# Fix-DockerCompose.ps1
$KeyPath = "..\keys\hduce-qa-key.pem"

$tf = Get-Content "..\terraform\terraform_outputs.json" | ConvertFrom-Json
$DB_IP = $tf.databases_instance_private_ip.value
$BASTION_IP = $tf.bastion_elastic_ip.value

Write-Host "Arreglando docker-compose.yml..." -ForegroundColor Yellow

# Leer y arreglar
$yml = Get-Content "..\instance-configs\instance-1-databases\docker-compose.yml" -Raw
$ymlFixed = $yml -replace 'version:\s*3\.8', 'version: "3.8"'

# Copiar arreglado
ssh -i $KeyPath ec2-user@$BASTION_IP "echo '$ymlFixed' | ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cat > /opt/hduce/databases/docker-compose.yml'"

Write-Host "✅ docker-compose.yml arreglado" -ForegroundColor Green

# Iniciar contenedores
Write-Host "Iniciando contenedores..." -ForegroundColor Yellow
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cd /opt/hduce/databases && sudo docker-compose up -d'"

Write-Host "Esperando 10 segundos..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Verificar
Write-Host "Verificando estado..." -ForegroundColor Yellow
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cd /opt/hduce/databases && sudo docker-compose ps'"

Write-Host "✅ COMPLETADO" -ForegroundColor Green
