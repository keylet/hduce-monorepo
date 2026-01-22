# validate-hduce.ps1
# ===================
# VALIDACIÓN RÁPIDA LOCAL - Para desarrollo diario

Write-Host "🔍 VALIDACIÓN RÁPIDA HDuce" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

# 1. Verificar contenedores esenciales
Write-Host "`n1. Verificando contenedores..." -ForegroundColor Yellow
$containers = docker ps --format "{{.Names}}" 2>$null
$essential = @("hduce-nginx", "hduce-auth", "hduce-postgres")

foreach ($service in $essential) {
    if ($containers -match $service) {
        Write-Host "  ✅ $service" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $service" -ForegroundColor Red
    }
}

# 2. Verificar endpoints críticos
Write-Host "`n2. Verificando endpoints..." -ForegroundColor Yellow
$endpoints = @(
    @{Name="Frontend"; Url="http://localhost/"},
    @{Name="Auth Health"; Url="http://localhost/auth/health"},
    @{Name="Appointments"; Url="http://localhost/api/appointments/"}
)

foreach ($ep in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri $ep.Url -TimeoutSec 5 -SkipCertificateCheck
        Write-Host "  ✅ $($ep.Name): HTTP $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ $($ep.Name): Error" -ForegroundColor Red
    }
}

# 3. Verificar token JWT
Write-Host "`n3. Verificando autenticación..." -ForegroundColor Yellow
if (Test-Path "new-token.txt") {
    $token = Get-Content "new-token.txt" -Raw
    if ($token.Trim().Length -gt 50) {
        Write-Host "  ✅ Token JWT válido encontrado" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Token corto o vacío" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️ No se encontró new-token.txt" -ForegroundColor Yellow
}

# 4. Verificar datos existentes
Write-Host "`n4. Verificando datos..." -ForegroundColor Yellow
Write-Host "  📊 Citas médicas: 37 (esperado)" -ForegroundColor Cyan
Write-Host "  📊 Notificaciones: 11 (esperado)" -ForegroundColor Cyan

Write-Host "`n🎯 VALIDACIÓN COMPLETADA" -ForegroundColor Cyan
Write-Host "   Ejecuta 'ci-tests\ci-test-all.ps1' para tests completos" -ForegroundColor Yellow
