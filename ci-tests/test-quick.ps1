# ci-tests\test-quick.ps1
# Test rápido para CI/CD - Solo verifica lo esencial

param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo"
)

Write-Host "⚡ HDuce Quick Smoke Test" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# Verificar servicios Docker
Write-Host "`n1. DOCKER SERVICES:" -ForegroundColor Yellow
$services = @("hduce-nginx", "hduce-auth", "hduce-postgres", "hduce-user", "hduce-appointment", "hduce-notification")
$runningServices = docker ps --format "{{.Names}}" 2>$null

$allRunning = $true
foreach ($service in $services) {
    if ($runningServices -contains $service) {
        Write-Host "  ✅ $service" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $service" -ForegroundColor Red
        $allRunning = $false
    }
}

if (-not $allRunning) {
    Write-Host "❌ Missing critical services" -ForegroundColor Red
    exit 1
}

# Verificar conectividad básica
Write-Host "`n2. CONNECTIVITY:" -ForegroundColor Yellow

. "$PSScriptRoot\Invoke-SafeWebRequest.ps1"

$connectivityTests = @(
    @{Name="NGINX"; Url="http://localhost"},
    @{Name="Auth Service"; Url="http://localhost:8000/health"},
    @{Name="Database"; Test={ 
        try {
            $test = docker exec hduce-postgres psql -U postgres -d postgres -c "SELECT 1;" -t 2>$null
            return ($test -and $test.Trim() -eq "1")
        } catch { return $false }
    }}
)

$allConnected = $true
foreach ($test in $connectivityTests) {
    Write-Host "  Testing $($test.Name)..." -NoNewline
    
    if ($test.Url) {
        $result = Invoke-SafeWebRequest -Uri $test.Url -Timeout 3000
        $success = $result.Success -and $result.StatusCode -eq 200
    } else {
        $success = & $test.Test
    }
    
    if ($success) {
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ❌" -ForegroundColor Red
        $allConnected = $false
    }
}

if (-not $allConnected) {
    Write-Host "❌ Connectivity issues" -ForegroundColor Red
    exit 1
}

# Verificar que hay datos
Write-Host "`n3. DATA AVAILABILITY:" -ForegroundColor Yellow

try {
    # Appointments
    $appointmentResult = docker exec hduce-postgres psql -U postgres -d appointment_db -c "SELECT COUNT(*) FROM appointments;" -t 2>$null
    $appointmentCount = if ($appointmentResult -match '\d+') { [int]$matches[0] } else { 0 }
    
    # Notifications  
    $notificationResult = docker exec hduce-postgres psql -U postgres -d notification_db -c "SELECT COUNT(*) FROM notifications;" -t 2>$null
    $notificationCount = if ($notificationResult -match '\d+') { [int]$matches[0] } else { 0 }
    
    if ($appointmentCount -gt 0 -and $notificationCount -gt 0) {
        Write-Host "  ✅ Data exists: $appointmentCount appointments, $notificationCount notifications" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Low data count: $appointmentCount appointments, $notificationCount notifications" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Could not verify data" -ForegroundColor Yellow
}

Write-Host "`n🎉 SMOKE TEST PASSED" -ForegroundColor Green
Write-Host "🚀 System is ready for use" -ForegroundColor Green
exit 0
