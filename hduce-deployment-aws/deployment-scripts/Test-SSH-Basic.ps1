# Test-SSH-Basic.ps1
Write-Host " Prueba básica de SSH" -ForegroundColor Cyan

$keyPath = "..\keys\hduce-qa-key.pem"
$bastionIP = "34.236.109.17"

Write-Host " Key: $keyPath" -ForegroundColor Gray
Write-Host " Bastion: $bastionIP" -ForegroundColor Gray

# Verificar que existe la key
if (-not (Test-Path $keyPath)) {
    Write-Host " Archivo key no encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "`n Probando conexión al Bastion..." -ForegroundColor Yellow
try {
    $result = ssh -i $keyPath -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@$bastionIP "echo ' Conectado al Bastion' && hostname && date"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " SSH exitoso" -ForegroundColor Green
        Write-Host " Output:" -ForegroundColor DarkGray
        Write-Host $result -ForegroundColor Gray
    } else {
        Write-Host " SSH falló con código: $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host " Error SSH: $_" -ForegroundColor Red
}

Write-Host "`n Prueba completada" -ForegroundColor Cyan
