# start.ps1 - Script para iniciar TODO en Windows
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  HDuce Microservices - Desarrollo Local" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Verificar que estamos en la carpeta correcta
$CurrentPath = Get-Location
Write-Host "Ubicación: $CurrentPath" -ForegroundColor Gray

# 2. Verificar Docker
Write-Host "`n[1/4] Verificando Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "   ✅ Docker instalado" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Docker no encontrado" -ForegroundColor Red
    Write-Host "   Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}

# 3. Construir imágenes
Write-Host "[2/4] Construyendo imágenes Docker..." -ForegroundColor Yellow
docker-compose build

# 4. Iniciar servicios
Write-Host "[3/4] Iniciando microservicios..." -ForegroundColor Yellow
docker-compose up -d

# 5. Mostrar estado
Write-Host "[4/4] Esperando que servicios inicien..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "`n✅ MICROSERVICIOS INICIADOS" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green
Write-Host ""
Write-Host "🔐 AUTH SERVICE" -ForegroundColor Cyan
Write-Host "   URL:      http://localhost:8000" -ForegroundColor White
Write-Host "   Health:   http://localhost:8000/health" -ForegroundColor White
Write-Host "   Docs:     http://localhost:8000/docs" -ForegroundColor White
Write-Host ""
Write-Host "👤 USER SERVICE" -ForegroundColor Cyan
Write-Host "   URL:      http://localhost:8001" -ForegroundColor White
Write-Host "   Health:   http://localhost:8001/health" -ForegroundColor White
Write-Host "   Docs:     http://localhost:8001/docs" -ForegroundColor White
Write-Host ""
Write-Host "🗄️  POSTGRESQL" -ForegroundColor Cyan
Write-Host "   Puerto:   5432" -ForegroundColor White
Write-Host "   Usuario:  postgres" -ForegroundColor White
Write-Host "   Password: postgres" -ForegroundColor White
Write-Host ""
Write-Host "⚡ REDIS" -ForegroundColor Cyan
Write-Host "   Puerto:   6379" -ForegroundColor White
Write-Host ""
Write-Host "📋 COMANDOS ÚTILES:" -ForegroundColor Yellow
Write-Host "   Ver logs:      docker-compose logs -f" -ForegroundColor Gray
Write-Host "   Detener:       docker-compose down" -ForegroundColor Gray
Write-Host "   Estado:        docker-compose ps" -ForegroundColor Gray
Write-Host "   Reiniciar:     docker-compose restart" -ForegroundColor Gray