#!/bin/bash
# ============================================
# INSTANCE 2: CORE SERVICES - MINIMAL DOCKER SETUP
# Auth, User, Appointment, Notification Services
# ============================================

set -e
echo "🔄 Starting Instance 2 (Core Services) - Minimal Docker Setup..."

# Update system
sudo yum update -y
sudo yum install -y git curl wget unzip

# Install Docker
echo "🐳 Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
echo "🎭 Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.24.0"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create directory structure
echo "📁 Creating HDuce directory structure..."
sudo mkdir -p /opt/hduce
sudo mkdir -p /opt/hduce/{services,config,logs,scripts}
sudo chown -R ec2-user:ec2-user /opt/hduce
sudo chmod -R 755 /opt/hduce

# Create environment template
echo "⚙️ Creating environment template..."
cat > /opt/hduce/config/.env.template << 'EOF'
# HDuce Core Services Configuration
# Will be populated during deployment

# Database Connection (from Instance 1)
DATABASE_URL=postgresql://postgres:postgres@DATABASE_HOST:5432

# Service URLs
AUTH_SERVICE_URL=http://localhost:8000
USER_SERVICE_URL=http://localhost:8001
APPOINTMENT_SERVICE_URL=http://localhost:8002
NOTIFICATION_SERVICE_URL=http://localhost:8003

# JWT Configuration (CRITICAL - DO NOT CHANGE)
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ALGORITHM=HS256
TOKEN_EXPIRY=24h

# Message Queue (from Instance 1)
RABBITMQ_URL=amqp://guest:guest@DATABASE_HOST:5672/
REDIS_URL=redis://DATABASE_HOST:6379
EOF

# Create docker-compose template
echo "📝 Creating docker-compose template..."
cat > /opt/hduce/services/docker-compose.template.yml << 'EOF'
# HDuce Core Services - Docker Compose Template
# Will be configured during deployment

version: '3.8'

services:
  auth-service:
    image: PLACEHOLDER_AUTH_IMAGE
    container_name: hduce-auth
    restart: always
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@DATABASE_HOST:5432/auth_db
      - JWT_SECRET=your-super-secret-jwt-key-change-in-production
    depends_on:
      - postgres
    volumes:
      - ./logs/auth:/app/logs

  user-service:
    image: PLACEHOLDER_USER_IMAGE
    container_name: hduce-user
    restart: always
    ports:
      - "8001:8001"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@DATABASE_HOST:5432/user_db
      - AUTH_SERVICE_URL=http://auth-service:8000
    depends_on:
      - auth-service

  appointment-service:
    image: PLACEHOLDER_APPOINTMENT_IMAGE
    container_name: hduce-appointment
    restart: always
    ports:
      - "8002:8002"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@DATABASE_HOST:5432/appointment_db
      - USER_SERVICE_URL=http://user-service:8001
    depends_on:
      - user-service

  notification-service:
    image: PLACEHOLDER_NOTIFICATION_IMAGE
    container_name: hduce-notification
    restart: always
    ports:
      - "8003:8003"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@DATABASE_HOST:5432/notification_db
      - RABBITMQ_URL=amqp://guest:guest@DATABASE_HOST:5672/
    depends_on:
      - appointment-service
      - rabbitmq
EOF

echo "✅ Instance 2 (Core Services) - Minimal setup complete!"
echo "📋 Ready for deployment script to:"
echo "   1. Configure environment variables"
echo "   2. Pull Docker images"
echo "   3. Start services"
