# Copy-Backup-Files.ps1
# Copia tus archivos de backup a los init-scripts

param(
    [string]$BackupDir = "C:\Users\raich\Desktop\HDuce-Final-Backup",
    [string]$TargetDir = "C:\Users\raich\Desktop\hduce-monorepo\hduce-deployment-aws\instance-configs\instance-1-databases\init-scripts"
)

Write-Host " HDuce - Backup Files Copier" -ForegroundColor Cyan
Write-Host " Copying 4 database backup files to init-scripts" -ForegroundColor Yellow

# Verificar directorio de origen
if (-not (Test-Path $BackupDir)) {
    Write-Error " Backup directory not found: $BackupDir"
    exit 1
}

# Verificar directorio de destino
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force
    Write-Host " Created target directory: $TargetDir" -ForegroundColor Green
}

# Archivos a copiar
$backupFiles = @{
    "auth_db.sql" = "02-auth-data.sql"
    "user_db.sql" = "03-user-data.sql" 
    "appointment_db.sql" = "04-appointment-data.sql"
    "notification_db.sql" = "05-notification-data.sql"
}

$successCount = 0

foreach ($sourceFile in $backupFiles.Keys) {
    $sourcePath = Join-Path $BackupDir $sourceFile
    $targetName = $backupFiles[$sourceFile]
    $targetPath = Join-Path $TargetDir $targetName
    
    if (Test-Path $sourcePath) {
        try {
            Copy-Item -Path $sourcePath -Destination $targetPath -Force
            $fileSize = (Get-Item $sourcePath).Length / 1KB
            Write-Host " Copied: $sourceFile  $targetName ($([math]::Round($fileSize, 2)) KB)" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host " Error copying $sourceFile : $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  Source file not found: $sourceFile" -ForegroundColor Yellow
    }
}

Write-Host "`n Summary:" -ForegroundColor Cyan
Write-Host "  Successfully copied: $successCount/4 files" -ForegroundColor Green

if ($successCount -eq 4) {
    Write-Host " All backup files copied successfully!" -ForegroundColor Green
    Write-Host " Files in init-scripts:" -ForegroundColor Yellow
    Get-ChildItem $TargetDir | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "  Some files were not copied. Check warnings above." -ForegroundColor Yellow
}
