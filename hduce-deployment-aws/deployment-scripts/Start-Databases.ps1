# Start-Databases.ps1 - VERSIÓN CORREGIDA
param([string]$KeyPath="..\keys\hduce-qa-key.pem")

$tf = Get-Content "..\terraform\terraform_outputs.json" | ConvertFrom-Json
$DB_IP = $tf.databases_instance_private_ip.value
$BASTION_IP = $tf.bastion_elastic_ip.value

Write-Host "Iniciando bases de datos en $DB_IP..."

# 1. Instalar docker-compose si no existe
Write-Host "Verificando docker-compose..."
$checkCmd = "which docker-compose || echo 'NO-INSTALADO'"
$checkResult = ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP '$checkCmd'"

if ($checkResult -match "NO-INSTALADO") {
    Write-Host "Instalando docker-compose..."
    $installCmd = "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
    ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP '$installCmd'"
}

# 2. Verificar
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'docker --version && docker-compose --version'"

# 3. Navegar al directorio
Write-Host "Navegando al directorio..."
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cd /opt/hduce/databases && pwd && ls -la'"

# 4. Iniciar contenedores CON docker-compose (binario)
Write-Host "Iniciando PostgreSQL, Redis, RabbitMQ..."
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cd /opt/hduce/databases && sudo docker-compose up -d'"

# 5. Esperar
Write-Host "Esperando inicializacion (15 segundos)..."
Start-Sleep -Seconds 15

# 6. Verificar estado
Write-Host "Verificando estado..."
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cd /opt/hduce/databases && sudo docker-compose ps'"

# 7. Verificar datos
Write-Host "Verificando datos..."
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cd /opt/hduce/databases && sudo docker-compose exec -T postgres psql -U postgres -c \"\l\"'"

Write-Host "BASES DE DATOS INICIADAS"
Write-Host "PostgreSQL (5432), Redis (6379), RabbitMQ (5672) listos"