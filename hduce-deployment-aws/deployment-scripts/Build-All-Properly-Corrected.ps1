# Build-All-Properly-Corrected.ps1
Write-Host "=== CONSTRUCCIÓN DE IMÁGENES DOCKER CORREGIDAS ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "`n"

# Variables críticas
$ROOT_DIR = "C:\Users\raich\Desktop\hduce-monorepo"
$TAG = "aws-production"
$SERVICES = @(
    @{Name="auth-service"; Dockerfile="backend/auth-service/Dockerfile.aws"},
    @{Name="user-service"; Dockerfile="backend/user-service/Dockerfile.aws"},
    @{Name="appointment-service"; Dockerfile="backend/appointment-service/Dockerfile.aws"},
    @{Name="notification-service"; Dockerfile="backend/notification-service/Dockerfile.aws"},
    @{Name="mqtt-service"; Dockerfile="backend/mqtt-service/Dockerfile.aws"},
    @{Name="metrics-service"; Dockerfile="backend/metrics-service/Dockerfile.aws"}
)

# Cambiar al directorio raíz
Set-Location $ROOT_DIR
Write-Host "Directorio de trabajo: $(Get-Location)" -ForegroundColor Green
Write-Host "Construyendo desde: $ROOT_DIR" -ForegroundColor Green

# Limpiar imágenes malformadas si existen
Write-Host "`n--- LIMPIANDO IMÁGENES MAL FORMADAS ---" -ForegroundColor Yellow
docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -match "hduce--" } | ForEach-Object {
    Write-Host "Eliminando: $_" -ForegroundColor Red
    docker rmi $_ -f
}

# Construir cada servicio
Write-Host "`n--- CONSTRUYENDO 6 MICROSERVICIOS ---" -ForegroundColor Green

foreach ($service in $SERVICES) {
    $serviceName = $service.Name
    $dockerfile = $service.Dockerfile
    $simpleName = $serviceName.Replace("-service", "")
    $imageName = "hduce-$simpleName`:$TAG"
    
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Construyendo: $serviceName" -ForegroundColor Cyan
    Write-Host "  Dockerfile: $dockerfile" -ForegroundColor Gray
    Write-Host "  Nombre de imagen: $imageName" -ForegroundColor Gray
    
    # Construir la imagen
    $buildCommand = "docker build -f $dockerfile -t $imageName ."
    Write-Host "  Comando: $buildCommand" -ForegroundColor DarkGray
    
    # Ejecutar el comando
    $result = Invoke-Expression $buildCommand
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ $serviceName construido exitosamente" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Error construyendo $serviceName (código: $LASTEXITCODE)" -ForegroundColor Red
    }
}

# Verificar imágenes construidas
Write-Host "`n--- VERIFICACIÓN DE IMÁGENES CONSTRUIDAS ---" -ForegroundColor Green
docker images --format "table {{.Repository}}`t{{.Tag}}`t{{.Size}}`t{{.CreatedSince}}" | Where-Object { $_ -match "hduce-" }

Write-Host "`n=== CONSTRUCCIÓN COMPLETADA ===" -ForegroundColor Cyan
Write-Host "Total de servicios procesados: $($SERVICES.Count)" -ForegroundColor Yellow
