# ci-tests\test-with-token.ps1 - VERSIÓN FINAL CORREGIDA
param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo"
)

Write-Host "🧪 HDuce Token-Based Tests (FINAL)" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Obtener token
$tokenFile = "$ProjectRoot\token.txt"
if (-not (Test-Path $tokenFile)) {
    & "$PSScriptRoot\auth-login.ps1" -ProjectRoot $ProjectRoot
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

$jwtToken = (Get-Content $tokenFile -First 1).Trim()
Write-Host "🔑 Using token from: $tokenFile" -ForegroundColor Gray

. "$PSScriptRoot\Invoke-SafeWebRequest.ps1"
$authHeaders = @{ "Authorization" = "Bearer $jwtToken" }

# TESTS ACTUALES DEL SISTEMA (basados en realidad)
Write-Host "`n1. API ENDPOINTS TEST:" -ForegroundColor Yellow

$apiTests = @(
    @{Name="User Profile"; Url="http://localhost/api/users/me"; MinStatus=200; MaxStatus=299},
    @{Name="Notifications"; Url="http://localhost/api/notifications/"; MinStatus=200; MaxStatus=299},
    @{Name="Doctors"; Url="http://localhost/api/doctors/"; MinStatus=200; MaxStatus=299},
    @{Name="Appointments"; Url="http://localhost/api/appointments/"; MinStatus=200; MaxStatus=299},
    @{Name="Users List"; Url="http://localhost/api/v1/users/"; MinStatus=200; MaxStatus=299}
)

$results = @()
foreach ($test in $apiTests) {
    Write-Host "  Testing $($test.Name)..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri $test.Url -Method "GET" -Headers $authHeaders -Timeout 5000
    
    if ($result.Success -and $result.StatusCode -ge $test.MinStatus -and $result.StatusCode -le $test.MaxStatus) {
        Write-Host " ✅ HTTP $($result.StatusCode)" -ForegroundColor Green
        
        # Extraer conteo si es posible
        $countInfo = ""
        try {
            $data = $result.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($data -is [array]) {
                $countInfo = " ($($data.Count) items)"
            } elseif ($data.items -is [array]) {
                $countInfo = " ($($data.items.Count) items)"
            } elseif ($data.total) {
                $countInfo = " (total: $($data.total))"
            } elseif ($result.Content.Length -gt 0) {
                # Intentar contar objetos en JSON
                $jsonObj = $result.Content | ConvertFrom-Json
                if ($jsonObj.PSObject.Properties.Name -contains "Count") {
                    $countInfo = " (count: $($jsonObj.Count))"
                }
            }
        } catch {
            $countInfo = " ($($result.Content.Length) bytes)"
        }
        
        $results += @{Test=$test.Name; Status="PASS"; Code=$result.StatusCode; Details="HTTP $($result.StatusCode)$countInfo"}
        
        if ($countInfo) {
            Write-Host "     $countInfo" -ForegroundColor Gray
        }
    } else {
        Write-Host " ❌ HTTP $($result.StatusCode)" -ForegroundColor Red
        $results += @{Test=$test.Name; Status="FAIL"; Code=$result.StatusCode; Details="HTTP $($result.StatusCode)"}
    }
    
    Start-Sleep -Milliseconds 100
}

# 2. HEALTH CHECKS
Write-Host "`n2. SERVICE HEALTH CHECKS:" -ForegroundColor Yellow

$healthEndpoints = @(
    @{Name="NGINX"; Url="http://localhost"},
    @{Name="Auth Service"; Url="http://localhost:8000/health"},
    @{Name="User Service"; Url="http://localhost:8001/health"},
    @{Name="Appointment Service"; Url="http://localhost:8002/health"},
    @{Name="Notification Service"; Url="http://localhost:8003/health"}
)

foreach ($endpoint in $healthEndpoints) {
    Write-Host "  Checking $($endpoint.Name)..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri $endpoint.Url -Method "GET" -Timeout 3000
    
    if ($result.Success -and $result.StatusCode -eq 200) {
        Write-Host " ✅" -ForegroundColor Green
        $results += @{Test="$($endpoint.Name) Health"; Status="PASS"; Code=200; Details="Healthy"}
    } else {
        Write-Host " ❌" -ForegroundColor Red
        $results += @{Test="$($endpoint.Name) Health"; Status="FAIL"; Code=$result.StatusCode; Details="Unhealthy"}
    }
}

# 3. DATABASE CHECK
Write-Host "`n3. DATABASE STATUS:" -ForegroundColor Yellow

try {
    # PostgreSQL
    $dbCheck = docker exec hduce-postgres psql -U postgres -d postgres -c "SELECT 1;" -t 2>$null
    if ($dbCheck -and $dbCheck.Trim() -eq "1") {
        Write-Host "  ✅ PostgreSQL is running" -ForegroundColor Green
        $results += @{Test="PostgreSQL"; Status="PASS"; Code="OK"; Details="Database running"}
    } else {
        Write-Host "  ❌ PostgreSQL not responding" -ForegroundColor Red
        $results += @{Test="PostgreSQL"; Status="FAIL"; Code="ERROR"; Details="Database error"}
    }
} catch {
    Write-Host "  ⚠️  Could not check database" -ForegroundColor Yellow
    $results += @{Test="PostgreSQL"; Status="WARN"; Code="ERROR"; Details="Check skipped"}
}

# RESUMEN
Write-Host "`n" + ("="*50) -ForegroundColor Cyan
Write-Host "📊 FINAL TEST RESULTS" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan

$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $results.Count

foreach ($result in $results) {
    $icon = if ($result.Status -eq "PASS") { "✅" } else { "❌" }
    $color = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $icon $($result.Test): $($result.Details)" -ForegroundColor $color
}

Write-Host "`n🎯 SCORE: $passed/$total tests passed ($([math]::Round(($passed/$total)*100, 1))%)" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "✅ ALL TESTS PASSED - System is 100% operational" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ $failed test(s) failed" -ForegroundColor Red
    exit 1
}
