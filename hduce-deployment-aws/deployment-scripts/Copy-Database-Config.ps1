param([string]$KeyPath="..\keys\hduce-qa-key.pem")

$tf = Get-Content "..\terraform\terraform_outputs.json" | ConvertFrom-Json
$DB_IP = $tf.databases_instance_private_ip.value
$BASTION_IP = $tf.bastion_elastic_ip.value

Write-Host "Copiando a $DB_IP..."

# 1. docker-compose.yml
$yml = Get-Content "..\instance-configs\instance-1-databases\docker-compose.yml" -Raw
ssh -i $KeyPath ec2-user@$BASTION_IP "echo '$yml' | ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cat > /opt/hduce/databases/docker-compose.yml'"

# 2. .env
$envContent = "POSTGRES_USER=postgres`nPOSTGRES_PASSWORD=postgres`nPOSTGRES_DB=postgres`nDATABASE_HOST=$DB_IP`nREDIS_HOST=$DB_IP`nRABBITMQ_HOST=$DB_IP`nPOSTGRES_PORT=5432`nREDIS_PORT=6379`nRABBITMQ_PORT=5672`nRABBITMQ_MANAGEMENT_PORT=15672"
ssh -i $KeyPath ec2-user@$BASTION_IP "echo '$envContent' | ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cat > /opt/hduce/databases/.env'"

# 3. Scripts SQL
$scripts = @("01-create-databases.sql","02-auth-data.sql","03-user-data.sql","04-appointment-data.sql","05-notification-data.sql")
foreach ($script in $scripts) {
    $content = Get-Content "..\instance-configs\instance-1-databases\init-scripts\$script" -Raw
    ssh -i $KeyPath ec2-user@$BASTION_IP "echo '$content' | ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cat > /opt/hduce/databases/init-scripts/$script'"
    Write-Host "$script OK"
}

# Verificar
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'ls -la /opt/hduce/databases/'"
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'grep -c INSERT /opt/hduce/databases/init-scripts/04-appointment-data.sql'"
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'grep -c INSERT /opt/hduce/databases/init-scripts/05-notification-data.sql'"

Write-Host "LISTO"
Write-Host "Proximo: Start-Databases.ps1"