# ci-tests\ci-run-all.ps1
param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo",
    [switch]$Quick = $false
)

Write-Host "🚀 HDuce CI/CD Test Suite" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Mode: $(if ($Quick) { 'Quick' } else { 'Full' })" -ForegroundColor Gray

$startTime = Get-Date
$results = @()
$testDir = "$PSScriptRoot"

# Función para ejecutar test y capturar resultados
function Run-Test {
    param($Name, $Script, $Timeout = 30000)
    
    Write-Host "`n▶️  Running: $Name" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan
    
    $testStart = Get-Date
    $output = @()
    
    try {
        # Ejecutar script y capturar output
        $job = Start-Job -ScriptBlock {
            param($scriptPath)
            & $scriptPath
        } -ArgumentList "$testDir\$Script" -ErrorAction Stop
        
        # Esperar con timeout
        $job | Wait-Job -Timeout ($Timeout/1000) | Out-Null
        
        if ($job.State -eq "Running") {
            $job | Stop-Job
            Remove-Job -Force $job
            throw "Test timeout after $($Timeout/1000) seconds"
        }
        
        $output = $job | Receive-Job
        $exitCode = $job.ChildJobs[0].ExitCode
        
        $job | Remove-Job
        
        # Mostrar output
        $output | ForEach-Object { Write-Host $_ }
        
        $testEnd = Get-Date
        $duration = [math]::Round(($testEnd - $testStart).TotalSeconds, 2)
        
        $status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
        $color = if ($exitCode -eq 0) { "Green" } else { "Red" }
        
        Write-Host "`n⏱️  Duration: ${duration}s" -ForegroundColor Gray
        Write-Host "📊 Result: $status (Exit code: $exitCode)" -ForegroundColor $color
        
        return @{
            Name = $Name
            Status = $status
            ExitCode = $exitCode
            Duration = $duration
            Output = $output -join "`n"
        }
    }
    catch {
        Write-Host "❌ ERROR: $_" -ForegroundColor Red
        return @{
            Name = $Name
            Status = "ERROR"
            ExitCode = 1
            Duration = [math]::Round((Get-Date - $testStart).TotalSeconds, 2)
            Error = $_.Exception.Message
        }
    }
}

# 1. Prueba de conectividad básica (siempre se ejecuta)
$results += Run-Test -Name "Basic Connectivity" -Script "test-connectivity.ps1"

# 2. Prueba de autenticación
if ($results[0].ExitCode -eq 0) {
    $results += Run-Test -Name "Authentication" -Script "test-auth.ps1"
} else {
    Write-Host "`n⏭️  Skipping authentication test due to connectivity issues" -ForegroundColor Yellow
}

# 3. Prueba completa de endpoints (solo en modo full)
if (-not $Quick -and $results[0].ExitCode -eq 0) {
    $results += Run-Test -Name "System Endpoints" -Script "test-endpoints.ps1" -Timeout 60000
}

# Resumen final
$endTime = Get-Date
$totalDuration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)

Write-Host "`n" + ("="*60) -ForegroundColor Cyan
Write-Host "📈 CI/CD TEST SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -in @("FAIL", "ERROR") }).Count
$skipped = $results.Count - $passed - $failed

Write-Host "⏱️  Total Time: ${totalDuration}s" -ForegroundColor Gray
Write-Host "📊 Tests Run: $($results.Count)" -ForegroundColor Gray
Write-Host "✅ Passed: $passed" -ForegroundColor Green
Write-Host "❌ Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Gray" })
Write-Host "⏭️  Skipped: $skipped" -ForegroundColor Gray

Write-Host "`n📋 DETAILED RESULTS:" -ForegroundColor Cyan
foreach ($result in $results) {
    $icon = switch ($result.Status) {
        "PASS" { "✅" }
        "FAIL" { "❌" }
        "ERROR" { "💥" }
        default { "🔍" }
    }
    
    $color = switch ($result.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "ERROR" { "Red" }
        default { "Gray" }
    }
    
    Write-Host "  $icon $($result.Name) - $($result.Status) (${$result.Duration}s)" -ForegroundColor $color
}

# Generar reporte JSON para CI/CD
$report = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    duration = $totalDuration
    tests = $results
    summary = @{
        total = $results.Count
        passed = $passed
        failed = $failed
        skipped = $skipped
    }
    system = @{
        project_root = $ProjectRoot
        hostname = $env:COMPUTERNAME
        powershell_version = $PSVersionTable.PSVersion.ToString()
    }
}

$reportJson = $report | ConvertTo-Json -Depth 5
$reportFile = "$testDir\test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$reportJson | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "`n📄 Report saved to: $reportFile" -ForegroundColor Cyan

# Salir con código apropiado para CI/CD
if ($failed -gt 0) {
    Write-Host "`n❌ CI/CD FAILED: $failed test(s) failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ CI/CD PASSED: All tests completed successfully" -ForegroundColor Green
    exit 0
}
