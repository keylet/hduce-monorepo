# Copy-Backups-To-InitScripts.ps1
Write-Host " Copiando backups a init-scripts..." -ForegroundColor Cyan

$backupDir = "C:\Users\raich\Desktop\HDuce-Final-Backup"
$targetDir = "..\instance-configs\instance-1-databases\init-scripts"

# Crear directorio si no existe
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force
    Write-Host " Directorio creado: $targetDir" -ForegroundColor Green
}

# Mapeo de archivos
$fileMap = @{
    "auth_db.sql" = "02-auth-data.sql"
    "user_db.sql" = "03-user-data.sql"
    "appointment_db.sql" = "04-appointment-data.sql"
    "notification_db.sql" = "05-notification-data.sql"
}

$successCount = 0
$totalCount = $fileMap.Count

foreach ($sourceFile in $fileMap.Keys) {
    $sourcePath = Join-Path $backupDir $sourceFile
    $targetFile = $fileMap[$sourceFile]
    $targetPath = Join-Path $targetDir $targetFile
    
    if (Test-Path $sourcePath) {
        try {
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
            $size = (Get-Item $sourcePath).Length / 1KB
            Write-Host " $sourceFile  $targetFile ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host " Error copiando $sourceFile : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Archivo no encontrado: $sourceFile" -ForegroundColor Yellow
    }
}

Write-Host "`n Resultado: $successCount/$totalCount archivos copiados" -ForegroundColor Cyan

if ($successCount -eq $totalCount) {
    Write-Host " ¡Todos los backups copiados exitosamente!" -ForegroundColor Green
    
    # Mostrar contenido final
    Write-Host "`n Archivos en init-scripts:" -ForegroundColor Yellow
    Get-ChildItem $targetDir | Format-Table Name, Length, LastWriteTime
} else {
    Write-Host "  Algunos archivos no se copiaron. Revisa los errores." -ForegroundColor Yellow
}
