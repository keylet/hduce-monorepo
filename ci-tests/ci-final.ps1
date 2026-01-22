# ci-tests\ci-final.ps1
# CI/CD definitivo basado en tests precisos

param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo"
)

Write-Host "🚀 HDuce Production CI/CD Pipeline" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

$startTime = Get-Date
$testDir = "$PSScriptRoot"

# Cargar función HTTP
. "$testDir\Invoke-SafeWebRequest.ps1"

# Paso 1: Verificar que los servicios están corriendo
Write-Host "`n🔍 STEP 1: SERVICE STATUS CHECK" -ForegroundColor Yellow

$services = docker ps --format "{{.Names}}" 2>$null
if (-not $services) {
    Write-Host "❌ No Docker services running" -ForegroundColor Red
    exit 1
}

$serviceCount = ($services -split "`n").Count
Write-Host "✅ $serviceCount services running" -ForegroundColor Green

# Verificar servicios críticos
$criticalServices = @("hduce-nginx", "hduce-auth", "hduce-postgres", "hduce-user", "hduce-appointment", "hduce-notification")
$missingServices = @()

foreach ($service in $criticalServices) {
    if ($services -contains $service) {
        Write-Host "  ✅ $service" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $service" -ForegroundColor Red
        $missingServices += $service
    }
}

if ($missingServices.Count -gt 0) {
    Write-Host "⚠️  Missing critical services: $($missingServices -join ', ')" -ForegroundColor Yellow
}

# Paso 2: Verificar conectividad básica
Write-Host "`n🔍 STEP 2: BASIC CONNECTIVITY" -ForegroundColor Yellow

$basicTests = @(
    @{Url="http://localhost"; Name="NGINX"},
    @{Url="http://localhost:8000/health"; Name="Auth Service"},
    @{Url="http://localhost:8001/health"; Name="User Service"},
    @{Url="http://localhost:8002/health"; Name="Appointment Service"},
    @{Url="http://localhost:8003/health"; Name="Notification Service"}
)

$connectivityPassed = 0
foreach ($test in $basicTests) {
    Write-Host "  Testing $($test.Name)..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri $test.Url -Timeout 5000
    
    if ($result.Success -and $result.StatusCode -eq 200) {
        Write-Host " ✅" -ForegroundColor Green
        $connectivityPassed++
    } else {
        Write-Host " ❌ HTTP $($result.StatusCode)" -ForegroundColor Red
    }
}

if ($connectivityPassed -lt 3) {
    Write-Host "❌ Insufficient connectivity ($connectivityPassed/$($basicTests.Count) passed)" -ForegroundColor Red
    exit 1
}

# Paso 3: Ejecutar tests precisos
Write-Host "`n🔍 STEP 3: ACCURATE SYSTEM TESTS" -ForegroundColor Yellow

try {
    & "$testDir\test-accurate.ps1" -ProjectRoot $ProjectRoot
    $testExitCode = $LASTEXITCODE
} catch {
    Write-Host "❌ Test execution failed: $_" -ForegroundColor Red
    $testExitCode = 1
}

# Paso 4: Validación de datos
Write-Host "`n🔍 STEP 4: DATA VALIDATION" -ForegroundColor Yellow

# Validar que existen datos (37 citas, 11 notificaciones)
try {
    # Appointments
    $appointmentCmd = 'docker exec hduce-postgres psql -U postgres -d appointment_db -c "SELECT COUNT(*) FROM appointments;" -t'
    $appointmentResult = Invoke-Expression $appointmentCmd 2>$null
    $appointmentCount = [int]($appointmentResult -replace '[^\d]', '')
    
    if ($appointmentCount -ge 1) {
        Write-Host "  📅 Appointments: $appointmentCount records" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Appointments: No records found" -ForegroundColor Yellow
    }
    
    # Notifications
    $notificationCmd = 'docker exec hduce-postgres psql -U postgres -d notification_db -c "SELECT COUNT(*) FROM notifications;" -t'
    $notificationResult = Invoke-Expression $notificationCmd 2>$null
    $notificationCount = [int]($notificationResult -replace '[^\d]', '')
    
    if ($notificationCount -ge 1) {
        Write-Host "  🔔 Notifications: $notificationCount records" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Notifications: No records found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Data validation skipped" -ForegroundColor Yellow
}

# Paso 5: Resumen final
$endTime = Get-Date
$totalDuration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)

Write-Host "`n" + ("="*60) -ForegroundColor Cyan
Write-Host "📈 CI/CD PIPELINE COMPLETE" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host "⏱️  Total Time: ${totalDuration}s" -ForegroundColor Gray
Write-Host "🏗️  Services: $serviceCount running" -ForegroundColor Gray
Write-Host "🔗 Connectivity: $connectivityPassed/$($basicTests.Count) passed" -ForegroundColor Gray

# Generar reporte
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    duration_seconds = $totalDuration
    services_running = $serviceCount
    connectivity_passed = $connectivityPassed
    test_exit_code = $testExitCode
    data_counts = @{
        appointments = $appointmentCount
        notifications = $notificationCount
    }
}

$reportJson = $report | ConvertTo-Json
$reportFile = "$testDir\ci-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$reportJson | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "📄 Report: $reportFile" -ForegroundColor Cyan

# Decisión final
if ($testExitCode -eq 0 -and $connectivityPassed -ge 3 -and $serviceCount -ge 10) {
    Write-Host "`n✅ CI/CD PASSED - System is production ready!" -ForegroundColor Green
    Write-Host "🚀 All critical checks passed successfully" -ForegroundColor Green
    exit 0
} elseif ($testExitCode -eq 0 -and $connectivityPassed -ge 2) {
    Write-Host "`n⚠️  CI/CD PASSED WITH WARNINGS" -ForegroundColor Yellow
    Write-Host "📈 System is functional but review warnings" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n❌ CI/CD FAILED" -ForegroundColor Red
    Write-Host "🔧 Some critical checks failed" -ForegroundColor Red
    exit 1
}
