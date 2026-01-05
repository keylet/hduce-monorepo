# Script para actualizar microservicios manteniendo compatibilidad Nginx
Write-Host "🔄 Actualizando microservicios con shared-libraries..." -ForegroundColor Cyan

# 1. Actualizar requirements.txt de todos los servicios
$services = @(
    @{Name="auth-service"; Port=8000},
    @{Name="user-service"; Port=8001},
    @{Name="appointment-service"; Port=8002},
    @{Name="notification-service"; Port=8003}
)

foreach ($service in $services) {
    $serviceName = $service.Name
    $servicePort = $service.Port
    $requirementsPath = "backend/$serviceName/requirements.txt"
    
    Write-Host "`n📦 Procesando $serviceName (puerto $servicePort)..." -ForegroundColor Yellow
    
    if (Test-Path $requirementsPath) {
        # Actualizar requirements.txt con shared-libs
        @"
# HDUCE $serviceName
fastapi==0.104.1
uvicorn[standard]==0.24.0
hduce-shared @ file:///C:/Users/raich/Desktop/hduce-monorepo/shared-libraries
"@ | Set-Content -Path $requirementsPath -Encoding UTF8
        
        Write-Host "  ✅ requirements.txt actualizado" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $requirementsPath no encontrado" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Todos los servicios actualizados" -ForegroundColor Green
Write-Host "`n🔧 Siguientes pasos manuales:" -ForegroundColor Cyan
Write-Host "   1. Reemplazar main.py de cada servicio con versión shared-libs"
Write-Host "   2. Mantener el mismo puerto (8000, 8001, etc.)"
Write-Host "   3. No modificar configuración de Nginx"
Write-Host "   4. Probar con docker-compose up -d"
