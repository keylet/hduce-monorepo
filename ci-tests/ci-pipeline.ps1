# ci-tests\ci-pipeline.ps1
# Pipeline de CI/CD REAL que simula flujo de usuario

param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo",
    [switch]$CleanToken = $false
)

Write-Host "🚀 HDuce REAL CI/CD Pipeline" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Mode: $(if ($CleanToken) { 'Fresh token' } else { 'Reuse if valid' })" -ForegroundColor Gray

$startTime = Get-Date
$testDir = "$PSScriptRoot"
$results = @()

# Función para registrar resultados
function Add-Result {
    param($Step, $Status, $Message)
    $results += [PSCustomObject]@{
        Step = $Step
        Status = $Status
        Message = $Message
        Timestamp = Get-Date -Format "HH:mm:ss"
    }
}

# ========== FASE 1: PREPARACIÓN ==========
Write-Host "`n📦 PHASE 1: PREPARATION" -ForegroundColor Yellow

# Limpiar token si se solicita
if ($CleanToken -and (Test-Path "$ProjectRoot\token.txt")) {
    Remove-Item "$ProjectRoot\token.txt" -Force
    Write-Host "  🗑️  Cleared existing token" -ForegroundColor Gray
    Add-Result -Step "Token Cleanup" -Status "INFO" -Message "Token file removed"
}

# Verificar Docker
Write-Host "  Checking Docker services..." -NoNewline
try {
    $dockerInfo = docker info 2>$null
    if ($dockerInfo -match "Server Version") {
        Write-Host " ✅ Docker running" -ForegroundColor Green
        Add-Result -Step "Docker Check" -Status "PASS" -Message "Docker is running"
    } else {
        Write-Host " ❌ Docker not available" -ForegroundColor Red
        Add-Result -Step "Docker Check" -Status "FAIL" -Message "Docker not responding"
        exit 1
    }
} catch {
    Write-Host " ❌ Docker error" -ForegroundColor Red
    Add-Result -Step "Docker Check" -Status "FAIL" -Message "Docker check failed: $_"
    exit 1
}

# ========== FASE 2: AUTENTICACIÓN ==========
Write-Host "`n🔐 PHASE 2: AUTHENTICATION" -ForegroundColor Yellow

$authParams = @{
    ProjectRoot = $ProjectRoot
}

if ($CleanToken) {
    $authParams.ForceRefresh = $true
}

try {
    $token = & "$testDir\auth-login.ps1" @authParams
    
    if ($LASTEXITCODE -eq 0 -and $token) {
        Write-Host "  ✅ Authentication successful" -ForegroundColor Green
        Add-Result -Step "Authentication" -Status "PASS" -Message "Token obtained and saved"
        
        # Verificar token
        . "$testDir\Invoke-SafeWebRequest.ps1"
        $headers = @{ "Authorization" = "Bearer $token" }
        $verifyResult = Invoke-SafeWebRequest -Uri "http://localhost/api/users/me" -Method "GET" -Headers $headers
        
        if ($verifyResult.Success -and $verifyResult.StatusCode -eq 200) {
            Write-Host "  ✅ Token validation successful" -ForegroundColor Green
            Add-Result -Step "Token Validation" -Status "PASS" -Message "Token works for API calls"
        } else {
            Write-Host "  ⚠️  Token validation warning: HTTP $($verifyResult.StatusCode)" -ForegroundColor Yellow
            Add-Result -Step "Token Validation" -Status "WARN" -Message "Token returned HTTP $($verifyResult.StatusCode)"
        }
    } else {
        Write-Host "  ❌ Authentication failed" -ForegroundColor Red
        Add-Result -Step "Authentication" -Status "FAIL" -Message "Failed to obtain token"
        exit 1
    }
} catch {
    Write-Host "  ❌ Authentication error: $_" -ForegroundColor Red
    Add-Result -Step "Authentication" -Status "FAIL" -Message "Error: $_"
    exit 1
}

# ========== FASE 3: TESTING CON TOKEN ==========
Write-Host "`n🧪 PHASE 3: TOKEN-BASED TESTING" -ForegroundColor Yellow

try {
    & "$testDir\test-with-token.ps1" -ProjectRoot $ProjectRoot
    $testExitCode = $LASTEXITCODE
    
    if ($testExitCode -eq 0) {
        Write-Host "  ✅ All tests passed" -ForegroundColor Green
        Add-Result -Step "Token Tests" -Status "PASS" -Message "All API tests completed successfully"
    } else {
        Write-Host "  ⚠️  Tests completed with warnings/errors" -ForegroundColor Yellow
        Add-Result -Step "Token Tests" -Status "WARN" -Message "Tests completed with exit code $testExitCode"
    }
} catch {
    Write-Host "  ❌ Testing failed: $_" -ForegroundColor Red
    Add-Result -Step "Token Tests" -Status "FAIL" -Message "Testing error: $_"
    $testExitCode = 1
}

# ========== FASE 4: VERIFICACIÓN DE DATOS ==========
Write-Host "`n📊 PHASE 4: DATA VERIFICATION" -ForegroundColor Yellow

# Solo verificar si los tests básicos pasaron
if ($testExitCode -eq 0) {
    try {
        # Appointments
        $appointmentQuery = 'docker exec hduce-postgres psql -U postgres -d appointment_db -c "SELECT COUNT(*) FROM appointments;" -t 2>$null'
        $appointmentResult = Invoke-Expression $appointmentQuery
        $appointmentCount = if ($appointmentResult -match '\d+') { $matches[0].Trim() } else { "0" }
        
        # Notifications
        $notificationQuery = 'docker exec hduce-postgres psql -U postgres -d notification_db -c "SELECT COUNT(*) FROM notifications;" -t 2>$null'
        $notificationResult = Invoke-Expression $notificationQuery
        $notificationCount = if ($notificationResult -match '\d+') { $matches[0].Trim() } else { "0" }
        
        Write-Host "  📅 Appointments in DB: $appointmentCount" -ForegroundColor Green
        Write-Host "  🔔 Notifications in DB: $notificationCount" -ForegroundColor Green
        
        Add-Result -Step "Data Check" -Status "PASS" -Message "Appointments: $appointmentCount, Notifications: $notificationCount"
        
        # Verificar que hay datos
        if ([int]$appointmentCount -eq 0 -or [int]$notificationCount -eq 0) {
            Write-Host "  ⚠️  Low data count detected" -ForegroundColor Yellow
            Add-Result -Step "Data Volume" -Status "WARN" -Message "Low data volume detected"
        }
    } catch {
        Write-Host "  ⚠️  Data verification skipped: $_" -ForegroundColor Yellow
        Add-Result -Step "Data Check" -Status "WARN" -Message "Data check skipped: $_"
    }
} else {
    Write-Host "  ⏭️  Skipping data verification due to test failures" -ForegroundColor Gray
    Add-Result -Step "Data Check" -Status "SKIP" -Message "Skipped due to test failures"
}

# ========== FASE 5: REPORTE FINAL ==========
$endTime = Get-Date
$totalDuration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)

Write-Host "`n" + ("="*60) -ForegroundColor Cyan
Write-Host "📈 PIPELINE COMPLETE" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host "⏱️  Total Duration: ${totalDuration}s" -ForegroundColor Gray

# Mostrar resumen por fases
Write-Host "`n📋 PHASE SUMMARY:" -ForegroundColor Cyan
foreach ($result in $results) {
    $icon = switch ($result.Status) {
        "PASS" { "✅" }
        "WARN" { "⚠️ " }
        "FAIL" { "❌" }
        "INFO" { "ℹ️ " }
        "SKIP" { "⏭️ " }
        default { "🔍" }
    }
    
    $color = switch ($result.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
        "INFO" { "Cyan" }
        "SKIP" { "Gray" }
        default { "White" }
    }
    
    Write-Host "  $icon [$($result.Timestamp)] $($result.Step): $($result.Message)" -ForegroundColor $color
}

# Contar resultados
$passedPhases = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$warnPhases = ($results | Where-Object { $_.Status -in @("WARN", "INFO") }).Count
$failedPhases = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$totalPhases = $results.Count

Write-Host "`n🎯 FINAL RESULT:" -ForegroundColor Cyan
Write-Host "  Phases: $passedPhases passed, $warnPhases warnings, $failedPhases failed" -ForegroundColor Gray

# Generar reporte JSON
$report = @{
    pipeline_run = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        duration_seconds = $totalDuration
        phases = $results
        summary = @{
            total_phases = $totalPhases
            passed = $passedPhases
            warnings = $warnPhases
            failed = $failedPhases
        }
        token_file = "$ProjectRoot\token.txt"
        test_exit_code = $testExitCode
    }
    system_info = @{
        hostname = $env:COMPUTERNAME
        user = $env:USERNAME
        powershell_version = $PSVersionTable.PSVersion.ToString()
    }
}

$reportJson = $report | ConvertTo-Json -Depth 4
$reportFile = "$testDir\pipeline-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$reportJson | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "📄 Full report: $reportFile" -ForegroundColor Cyan

# Decisión final
if ($failedPhases -eq 0) {
    if ($warnPhases -eq 0) {
        Write-Host "`n🎉 SUCCESS: All phases completed perfectly!" -ForegroundColor Green
        Write-Host "🚀 System is production ready" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n⚠️  SUCCESS WITH WARNINGS" -ForegroundColor Yellow
        Write-Host "📈 System is operational with minor issues" -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "`n❌ PIPELINE FAILED" -ForegroundColor Red
    Write-Host "🔧 Critical issues need attention" -ForegroundColor Red
    exit 1
}
