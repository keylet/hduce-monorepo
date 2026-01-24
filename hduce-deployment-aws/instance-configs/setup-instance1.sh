#!/bin/bash
# setup-instance1.sh - Para instancia Databases

echo "=== CONFIGURANDO INSTANCIA 1: DATABASES ==="

# 1. Instalar Docker
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user

# 2. Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. Crear estructura de carpetas
mkdir -p ~/hduce/databases
cd ~/hduce/databases

# 4. Copiar configuración
echo "Copiando configuración de bases de datos..."

# 5. Iniciar servicios
docker-compose -f instance1-databases.yml up -d

echo " Instancia 1 configurada"
echo "PostgreSQL: 5432, Redis: 6379, RabbitMQ: 5672/15672"
