# build-all.ps1 - Construye todas las imágenes Docker
Write-Host "=== CONSTRUYENDO IMÁGENES DOCKER PARA AWS ===" -ForegroundColor Cyan

# Servicios y puertos
$services = @{
    'auth' = 8000
    'user' = 8001
    'appointment' = 8002
    'notification' = 8003
    'mqtt' = 8004
    'metrics' = 8005
}

foreach ($service in $services.Keys) {
    Write-Host "
 Construyendo $service-service (puerto: $($services[$service]))..." -ForegroundColor Yellow
    
    # Ruta al código fuente (ajusta según tu estructura)
    $sourcePath = "..\..\..\backend\$service-service"
    
    if (Test-Path $sourcePath) {
        docker build 
            -f "Dockerfile.$service.prod" 
            -t "hduce-$service:prod" 
            .
        
        Write-Host "   hduce-$service:prod construida" -ForegroundColor Green
    } else {
        Write-Host "   No se encuentra: $sourcePath" -ForegroundColor Red
    }
}

Write-Host "
 Proceso completado!" -ForegroundColor Green
Write-Host "
Siguientes pasos:" -ForegroundColor Cyan
Write-Host "1. Subir a DockerHub: docker login" -ForegroundColor White
Write-Host "2. Tag images: docker tag hduce-auth:prod tuusuario/hduce-auth:latest" -ForegroundColor White
Write-Host "3. Push: docker push tuusuario/hduce-auth:latest" -ForegroundColor White
