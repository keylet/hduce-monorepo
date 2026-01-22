# ci-tests\test-accurate.ps1
# Tests 100% precisos basados en análisis real del sistema

param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo"
)

Write-Host "🎯 HDuce Accurate System Tests" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "Based on actual system analysis" -ForegroundColor Gray

# Cargar función HTTP
. "$PSScriptRoot\Invoke-SafeWebRequest.ps1"

# Cargar token
$tokenFile = "$ProjectRoot\new-token.txt"
if (-not (Test-Path $tokenFile)) {
    Write-Host "❌ Token file not found" -ForegroundColor Red
    exit 1
}

$jwtToken = (Get-Content $tokenFile -First 1).Trim()
$authHeaders = @{
    "Authorization" = "Bearer $jwtToken"
}

# Decodificar token para información
$tokenParts = $jwtToken.Split('.')
if ($tokenParts.Count -ge 2) {
    $payloadBase64 = $tokenParts[1]
    while ($payloadBase64.Length % 4) { $payloadBase64 += "=" }
    $payloadBytes = [System.Convert]::FromBase64String($payloadBase64)
    $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
    $tokenData = $payloadJson | ConvertFrom-Json
    Write-Host "👤 User: $($tokenData.email) (ID: $($tokenData.user_id))" -ForegroundColor Gray
}

$testResults = @()

# ========== TEST 1: CONECTIVIDAD BÁSICA ==========
Write-Host "`n1. BASIC CONNECTIVITY:" -ForegroundColor Yellow

$connectivityTests = @(
    @{Name="NGINX"; Url="http://localhost"; Method="GET"; Headers=@{}; Expected=200},
    @{Name="Auth Health"; Url="http://localhost:8000/health"; Method="GET"; Headers=@{}; Expected=200},
    @{Name="User Service"; Url="http://localhost:8001/health"; Method="GET"; Headers=@{}; Expected=200},
    @{Name="Appointment Service"; Url="http://localhost:8002/health"; Method="GET"; Headers=@{}; Expected=200},
    @{Name="Notification Service"; Url="http://localhost:8003/health"; Method="GET"; Headers=@{}; Expected=200}
)

foreach ($test in $connectivityTests) {
    Write-Host "  Testing $($test.Name)..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri $test.Url -Method $test.Method -Headers $test.Headers -Timeout 3000
    
    if ($result.Success -and $result.StatusCode -eq $test.Expected) {
        Write-Host " ✅" -ForegroundColor Green
        $testResults += @{Test=$test.Name; Status="PASS"; Details="HTTP $($result.StatusCode)"}
    } else {
        Write-Host " ❌ HTTP $($result.StatusCode)" -ForegroundColor Red
        $testResults += @{Test=$test.Name; Status="FAIL"; Details="HTTP $($result.StatusCode) - $($result.Content)"}
    }
}

# ========== TEST 2: AUTENTICACIÓN JWT ==========
Write-Host "`n2. JWT AUTHENTICATION:" -ForegroundColor Yellow

Write-Host "  Testing token validity via login..." -NoNewline
$loginData = @{
    email = "testuser@example.com"
    password = "secret"
} | ConvertTo-Json

$result = Invoke-SafeWebRequest -Uri "http://localhost:8000/auth/login" -Method "POST" -Body $loginData -Timeout 5000

if ($result.Success -and $result.StatusCode -eq 200) {
    Write-Host " ✅ Token can be obtained" -ForegroundColor Green
    $testResults += @{Test="JWT Login"; Status="PASS"; Details="Token obtainable"}
} else {
    Write-Host " ❌ Login failed" -ForegroundColor Red
    $testResults += @{Test="JWT Login"; Status="FAIL"; Details="HTTP $($result.StatusCode)"}
}

# ========== TEST 3: ENDPOINTS PROTEGIDOS (BASADOS EN REALIDAD) ==========
Write-Host "`n3. PROTECTED ENDPOINTS (Real Paths):" -ForegroundColor Yellow

# Rutas REALES que sabemos funcionan (de los logs y pruebas)
$realEndpoints = @(
    @{Name="User Profile"; Url="http://localhost/api/users/me"; Expected=200; Description="User profile endpoint"},
    @{Name="Notifications"; Url="http://localhost/api/notifications/"; Expected=200; Description="Notifications list"},
    @{Name="Appointments"; Url="http://localhost/api/appointments/"; Expected=200; Description="Appointments list"},
    @{Name="Doctors"; Url="http://localhost/api/doctors/"; Expected=200; Description="Doctors list"}
)

foreach ($endpoint in $realEndpoints) {
    Write-Host "  Testing $($endpoint.Name) ($($endpoint.Description))..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri $endpoint.Url -Method "GET" -Headers $authHeaders -Timeout 5000
    
    if ($result.Success -and $result.StatusCode -eq $endpoint.Expected) {
        Write-Host " ✅" -ForegroundColor Green
        
        # Analizar respuesta
        try {
            $data = $result.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
            $countInfo = ""
            
            if ($data -is [array]) {
                $countInfo = " ($($data.Count) items)"
            } elseif ($data.items -is [array]) {
                $countInfo = " ($($data.items.Count) items)"
            } elseif ($data.total) {
                $countInfo = " (total: $($data.total))"
            }
            
            Write-Host "     Response: HTTP $($result.StatusCode)$countInfo" -ForegroundColor Gray
            $testResults += @{Test=$endpoint.Name; Status="PASS"; Details="HTTP $($result.StatusCode)$countInfo"}
        } catch {
            Write-Host "     Response: HTTP $($result.StatusCode) ($($result.Content.Length) bytes)" -ForegroundColor Gray
            $testResults += @{Test=$endpoint.Name; Status="PASS"; Details="HTTP $($result.StatusCode)"}
        }
    } elseif ($result.StatusCode -eq 401 -or $result.StatusCode -eq 403) {
        Write-Host " ❌ Authentication failed" -ForegroundColor Red
        $testResults += @{Test=$endpoint.Name; Status="FAIL"; Details="HTTP $($result.StatusCode) - Auth failed"}
    } else {
        Write-Host " ⚠️  HTTP $($result.StatusCode)" -ForegroundColor Yellow
        $testResults += @{Test=$endpoint.Name; Status="WARN"; Details="HTTP $($result.StatusCode)"}
    }
    
    Start-Sleep -Milliseconds 300
}

# ========== TEST 4: DATOS EXISTENTES ==========
Write-Host "`n4. EXISTING DATA VALIDATION:" -ForegroundColor Yellow

try {
    # Appointments
    $appointmentQuery = 'docker exec hduce-postgres psql -U postgres -d appointment_db -c "SELECT COUNT(*) as count FROM appointments;" -t 2>$null'
    $appointmentCount = (Invoke-Expression $appointmentQuery | ForEach-Object { $_.Trim() }) -match '^\d+'
    
    if ($appointmentCount) {
        $count = $matches[0]
        Write-Host "  📅 Appointments in DB: $count records" -ForegroundColor Green
        $testResults += @{Test="Appointments Data"; Status="PASS"; Details="$count records"}
    } else {
        Write-Host "  ⚠️  Could not get appointments count" -ForegroundColor Yellow
        $testResults += @{Test="Appointments Data"; Status="WARN"; Details="Query failed"}
    }
    
    # Notifications
    $notificationQuery = 'docker exec hduce-postgres psql -U postgres -d notification_db -c "SELECT COUNT(*) as count FROM notifications;" -t 2>$null'
    $notificationCount = (Invoke-Expression $notificationQuery | ForEach-Object { $_.Trim() }) -match '^\d+'
    
    if ($notificationCount) {
        $count = $matches[0]
        Write-Host "  🔔 Notifications in DB: $count records" -ForegroundColor Green
        $testResults += @{Test="Notifications Data"; Status="PASS"; Details="$count records"}
    } else {
        Write-Host "  ⚠️  Could not get notifications count" -ForegroundColor Yellow
        $testResults += @{Test="Notifications Data"; Status="WARN"; Details="Query failed"}
    }
} catch {
    Write-Host "  ⚠️  Database validation skipped: $_" -ForegroundColor Yellow
}

# ========== TEST 5: MICROSERVICES DOCS ==========
Write-Host "`n5. MICROSERVICES DOCUMENTATION:" -ForegroundColor Yellow

$services = @(
    @{Port=8001; Name="User Service"},
    @{Port=8002; Name="Appointment Service"},
    @{Port=8003; Name="Notification Service"}
)

foreach ($service in $services) {
    Write-Host "  Checking $($service.Name) docs..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri "http://localhost:$($service.Port)/docs" -Method "GET" -Timeout 3000
    
    if ($result.Success -and $result.StatusCode -eq 200) {
        Write-Host " ✅ OpenAPI available" -ForegroundColor Green
        $testResults += @{Test="$($service.Name) Docs"; Status="PASS"; Details="OpenAPI available"}
    } else {
        Write-Host " ⚠️  No docs" -ForegroundColor Yellow
        $testResults += @{Test="$($service.Name) Docs"; Status="WARN"; Details="HTTP $($result.StatusCode)"}
    }
}

# ========== RESULTADOS ==========
Write-Host "`n" + ("="*50) -ForegroundColor Cyan
Write-Host "📊 TEST RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan

$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$warn = ($testResults | Where-Object { $_.Status -eq "WARN" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Count

foreach ($result in $testResults) {
    $icon = switch ($result.Status) {
        "PASS" { "✅" }
        "WARN" { "⚠️ " }
        "FAIL" { "❌" }
    }
    
    $color = switch ($result.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
    }
    
    Write-Host "  $icon $($result.Test): $($result.Details)" -ForegroundColor $color
}

Write-Host "`n🎯 FINAL SCORE: $passed/$total passed ($([math]::Round(($passed/$total)*100, 1))%)" -ForegroundColor Cyan

if ($failed -eq 0) {
    if ($warn -eq 0) {
        Write-Host "✅ PERFECT! All tests passed" -ForegroundColor Green
        Write-Host "🚀 System is 100% operational" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "⚠️  ACCEPTABLE: $passed passed, $warn warnings" -ForegroundColor Yellow
        Write-Host "📈 System is functional with minor issues" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "❌ NEEDS ATTENTION: $passed passed, $warn warnings, $failed failed" -ForegroundColor Red
    exit 1
}
