# Simple-Docker-Test.ps1
Write-Host " Prueba SUPER SIMPLE de conexión" -ForegroundColor Cyan

$keyPath = "..\keys\hduce-qa-key.pem"
$bastionIP = "34.236.109.17"
$databaseIP = "172.31.27.77"

Write-Host " Probando: Bastion  Database" -ForegroundColor Yellow

# Solo probar conexión básica primero
$testCmd = "ssh -i `"$keyPath`" -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ProxyCommand=`"ssh -i $keyPath -W %h:%p ec2-user@$bastionIP`" ec2-user@$databaseIP `"echo ' Conectado a Database instance' && hostname`""

try {
    Write-Host " Ejecutando comando de prueba..." -ForegroundColor Gray
    Invoke-Expression $testCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n ¡Conexión exitosa a Database instance!" -ForegroundColor Green
        Write-Host " Podemos proceder con la instalación" -ForegroundColor Green
    } else {
        Write-Host "`n Conexión falló con código: $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "`n Error: $_" -ForegroundColor Red
}
