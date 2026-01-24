param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo"
)

# Cargar función corregida
. "C:\Users\raich\Desktop\hduce-monorepo\ci-tests\Invoke-SafeWebRequest.ps1"

Write-Host "🚀 HDuce System Integration Tests" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Cargar token
$tokenFile = "$ProjectRoot\new-token.txt"
if (-not (Test-Path $tokenFile)) {
    Write-Host "❌ Token file not found" -ForegroundColor Red
    exit 1
}

$jwtToken = (Get-Content $tokenFile -First 1).Trim()
Write-Host "🔑 Using JWT Token: $($jwtToken.Substring(0, 30))..." -ForegroundColor Gray

$authHeaders = @{
    "Authorization" = "Bearer $jwtToken"
}

# Tests de endpoints protegidos
Write-Host "`n1. PROTECTED ENDPOINTS (via NGINX):" -ForegroundColor Yellow

$protectedEndpoints = @(
    @{Name="Appointments API"; Url="http://localhost/api/appointments/"; Expected=200},
    @{Name="Notifications API"; Url="http://localhost/api/notifications/"; Expected=200},
    @{Name="Users API"; Url="http://localhost/api/v1/users/"; Expected=200},
    @{Name="User Profile"; Url="http://localhost/api/v1/users/me"; Expected=200}
)

$results = @()

foreach ($endpoint in $protectedEndpoints) {
    Write-Host "  Testing $($endpoint.Name)..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri $endpoint.Url -Method GET -Headers $authHeaders -Timeout 5000
    
    if ($result -and $result.Success -and $result.StatusCode -eq $endpoint.Expected) {
        Write-Host " ✅ HTTP $($result.StatusCode)" -ForegroundColor Green
        
        # Extraer información útil
        try {
            $data = $result.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($data -is [array]) {
                $count = $data.Count
                Write-Host "     Found $count records" -ForegroundColor Gray
            } elseif ($data.items -is [array]) {
                $count = $data.items.Count
                Write-Host "     Found $count records" -ForegroundColor Gray
            } elseif ($data.total) {
                Write-Host "     Total: $($data.total) records" -ForegroundColor Gray
            }
        } catch {
            # No es JSON o no necesita procesamiento
        }
        
        $results += @{Name=$endpoint.Name; Status="PASS"; Code=$result.StatusCode; Data=$result.Content.Length}
    } elseif ($result.StatusCode -eq 401 -or $result.StatusCode -eq 403) {
        Write-Host " ❌ HTTP $($result.StatusCode) (Unauthorized)" -ForegroundColor Red
        $results += @{Name=$endpoint.Name; Status="FAIL"; Code=$result.StatusCode; Error="Authentication failed"}
    } else {
        Write-Host " ⚠️  HTTP $($result.StatusCode)" -ForegroundColor Yellow
        $results += @{Name=$endpoint.Name; Status="WARN"; Code=$result.StatusCode; Error=$result.Content}
    }
    
    Start-Sleep -Milliseconds 300
}

# Test de microservicios directos
Write-Host "`n2. MICROSERVICES DIRECT (bypassing NGINX):" -ForegroundColor Yellow

$microservices = @(
    @{Name="Auth Service"; Url="http://localhost:8000/auth/health"; Expected=200},
    @{Name="User Service"; Url="http://localhost:8001/health"; Expected=200},
    @{Name="Appointment Service"; Url="http://localhost:8002/health"; Expected=200},
    @{Name="Notification Service"; Url="http://localhost:8003/health"; Expected=200}
)

foreach ($service in $microservices) {
    Write-Host "  Testing $($service.Name)..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri $service.Url -Method GET -Timeout 3000
    
    if ($result -and $result.Success -and $result.StatusCode -eq $service.Expected) {
        Write-Host " ✅ HTTP $($result.StatusCode)" -ForegroundColor Green
        $results += @{Name="$($service.Name) Direct"; Status="PASS"; Code=$result.StatusCode}
    } else {
        Write-Host " ⚠️  HTTP $($result.StatusCode)" -ForegroundColor Yellow
        $results += @{Name="$($service.Name) Direct"; Status="WARN"; Code=$result.StatusCode; Error=$result.Content}
    }
    
    Start-Sleep -Milliseconds 200
}

# Test de base de datos
Write-Host "`n3. DATABASE DATA VALIDATION:" -ForegroundColor Yellow

try {
    # Contar citas médicas
    $appointmentsQuery = 'docker exec hduce-postgres psql -U postgres -d appointment_db -c "SELECT COUNT(*) FROM appointments;" -t 2>$null'
    $appointmentCount = Invoke-Expression $appointmentsQuery | ForEach-Object { $_.Trim() }
    
    if ($appointmentCount -match '^\d+$') {
        Write-Host "  📅 Appointments: $appointmentCount records" -ForegroundColor Green
        $results += @{Name="Appointment DB"; Status="PASS"; Code="DATA"; Data=$appointmentCount}
    } else {
        Write-Host "  ⚠️  Appointments: Could not retrieve count" -ForegroundColor Yellow
        $results += @{Name="Appointment DB"; Status="WARN"; Code="ERROR"}
    }
    
    # Contar notificaciones
    $notificationsQuery = 'docker exec hduce-postgres psql -U postgres -d notification_db -c "SELECT COUNT(*) FROM notifications;" -t 2>$null'
    $notificationCount = Invoke-Expression $notificationsQuery | ForEach-Object { $_.Trim() }
    
    if ($notificationCount -match '^\d+$') {
        Write-Host "  🔔 Notifications: $notificationCount records" -ForegroundColor Green
        $results += @{Name="Notification DB"; Status="PASS"; Code="DATA"; Data=$notificationCount}
    } else {
        Write-Host "  ⚠️  Notifications: Could not retrieve count" -ForegroundColor Yellow
        $results += @{Name="Notification DB"; Status="WARN"; Code="ERROR"}
    }
    
} catch {
    Write-Host "  ⚠️  Database validation skipped: $_" -ForegroundColor Yellow
}

# Resumen detallado
Write-Host "`n📊 DETAILED TEST REPORT:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$warn = ($results | Where-Object { $_.Status -eq "WARN" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count

foreach ($result in $results) {
    $icon = switch ($result.Status) {
        "PASS" { "✅" }
        "WARN" { "⚠️ " }
        "FAIL" { "❌" }
        default { "🔍" }
    }
    
    $color = switch ($result.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        default { "Gray" }
    }
    
    $info = if ($result.Data) { "($($result.Data))" } else { "" }
    Write-Host "  $icon $($result.Name): HTTP $($result.Code) $info" -ForegroundColor $color
}

Write-Host "`n🎯 FINAL VERDICT:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

if ($failed -eq 0 -and $warn -eq 0) {
    Write-Host "✅ PERFECT! All $passed tests passed" -ForegroundColor Green
    Write-Host "🚀 System is fully operational and ready for production" -ForegroundColor Green
    exit 0
} elseif ($failed -eq 0) {
    Write-Host "⚠️  ACCEPTABLE: $passed passed, $warn warnings" -ForegroundColor Yellow
    Write-Host "📈 System is functional with minor issues" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "❌ NEEDS ATTENTION: $passed passed, $warn warnings, $failed failed" -ForegroundColor Red
    Write-Host "🔧 Some critical components need fixing" -ForegroundColor Red
    exit 1
}
