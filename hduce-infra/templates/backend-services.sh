#!/bin/bash
# ============================================================================
# TEMPLATE: BACKEND SERVICES CONFIGURATION
# ============================================================================

ENVIRONMENT="${environment}"

echo "Configurando Backend HDUCE: $ENVIRONMENT"

# Actualizar e instalar Docker
sudo yum update -y
sudo yum install -y docker git
sudo systemctl start docker
sudo systemctl enable docker

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Crear estructura
mkdir -p /opt/hduce
cd /opt/hduce

# Crear docker-compose.yml básico
cat > docker-compose.yml <<'EOF'
version: "3.8"

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: hduce_db
      POSTGRES_USER: hduce_user
      POSTGRES_PASSWORD: password123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass redispass123
    ports:
      - "6379:6379"

  rabbitmq:
    image: rabbitmq:3-management-alpine
    environment:
      RABBITMQ_DEFAULT_USER: admin
      RABBITMQ_DEFAULT_PASS: admin123
    ports:
      - "5672:5672"
      - "15672:15672"

  auth-service:
    image: hduce-monorepo-auth-service:latest
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://hduce_user:password123@postgres:5432/hduce_db

  user-service:
    image: hduce-monorepo-user-service:latest
    ports:
      - "8001:8001"

  appointment-service:
    image: hduce-monorepo-appointment-service:latest
    ports:
      - "8002:8002"

  notification-service:
    image: hduce-monorepo-notification-service:latest
    ports:
      - "8003:8003"

volumes:
  postgres_data:
EOF

echo "Backend configurado. Ejecuta 'docker-compose up -d' para iniciar servicios"