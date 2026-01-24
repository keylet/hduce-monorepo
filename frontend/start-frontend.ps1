# Script para iniciar frontend
Write-Host "=== INICIANDO HDuce FRONTEND ===" -ForegroundColor Cyan
Write-Host "Puerto: 4200" -ForegroundColor Yellow
Write-Host "Modo: desarrollo" -ForegroundColor Yellow

# Verificar Node.js y npm
Write-Host "`n1. Verificando Node.js..." -ForegroundColor Green
node --version
npm --version

# Verificar dependencias
Write-Host "`n2. Verificando dependencias..." -ForegroundColor Green
if (Test-Path "node_modules") {
    Write-Host "   ✅ node_modules existe" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Instalando dependencias..." -ForegroundColor Yellow
    npm install
}

# Verificar que el backend esté corriendo
Write-Host "`n3. Verificando backend..." -ForegroundColor Green
$services = @("http://localhost/auth/health", "http://localhost/api/v1/users/health")
foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service -Method Head -TimeoutSec 3 -ErrorAction SilentlyContinue
        Write-Host "   ✅ $($service.Split('/')[2]) está activo" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ $($service.Split('/')[2]) NO responde" -ForegroundColor Red
    }
}

# Iniciar Vite
Write-Host "`n4. Iniciando servidor de desarrollo..." -ForegroundColor Green
Write-Host "   URL: http://localhost:4200" -ForegroundColor Cyan
Write-Host "   Presiona Ctrl+C para detener" -ForegroundColor Yellow
npm run dev
