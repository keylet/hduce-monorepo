#!/bin/bash
# ============================================
# INSTANCE 5: IOT - MINIMAL DOCKER SETUP
# Mosquitto, MQTT Service, Metrics Service
# ============================================

set -e
echo "🔄 Starting Instance 5 (IoT) - Minimal Docker Setup..."

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
sudo mkdir -p /opt/hduce/{iot,config,logs,mosquitto}
sudo chown -R ec2-user:ec2-user /opt/hduce
sudo chmod -R 755 /opt/hduce

# Create mosquitto configuration
echo "📡 Creating Mosquitto configuration..."
cat > /opt/hduce/iot/mosquitto.conf << 'EOF'
# HDuce Mosquitto MQTT Broker Configuration

listener 1883 0.0.0.0
protocol mqtt

# Allow anonymous connections (for testing)
allow_anonymous true

# Persistence
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF

# Create docker-compose template
echo "📝 Creating IoT docker-compose template..."
cat > /opt/hduce/iot/docker-compose.template.yml << 'EOF'
# HDuce IoT - Docker Compose Template
# Will be configured during deployment

version: '3.8'

services:
  mosquitto:
    image: eclipse-mosquitto:2
    container_name: hduce-mosquitto
    restart: always
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
      - mosquitto_data:/mosquitto/data
      - mosquitto_log:/mosquitto/log
    command: /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf

  mqtt-service:
    image: PLACEHOLDER_MQTT_IMAGE
    container_name: hduce-mqtt
    restart: always
    ports:
      - "8004:8004"
    environment:
      - MQTT_BROKER=mosquitto
      - MQTT_PORT=1883
      - DATABASE_URL=postgresql://postgres:postgres@DATABASE_HOST:5432
    depends_on:
      - mosquitto

  metrics-service:
    image: PLACEHOLDER_METRICS_IMAGE
    container_name: hduce-metrics
    restart: always
    ports:
      - "8005:8005"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@DATABASE_HOST:5432
      - REDIS_URL=redis://DATABASE_HOST:6379
    depends_on:
      - mqtt-service

volumes:
  mosquitto_data:
  mosquitto_log:
EOF

echo "✅ Instance 5 (IoT) - Minimal setup complete!"
echo "📋 Ready for deployment script to:"
echo "   1. Configure MQTT broker"
echo "   2. Pull and start IoT services"
echo "   3. Setup metrics collection"
