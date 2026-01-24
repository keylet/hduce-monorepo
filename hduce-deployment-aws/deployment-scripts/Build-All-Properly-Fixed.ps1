# Build-All-Properly-Fixed.ps1
Write-Host "=== CONSTRUCCIÓN DE IMÁGENES DOCKER CORREGIDAS ===" -ForegroundColor Cyan
Write-Host "Fecha: \2026-01-22 23:20:04" -ForegroundColor Yellow
Write-Host "
"

# Variables críticas
$ROOT_DIR = "C:\Users\raich\Desktop\hduce-monorepo"
$TAG = "aws-production"
$SERVICES = @(
    @{Name="auth"; Path="backend/auth-service"; Dockerfile="Dockerfile.aws"},
    @{Name="user"; Path="backend/user-service"; Dockerfile="Dockerfile.aws"},
    @{Name="appointment"; Path="backend/appointment-service"; Dockerfile="Dockerfile.aws"},
    @{Name="notification"; Path="backend/notification-service"; Dockerfile="Dockerfile.aws"},
    @{Name="mqtt"; Path="backend/mqtt-service"; Dockerfile="Dockerfile.aws"},
    @{Name="metrics"; Path="backend/metrics-service"; Dockerfile="Dockerfile.aws"}
)

# Cambiar al directorio raíz
Set-Location $ROOT_DIR
Write-Host "Directorio de trabajo: \C:\Users\raich\Desktop\hduce-monorepo\hduce-deployment-aws\deployment-scripts" -ForegroundColor Green
Write-Host "Construyendo desde: $ROOT_DIR" -ForegroundColor Green

# Limpiar imágenes malformadas si existen
Write-Host "
--- LIMPIANDO IMÁGENES MAL FORMADAS ---" -ForegroundColor Yellow
docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -match "hduce--" } | ForEach-Object {
    Write-Host "Eliminando: \$_" -ForegroundColor Red
    docker rmi \$_ -f
}

# Construir cada servicio
Write-Host "
--- CONSTRUYENDO 6 MICROSERVICIOS ---" -ForegroundColor Green

foreach ($service in $SERVICES) {
    $serviceName = $service.Name
    $servicePath = $service.Path
    $dockerfile = $service.Dockerfile
    $imageName = "hduce-$serviceName:aws-production"
    $dockerfilePath = "$servicePath/$dockerfile"
    
    Write-Host "
[\23:20:04] Construyendo: $serviceName" -ForegroundColor Cyan
    Write-Host "  Ruta del servicio: $servicePath" -ForegroundColor Gray
    Write-Host "  Dockerfile: $dockerfilePath" -ForegroundColor Gray
    Write-Host "  Nombre de imagen: $imageName" -ForegroundColor Gray
    
    # Construir la imagen
    $buildCommand = "docker build -f $dockerfilePath -t $imageName ."
    Write-Host "  Comando: $buildCommand" -ForegroundColor DarkGray
    
    try {
        Invoke-Expression $buildCommand
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  \u{2705} $serviceName construido exitosamente" -ForegroundColor Green
        } else {
            Write-Host "  \u{274C} Error construyendo $serviceName (código: $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  \u{274C} Excepción construyendo $serviceName" -ForegroundColor Red
    }
}

# Verificar imágenes construidas
Write-Host "
--- VERIFICACIÓN DE IMÁGENES CONSTRUIDAS ---" -ForegroundColor Green
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | Where-Object { $_ -match "hduce-" }

Write-Host "
=== CONSTRUCCIÓN COMPLETADA ===" -ForegroundColor Cyan
Write-Host "Total de servicios procesados: $($SERVICES.Count)" -ForegroundColor Yellow
