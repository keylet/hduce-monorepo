# build-docker-images.ps1
# Script para construir imágenes Docker de HDuce para AWS

Write-Host "=== CONSTRUCCIÓN DE IMÁGENES DOCKER HDuce ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)"`n

# Variables
$dockerhubUser = "tuusuario"  # CAMBIAR POR TU USUARIO DOCKERHUB
$services = @{
    "auth" = @{Port=8000; Path="../../../../backend/auth-service"}
    "user" = @{Port=8001; Path="../../../../backend/user-service"}
    "appointment" = @{Port=8002; Path="../../../../backend/appointment-service"}
    "notification" = @{Port=8003; Path="../../../../backend/notification-service"}
    "mqtt" = @{Port=8004; Path="../../../../backend/mqtt-service"}
    "metrics" = @{Port=8005; Path="../../../../backend/metrics-service"}
}

# Función para construir una imagen
function Build-DockerImage {
    param($serviceName, $serviceConfig)
    
    Write-Host "`n Construyendo $serviceName-service..." -ForegroundColor Yellow
    
    # Verificar que existe el directorio del servicio
    if (-not (Test-Path $serviceConfig.Path)) {
        Write-Host "   No se encuentra: $($serviceConfig.Path)" -ForegroundColor Red
        return $false
    }
    
    # Verificar que existe requirements.txt
    $reqFile = Join-Path $serviceConfig.Path "requirements.txt"
    if (-not (Test-Path $reqFile)) {
        Write-Host "    No se encuentra requirements.txt en $serviceName" -ForegroundColor Yellow
    }
    
    # Nombre de la imagen
    $imageName = "$dockerhubUser/hduce-$serviceName`:`latest"
    $dockerfile = "Dockerfile.$serviceName.prod"
    
    # Verificar si existe Dockerfile específico
    if (-not (Test-Path $dockerfile)) {
        Write-Host "    No se encuentra $dockerfile, usando template genérico..." -ForegroundColor Yellow
        
        # Crear Dockerfile temporal
        @"
# Dockerfile para $serviceName-service
FROM python:3.11-slim AS builder

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copiar shared-libraries
WORKDIR /build
COPY ../../../shared-libraries ./shared-libraries
WORKDIR /build/shared-libraries
RUN pip wheel --wheel-dir /wheels .

# Copiar servicio
WORKDIR /build
COPY $($serviceConfig.Path.Replace('../../../../', '')) ./service
WORKDIR /build/service
RUN pip wheel --wheel-dir /wheels -r requirements.txt

# Runtime
FROM python:3.11-slim
WORKDIR /app

# Dependencias runtime
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar wheels
COPY --from=builder /wheels /wheels
RUN pip install --no-index --find-links=/wheels /wheels/*

# Copiar código
COPY --from=builder /build/service /app

# Configuración
ENV PYTHONPATH=/app
ENV PORT=$($serviceConfig.Port)

EXPOSE $($serviceConfig.Port)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "$($serviceConfig.Port)"]
"@ | Out-File -FilePath "Dockerfile.$serviceName.temp" -Encoding UTF8
        
        $dockerfile = "Dockerfile.$serviceName.temp"
    }
    
    # Construir imagen
    Write-Host "   Construyendo imagen: $imageName" -ForegroundColor Gray
    try {
        docker build `
            -f $dockerfile `
            -t $imageName `
            .
        
        Write-Host "   $serviceName construido exitosamente" -ForegroundColor Green
        
        # Limpiar temporal si existe
        if (Test-Path "Dockerfile.$serviceName.temp") {
            Remove-Item "Dockerfile.$serviceName.temp"
        }
        
        return $true
    } catch {
        Write-Host "   Error construyendo $serviceName: $_" -ForegroundColor Red
        return $false
    }
}

# Ejecutar construcción
$successCount = 0
$totalCount = $services.Count

foreach ($service in $services.Keys) {
    if (Build-DockerImage -serviceName $service -serviceConfig $services[$service]) {
        $successCount++
    }
}

# Resumen
Write-Host "`n RESUMEN DE CONSTRUCCIÓN:" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Gray
Write-Host "Total servicios: $totalCount" -ForegroundColor White
Write-Host "Construidos exitosamente: $successCount" -ForegroundColor $(if($successCount -eq $totalCount){"Green"}else{"Yellow"})
Write-Host "Fallidos: $($totalCount - $successCount)" -ForegroundColor $(if(($totalCount - $successCount) -gt 0){"Red"}else{"White"})

if ($successCount -gt 0) {
    Write-Host "`n Imágenes construidas localmente:" -ForegroundColor Green
    docker images | Where-Object {$_.Repository -like "*hduce-*"} | Format-Table Repository, Tag, Size
    
    Write-Host "`n SIGUIENTES PASOS:" -ForegroundColor Cyan
    Write-Host "1. Iniciar sesión en DockerHub: docker login" -ForegroundColor White
    Write-Host "2. Subir imágenes: foreach(`$s in `$services.Keys) { docker push `$dockerhubUser/hduce-`$s`:`latest }" -ForegroundColor White
    Write-Host "3. Luego ejecutar Paso 3: Desplegar infraestructura AWS" -ForegroundColor White
} else {
    Write-Host "`n No se construyeron imágenes exitosamente" -ForegroundColor Red
    Write-Host "Revisa los errores arriba y corrige los Dockerfiles" -ForegroundColor Yellow
}
