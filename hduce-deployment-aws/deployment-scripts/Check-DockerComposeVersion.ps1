Write-Host "=== PASO 1: VERIFICACIÓN DE DOCKER-COMPOSE.YML ===" -ForegroundColor Cyan
Write-Host "Directorio de trabajo: $(Get-Location)" -ForegroundColor Yellow

$dockerComposePath = "..\instance-configs\instance-1-databases\docker-compose.yml"
Write-Host "Ruta del archivo: $dockerComposePath" -ForegroundColor Yellow

# Verificar si el archivo existe
if (Test-Path $dockerComposePath) {
    Write-Host "✓ Archivo encontrado" -ForegroundColor Green
    
    Write-Host "`n--- Mostrando primeras 10 líneas ---" -ForegroundColor Cyan
    $firstLines = Get-Content $dockerComposePath -TotalCount 10
    $firstLines | ForEach-Object {
        Write-Host $_ -ForegroundColor Gray
    }
    
    Write-Host "`n--- Buscando línea de versión ---" -ForegroundColor Cyan
    $content = Get-Content $dockerComposePath
    $versionLine = $content | Where-Object { $_ -match '^\s*version:' }
    
    if ($versionLine) {
        Write-Host "PROBLEMA IDENTIFICADO:" -ForegroundColor Red
        Write-Host "Línea actual: $versionLine" -ForegroundColor Red
        
        # Analizar tipo de comillas
        if ($versionLine -match "version:\s*'") {
            Write-Host "Tipo: Comillas simples - INCOMPATIBLE con Docker Compose v5" -ForegroundColor Red
        }
        elseif ($versionLine -match 'version:\s*"') {
            Write-Host "Tipo: Comillas dobles - CORRECTO" -ForegroundColor Green
        }
        else {
            Write-Host "Tipo: Sin comillas - VERIFICAR" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "No se encontró línea de versión" -ForegroundColor Yellow
    }
    
    # Mostrar estructura básica del archivo
    Write-Host "`n--- Estructura del archivo ---" -ForegroundColor Cyan
    $content | Select-String '^\s*(version:|services:|postgres:|redis:|rabbitmq:)' | ForEach-Object {
        Write-Host $_ -ForegroundColor DarkGray
    }
    
} else {
    Write-Host "✗ Archivo NO encontrado en: $dockerComposePath" -ForegroundColor Red
    Write-Host "Directorios disponibles en ..\instance-configs\:" -ForegroundColor Yellow
    Get-ChildItem "..\instance-configs\" | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
}
