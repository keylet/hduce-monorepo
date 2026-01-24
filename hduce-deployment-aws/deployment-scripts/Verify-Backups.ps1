# Verify-Backups.ps1
Write-Host " Verificando archivos de backup..." -ForegroundColor Cyan

$backupDir = "C:\Users\raich\Desktop\HDuce-Final-Backup"
$targetDir = "..\instance-configs\instance-1-databases\init-scripts"

Write-Host " Backup source: $backupDir" -ForegroundColor Gray
Write-Host " Target init-scripts: $targetDir" -ForegroundColor Gray

# Verificar archivos origen
Write-Host "`n Archivos en backup directory:" -ForegroundColor Yellow
Get-ChildItem $backupDir | Format-Table Name, Length, LastWriteTime

# Verificar archivos destino
Write-Host "`n Archivos en init-scripts:" -ForegroundColor Yellow
if (Test-Path $targetDir) {
    Get-ChildItem $targetDir | Format-Table Name, Length, LastWriteTime
} else {
    Write-Host " Directorio init-scripts no existe" -ForegroundColor Red
}

# Lista de archivos esperados
$expectedFiles = @("auth_db.sql", "user_db.sql", "appointment_db.sql", "notification_db.sql")
$missingCount = 0

Write-Host "`n Verificando archivos esperados..." -ForegroundColor Cyan
foreach ($file in $expectedFiles) {
    $sourcePath = Join-Path $backupDir $file
    if (Test-Path $sourcePath) {
        $size = (Get-Item $sourcePath).Length / 1KB
        Write-Host " $file - $([math]::Round($size, 2)) KB" -ForegroundColor Green
    } else {
        Write-Host " $file - NO ENCONTRADO" -ForegroundColor Red
        $missingCount++
    }
}

if ($missingCount -eq 0) {
    Write-Host "`n Todos los backups están presentes" -ForegroundColor Green
} else {
    Write-Host "`n  Faltan $missingCount archivos de backup" -ForegroundColor Yellow
}
