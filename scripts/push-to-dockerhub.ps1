Write-Host " Subiendo imágenes a Docker Hub..." -ForegroundColor Green

$services = @("auth", "user", "appointment", "notification")

foreach ($service in $services) {
    $image = "keylet/hduce-$service"
    
    Write-Host "`n Procesando $image..." -ForegroundColor Yellow
    
    # 1. Verificar si la imagen existe localmente
    $exists = docker images -q "$image:latest"
    if (-not $exists) {
        Write-Host "     Imagen no encontrada localmente" -ForegroundColor Red
        continue
    }
    
    Write-Host "    Imagen encontrada localmente" -ForegroundColor Green
    
    # 2. Subir a Docker Hub
    Write-Host "    Subiendo a Docker Hub..." -ForegroundColor Cyan
    docker push "$image:latest"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    $service subido correctamente" -ForegroundColor Green
    } else {
        Write-Host "    Error al subir $service" -ForegroundColor Red
        Write-Host "    Posible solución: docker login" -ForegroundColor Yellow
    }
}

Write-Host "`n Proceso completado!" -ForegroundColor Green
Write-Host " Verifica en: https://hub.docker.com/u/keylet" -ForegroundColor Cyan
Write-Host "`n Comando para verificar:" -ForegroundColor Yellow
Write-Host "docker pull keylet/hduce-auth:latest" -ForegroundColor White
