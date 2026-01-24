#!/bin/bash
# instance2-services.sh - Configuración para instancia de Servicios Core

echo "=== CONFIGURANDO INSTANCIA 2: HDuce Core Services ==="

# Actualizar sistema
sudo yum update -y

# 1. Instalar Docker
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo systemctl enable docker

# 2. Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. Obtener IP de la instancia de bases de datos (se pasa como parámetro)
DB_INSTANCE_IP=$1
if [ -z "$DB_INSTANCE_IP" ]; then
    echo " Error: Se requiere la IP de la instancia de bases de datos"
    echo "   Uso: ./instance2-services.sh <ip-databases>"
    exit 1
fi

echo " Conectando a bases de datos en: $DB_INSTANCE_IP"

# 4. Crear estructura de directorios
mkdir -p /home/ec2-user/hduce/services
cd /home/ec2-user/hduce/services

# 5. Crear archivo .env con configuraciones
cat > .env << 'ENVFILE'
# Configuración de HDuce Services
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ALGORITHM=HS256

# URLs de Bases de Datos (Instancia 1)
AUTH_DB_URL=postgresql://postgres:postgres@'"${DB_INSTANCE_IP}"':5432/auth_db
USER_DB_URL=postgresql://postgres:postgres@'"${DB_INSTANCE_IP}"':5432/user_db
APPOINTMENT_DB_URL=postgresql://postgres:postgres@'"${DB_INSTANCE_IP}"':5432/appointment_db
NOTIFICATION_DB_URL=postgresql://postgres:postgres@'"${DB_INSTANCE_IP}"':5432/notification_db

# Redis y RabbitMQ
REDIS_URL=redis://'"${DB_INSTANCE_IP}"':6379
RABBITMQ_URL=amqp://guest:guest@'"${DB_INSTANCE_IP}"':5672/

# Puertos de servicios
AUTH_PORT=8000
USER_PORT=8001
APPOINTMENT_PORT=8002
NOTIFICATION_PORT=8003
ENVFILE

# 6. Crear docker-compose.yml para servicios
cat > docker-compose.yml << 'DOCKERFILE'
version: '3.8'

services:
  auth-service:
    image: hduce-auth:prod
    container_name: hduce-auth-aws
    restart: always
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${AUTH_DB_URL}
      - REDIS_URL=${REDIS_URL}
      - JWT_SECRET=${JWT_SECRET}
      - JWT_ALGORITHM=${JWT_ALGORITHM}
    depends_on:
      - wait-for-db

  user-service:
    image: hduce-user:prod
    container_name: hduce-user-aws
    restart: always
    ports:
      - "8001:8001"
    environment:
      - DATABASE_URL=${USER_DB_URL}
      - REDIS_URL=${REDIS_URL}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - wait-for-db

  appointment-service:
    image: hduce-appointment:prod
    container_name: hduce-appointment-aws
    restart: always
    ports:
      - "8002:8002"
    environment:
      - DATABASE_URL=${APPOINTMENT_DB_URL}
      - REDIS_URL=${REDIS_URL}
      - RABBITMQ_URL=${RABBITMQ_URL}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - wait-for-db

  notification-service:
    image: hduce-notification:prod
    container_name: hduce-notification-aws
    restart: always
    ports:
      - "8003:8003"
    environment:
      - DATABASE_URL=${NOTIFICATION_DB_URL}
      - REDIS_URL=${REDIS_URL}
      - RABBITMQ_URL=${RABBITMQ_URL}
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - wait-for-db

  wait-for-db:
    image: busybox
    container_name: wait-for-databases
    command: >
      sh -c "
      echo 'Esperando que PostgreSQL esté disponible...' &&
      until nc -z '"${DB_INSTANCE_IP}"' 5432; do
        sleep 2
      done &&
      echo 'PostgreSQL listo!' &&
      echo 'Esperando que Redis esté disponible...' &&
      until nc -z '"${DB_INSTANCE_IP}"' 6379; do
        sleep 2
      done &&
      echo 'Redis listo!' &&
      echo 'Esperando que RabbitMQ esté disponible...' &&
      until nc -z '"${DB_INSTANCE_IP}"' 5672; do
        sleep 2
      done &&
      echo 'RabbitMQ listo!'
      "
DOCKERFILE

# 7. Iniciar servicios
echo " Iniciando servicios HDuce..."
docker-compose up -d

echo " Instancia 2 configurada"
echo " Servicios ejecutándose:"
echo "    Auth Service: puerto 8000"
echo "    User Service: puerto 8001"
echo "    Appointment Service: puerto 8002"
echo "    Notification Service: puerto 8003"
echo " IP Pública de esta instancia: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
