# Install-Docker-Database.ps1
# Versión CORRECTA con IP 34.236.109.17

Write-Host " Instalando Docker en Database Instance" -ForegroundColor Cyan

$keyPath = "..\keys\hduce-qa-key.pem"
$bastionIP = "34.236.109.17"  # ¡IP CORRECTA!
$databaseIP = "172.31.27.77"

Write-Host " SSH Key: $keyPath" -ForegroundColor Gray
Write-Host " Bastion IP: $bastionIP" -ForegroundColor Gray
Write-Host "  Database IP: $databaseIP" -ForegroundColor Gray

# Comando para instalar Docker
$dockerInstallCommand = @'
echo "=== Actualizando sistema ==="
sudo yum update -y

echo "=== Instalando Docker ==="
sudo amazon-linux-extras install docker -y

echo "=== Iniciando Docker service ==="
sudo service docker start

echo "=== Agregando usuario a grupo docker ==="
sudo usermod -a -G docker ec2-user

echo "=== Verificando instalación ==="
docker --version

echo " Docker instalado exitosamente"
'@

Write-Host "
 Ejecutando instalación de Docker..." -ForegroundColor Yellow

try {
    # Construir comando SSH CORRECTO
    $sshCommand = "ssh -i \"$keyPath\" -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ProxyCommand=\"ssh -i $keyPath -W %h:%p ec2-user@$bastionIP\" ec2-user@$databaseIP \"$dockerInstallCommand\""
    
    Write-Host " Comando a ejecutar:" -ForegroundColor DarkGray
    Write-Host $sshCommand -ForegroundColor DarkGray
    
    Write-Host "
 Ejecutando... (esto puede tomar unos minutos)" -ForegroundColor Yellow
    
    # Ejecutar comando
    Invoke-Expression $sshCommand
    
    # Verificar resultado
    if ($LASTEXITCODE -eq 0) {
        Write-Host "
 ¡Docker instalado exitosamente en Database instance!" -ForegroundColor Green
    } else {
        Write-Host "
  La instalación terminó con código de salida: $LASTEXITCODE" -ForegroundColor Yellow
    }
} catch {
    Write-Host "
 Error durante la instalación: $_" -ForegroundColor Red
}

Write-Host "
 Script completado" -ForegroundColor Cyan
