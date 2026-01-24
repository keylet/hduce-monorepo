#!/bin/bash
# instance1-databases.sh - Configuración para instancia de Bases de Datos

echo "=== CONFIGURANDO INSTANCIA 1: HDuce Databases ==="

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

# 3. Crear estructura de directorios
mkdir -p /home/ec2-user/hduce/databases
cd /home/ec2-user/hduce/databases

# 4. Crear docker-compose.yml para bases de datos
cat > docker-compose.yml << 'DOCKERFILE'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: hduce-postgres-aws
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: hduce-redis-aws
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: hduce-rabbitmq-aws
    restart: always
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:
DOCKERFILE

# 5. Crear script de inicialización de bases de datos
cat > init.sql << 'SQL'
-- Crear bases de datos para HDuce
CREATE DATABASE auth_db;
CREATE DATABASE user_db;
CREATE DATABASE appointment_db;
CREATE DATABASE notification_db;

-- Conceder privilegios
GRANT ALL PRIVILEGES ON DATABASE auth_db TO postgres;
GRANT ALL PRIVILEGES ON DATABASE user_db TO postgres;
GRANT ALL PRIVILEGES ON DATABASE appointment_db TO postgres;
GRANT ALL PRIVILEGES ON DATABASE notification_db TO postgres;
SQL

# 6. Iniciar servicios
docker-compose up -d

echo " Instancia 1 configurada"
echo " Servicios:"
echo "    PostgreSQL: puerto 5432 (auth_db, user_db, appointment_db, notification_db)"
echo "    Redis: puerto 6379"
echo "    RabbitMQ: puerto 5672 (management: 15672)"
echo " IP Privada de esta instancia: $(hostname -I | awk '{print $1}')"
