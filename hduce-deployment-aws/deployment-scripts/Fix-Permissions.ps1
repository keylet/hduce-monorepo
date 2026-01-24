param([string]$KeyPath="..\keys\hduce-qa-key.pem")

$tf = Get-Content "..\terraform\terraform_outputs.json" | ConvertFrom-Json
$DB_IP = $tf.databases_instance_private_ip.value
$BASTION_IP = $tf.bastion_elastic_ip.value

Write-Host "Arreglando permisos..."

# 1. Cambiar dueño
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'sudo chown -R ec2-user:ec2-user /opt/hduce'"

# 2. Crear estructura
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'mkdir -p /opt/hduce/databases/init-scripts'"

# 3. Copiar docker-compose.yml
$yml = Get-Content "..\instance-configs\instance-1-databases\docker-compose.yml" -Raw
ssh -i $KeyPath ec2-user@$BASTION_IP "echo '$yml' | ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cat > /opt/hduce/databases/docker-compose.yml'"

# 4. Copiar .env
$envContent = "POSTGRES_USER=postgres`nPOSTGRES_PASSWORD=postgres`nPOSTGRES_DB=postgres`nDATABASE_HOST=$DB_IP`nREDIS_HOST=$DB_IP`nRABBITMQ_HOST=$DB_IP`nPOSTGRES_PORT=5432`nREDIS_PORT=6379`nRABBITMQ_PORT=5672`nRABBITMQ_MANAGEMENT_PORT=15672"
ssh -i $KeyPath ec2-user@$BASTION_IP "echo '$envContent' | ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cat > /opt/hduce/databases/.env'"

# 5. Copiar scripts SQL - método directo
$scripts = @("01-create-databases.sql","02-auth-data.sql","03-user-data.sql","04-appointment-data.sql","05-notification-data.sql")
foreach ($script in $scripts) {
    $content = Get-Content "..\instance-configs\instance-1-databases\init-scripts\$script" -Raw
    ssh -i $KeyPath ec2-user@$BASTION_IP "echo '$content' | ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'cat > /opt/hduce/databases/init-scripts/$script'"
    Write-Host "$script OK"
}

# 6. Verificar
ssh -i $KeyPath ec2-user@$BASTION_IP "ssh -i ~/.ssh/hduce-qa-key.pem ec2-user@$DB_IP 'ls -la /opt/hduce/databases/'"
Write-Host "LISTO"
Write-Host "Proximo: Start-Databases.ps1"