Write-Host "=== PASO 2: CORRECCIÓN DE DOCKER-COMPOSE.YML ===" -ForegroundColor Cyan

$dockerComposePath = "..\instance-configs\instance-1-databases\docker-compose.yml"
$backupPath = "$dockerComposePath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Host "Archivo original: $dockerComposePath" -ForegroundColor Yellow
Write-Host "Backup: $backupPath" -ForegroundColor Yellow

# 1. Crear backup primero
if (Test-Path $dockerComposePath) {
    Copy-Item -Path $dockerComposePath -Destination $backupPath
    Write-Host "✓ Backup creado exitosamente" -ForegroundColor Green
} else {
    Write-Host "✗ Archivo no encontrado" -ForegroundColor Red
    exit 1
}

# 2. Mostrar contenido actual (primeras 15 líneas)
Write-Host "`n--- CONTENIDO ACTUAL (primeras 15 líneas) ---" -ForegroundColor Cyan
Get-Content $dockerComposePath -TotalCount 15 | ForEach-Object {
    Write-Host $_ -ForegroundColor Gray
}

# 3. Leer todo el contenido
$content = Get-Content $dockerComposePath -Raw
Write-Host "`n--- TAMAÑO DEL ARCHIVO: $($content.Length) caracteres ---" -ForegroundColor Yellow

# 4. Realizar la corrección específica
Write-Host "`n--- APLICANDO CORRECCIÓN ---" -ForegroundColor Cyan
Write-Host "Cambiando: version: '3.8'" -ForegroundColor Red
Write-Host "Por:      version: `"3.8`"" -ForegroundColor Green

$newContent = $content -replace "version:\s*'3\.8'", 'version: "3.8"'

# 5. Verificar si hubo cambio
if ($newContent -eq $content) {
    Write-Host "✗ No se pudo realizar el cambio. Buscando otros patrones..." -ForegroundColor Red
    
    # Intentar otros patrones
    $newContent = $content -replace "version: '3.8'", 'version: "3.8"'
    $newContent = $newContent -replace "version:\s*3\.8", 'version: "3.8"'
    $newContent = $newContent -replace "^\s*version:\s*'", 'version: "'
}

# 6. Guardar el archivo corregido
if ($newContent -ne $content) {
    $newContent | Out-File -FilePath $dockerComposePath -Encoding UTF8 -Force
    Write-Host "✓ Archivo corregido y guardado" -ForegroundColor Green
} else {
    Write-Host "✗ No se detectaron cambios necesarios" -ForegroundColor Yellow
}

# 7. Mostrar el resultado
Write-Host "`n--- CONTENIDO CORREGIDO (primeras 15 líneas) ---" -ForegroundColor Cyan
Get-Content $dockerComposePath -TotalCount 15 | ForEach-Object {
    if ($_ -match "version:") {
        Write-Host $_ -ForegroundColor Green
    } else {
        Write-Host $_ -ForegroundColor Gray
    }
}

# 8. Verificar la corrección
Write-Host "`n--- VERIFICACIÓN FINAL ---" -ForegroundColor Cyan
$finalContent = Get-Content $dockerComposePath
$versionLine = $finalContent | Where-Object { $_ -match '^\s*version:' }

if ($versionLine) {
    if ($versionLine -match 'version:\s*"3\.8"') {
        Write-Host "✓ CORRECTO: Versión con comillas dobles: $versionLine" -ForegroundColor Green
    } else {
        Write-Host "⚠ ADVERTENCIA: Línea de versión encontrada pero formato inesperado:" -ForegroundColor Yellow
        Write-Host "  $versionLine" -ForegroundColor Red
    }
} else {
    Write-Host "ℹ INFORMACIÓN: No se encontró línea de versión (posiblemente eliminada)" -ForegroundColor Blue
}

Write-Host "`n=== CORRECCIÓN COMPLETADA ===" -ForegroundColor Green
Write-Host "Backup guardado en: $backupPath" -ForegroundColor Yellow
