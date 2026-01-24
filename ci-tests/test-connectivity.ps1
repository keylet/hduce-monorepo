param(
    [string]$ProjectRoot = "C:\Users\raich\Desktop\hduce-monorepo"
)

# Cargar función
. "C:\Users\raich\Desktop\hduce-monorepo\ci-tests\Invoke-SafeWebRequest.ps1"

Write-Host "🔍 HDuce Basic Connectivity Tests" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Test endpoints públicos
Write-Host "`n1. PUBLIC ENDPOINTS:" -ForegroundColor Yellow

$publicEndpoints = @(
    @{Name="NGINX (Port 80)"; Url="http://localhost"},
    @{Name="Auth Service (Port 8000)"; Url="http://localhost:8000"},
    @{Name="Auth Health"; Url="http://localhost:8000/health"},
    @{Name="User Service (Port 8001)"; Url="http://localhost:8001"},
    @{Name="Appointment Service (Port 8002)"; Url="http://localhost:8002"},
    @{Name="Notification Service (Port 8003)"; Url="http://localhost:8003"}
)

$passed = 0
$failed = 0

foreach ($endpoint in $publicEndpoints) {
    Write-Host "  Testing $($endpoint.Name)..." -NoNewline
    $result = Invoke-SafeWebRequest -Uri $endpoint.Url -Method GET -Timeout 3000
    
    if ($result -and $result.Success -and $result.StatusCode -in @(200, 301, 302, 404)) {
        Write-Host " ✅ HTTP $($result.StatusCode)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " ❌ HTTP $($result.StatusCode) $($result.Exception)" -ForegroundColor Red
        $failed++
    }
    
    Start-Sleep -Milliseconds 200
}

# Test de contenedores
Write-Host "`n2. DOCKER CONTAINERS:" -ForegroundColor Yellow

try {
    $containers = docker ps --format "{{.Names}}" 2>$null
    if ($containers) {
        $containerCount = ($containers -split "`n").Count
        Write-Host "  ✅ $containerCount containers running" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ❌ No containers found" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  ❌ Docker check failed: $_" -ForegroundColor Red
    $failed++
}

# Test de puertos
Write-Host "`n3. PORT AVAILABILITY:" -ForegroundColor Yellow

$ports = @(80, 8000, 8001, 8002, 8003, 5432)
foreach ($port in $ports) {
    Write-Host "  Testing port $port..." -NoNewline
    $test = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue 2>$null
    if ($test -and $test.TcpTestSucceeded) {
        Write-Host " ✅ OPEN" -ForegroundColor Green
        $passed++
    } else {
        Write-Host " ❌ CLOSED" -ForegroundColor Red
        $failed++
    }
}

# Resumen
Write-Host "`n📊 SUMMARY:" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan
Write-Host "✅ Passed: $passed" -ForegroundColor Green
Write-Host "❌ Failed: $failed" -ForegroundColor Red
Write-Host "📈 Total: $($passed + $failed) tests" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "🎉 ALL TESTS PASSED - System is ready!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Some tests failed - Check services" -ForegroundColor Yellow
    exit 1
}
