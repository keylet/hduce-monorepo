# DockerHub-Push-Simple.ps1
Write-Host "=== SUBIDA A DOCKER HUB - SIMPLIFICADO ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "`n"

# Variables
$DOCKER_HUB_USER = "keylet30"
$TAG = "aws-production"
$SERVICES = @("auth", "user", "appointment", "notification", "mqtt", "metrics")

# Información
Write-Host "Usuario Docker Hub: $DOCKER_HUB_USER" -ForegroundColor Green
Write-Host "Tag: $TAG" -ForegroundColor Green
Write-Host "Servicios a subir: $($SERVICES -join ', ')" -ForegroundColor Green

Write-Host "`n⚠️  IMPORTANTE: Asegúrate de haber creado estos repositorios en Docker Hub:" -ForegroundColor Yellow
foreach ($service in $SERVICES) {
    Write-Host "  - $DOCKER_HUB_USER/hduce-$service" -ForegroundColor Blue
}

$confirmation = Read-Host "`n¿Has creado los 6 repositorios en Docker Hub? (s/n)"
if ($confirmation -ne 's') {
    Write-Host "❌ Por favor crea los repositorios primero en https://hub.docker.com" -ForegroundColor Red
    exit 1
}

# Login a Docker Hub
Write-Host "`n--- INICIANDO SESIÓN EN DOCKER HUB ---" -ForegroundColor Green
docker login -u $DOCKER_HUB_USER

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error en login a Docker Hub" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Login exitoso" -ForegroundColor Green

# Proceso para cada servicio
Write-Host "`n--- PROCESANDO IMÁGENES ---" -ForegroundColor Green
$successCount = 0
$errorCount = 0

foreach ($service in $SERVICES) {
    Write-Host "`n[$service]" -ForegroundColor Cyan
    
    # Definir nombres
    $localImage = "hduce-$service`:$TAG"
    $dockerHubImage = "$DOCKER_HUB_USER/hduce-$service`:$TAG"
    $dockerHubLatest = "$DOCKER_HUB_USER/hduce-$service`:latest"
    
    Write-Host "  Imagen local: $localImage" -ForegroundColor Gray
    
    # Paso 1: Verificar imagen local
    $imageExists = docker images --quiet "$localImage"
    if (-not $imageExists) {
        Write-Host "  ❌ Imagen local no encontrada" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    Write-Host "  ✅ Imagen local verificada" -ForegroundColor Green
    
    # Paso 2: Etiquetar para Docker Hub
    Write-Host "  Etiquetando..." -ForegroundColor Gray
    docker tag $localImage $dockerHubImage
    docker tag $localImage $dockerHubLatest
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Etiquetado completado" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Error en etiquetado" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    # Paso 3: Subir imágenes
    Write-Host "  Subiendo a Docker Hub..." -ForegroundColor Gray
    
    # Subir versión con tag
    Write-Host "    Subiendo: $dockerHubImage" -ForegroundColor DarkGray
    docker push $dockerHubImage
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    ❌ Error subiendo $dockerHubImage" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    # Subir versión latest
    Write-Host "    Subiendo: $dockerHubLatest" -ForegroundColor DarkGray
    docker push $dockerHubLatest
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ $service subido exitosamente" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "  ❌ Error subiendo latest tag" -ForegroundColor Red
        $errorCount++
    }
}

# Resumen
Write-Host "`n=== RESUMEN FINAL ===" -ForegroundColor Cyan
Write-Host "Éxitos: $successCount" -ForegroundColor Green
Write-Host "Errores: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })

if ($successCount -gt 0) {
    Write-Host "`n✅ Imágenes subidas a Docker Hub:" -ForegroundColor Green
    foreach ($service in $SERVICES) {
        Write-Host "  https://hub.docker.com/r/$DOCKER_HUB_USER/hduce-$service" -ForegroundColor Blue
    }
}

# Mostrar imágenes locales con tags de Docker Hub
Write-Host "`n--- IMÁGENES LOCALES CON TAGS DOCKER HUB ---" -ForegroundColor Green
docker images --format "table {{.Repository}}`t{{.Tag}}`t{{.Size}}" | Where-Object { $_ -match "keylet30" -or ($_ -match "hduce-" -and $_ -match "aws-production") }
