# build-from-root.ps1
# Construye imágenes Docker desde la raíz del proyecto

Write-Host "=== CONSTRUCCIÓN DESDE RAIZ DEL PROYECTO ===" -ForegroundColor Cyan

# Ir a la raíz del proyecto
$projectRoot = "C:\Users\raich\Desktop\hduce-monorepo"
cd $projectRoot

Write-Host "Ubicación: $(Get-Location)" -ForegroundColor White
Write-Host "Contexto de build: . (directorio actual)"`n -ForegroundColor White

# Servicios a construir
$services = @("auth", "user", "appointment", "notification", "mqtt", "metrics")
$dockerfilesDir = "hduce-deployment-aws\docker-images"

foreach ($service in $services) {
    Write-Host " Construyendo $service-service..." -ForegroundColor Yellow
    
    # Verificar que existe el Dockerfile
    $dockerfile = "$dockerfilesDir\Dockerfile.$service.corrected"
    if (-not (Test-Path $dockerfile)) {
        # Usar el .prod si no existe .corrected
        $dockerfile = "$dockerfilesDir\Dockerfile.$service.prod"
    }
    
    if (Test-Path $dockerfile) {
        Write-Host "   Usando: $dockerfile" -ForegroundColor Gray
        
        # Construir imagen
        docker build `
            -f $dockerfile `
            -t "hduce-$service`:test" `
            .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    $service construido exitosamente" -ForegroundColor Green
        } else {
            Write-Host "    Error construyendo $service" -ForegroundColor Red
        }
    } else {
        Write-Host "    No se encuentra Dockerfile para $service" -ForegroundColor Red
    }
}

# Resumen
Write-Host "`n Imágenes construidas:" -ForegroundColor Cyan
docker images | Where-Object {$_.Repository -like "hduce-*"} | Format-Table Repository, Tag, Size
