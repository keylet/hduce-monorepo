# Install-Docker-Compose.ps1
param([string]$KeyPath="..\keys\hduce-qa-key.pem")

$tf = Get-Content "..\terraform\terraform_outputs.json" | ConvertFrom-Json
$DB_IP = $tf.databases_instance_private_ip.value
$BASTION_IP = $tf.bastion_elastic_ip.value

Write-Host "Instalando docker-compose-plugin en $DB_IP..."

# Instalar plugin
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'sudo yum install -y docker-compose-plugin'"

# Verificar instalación
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'docker compose version'"

Write-Host "✅ docker-compose-plugin instalado"
Write-Host "Ejecutar Start-Databases.ps1 de nuevo"