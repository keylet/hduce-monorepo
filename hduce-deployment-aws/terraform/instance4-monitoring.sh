#!/bin/bash
# ============================================
# INSTANCE 4: MONITORING - MINIMAL DOCKER SETUP
# Grafana, Prometheus, n8n
# ============================================

set -e
echo "🔄 Starting Instance 4 (Monitoring) - Minimal Docker Setup..."

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
sudo mkdir -p /opt/hduce/{monitoring,config,logs,data}
sudo chown -R ec2-user:ec2-user /opt/hduce
sudo chmod -R 755 /opt/hduce

# Create monitoring docker-compose template
echo "📝 Creating monitoring docker-compose template..."
cat > /opt/hduce/monitoring/docker-compose.template.yml << 'EOF'
# HDuce Monitoring - Docker Compose Template
# Will be configured during deployment

version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: hduce-prometheus
    restart: always
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana:latest
    container_name: hduce-grafana
    restart: always
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    depends_on:
      - prometheus

  n8n:
    image: n8nio/n8n:latest
    container_name: hduce-n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=admin
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  prometheus_data:
  grafana_data:
  n8n_data:
EOF

# Create Prometheus config template
echo "📊 Creating Prometheus configuration template..."
cat > /opt/hduce/monitoring/prometheus.yml.template << 'EOF'
# HDuce Prometheus Configuration
# Will be configured during deployment

global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'auth-service'
    static_configs:
      - targets: ['CORE_SERVICES_HOST:8000']

  - job_name: 'user-service'
    static_configs:
      - targets: ['CORE_SERVICES_HOST:8001']

  - job_name: 'appointment-service'
    static_configs:
      - targets: ['CORE_SERVICES_HOST:8002']

  - job_name: 'notification-service'
    static_configs:
      - targets: ['CORE_SERVICES_HOST:8003']

  - job_name: 'mqtt-service'
    static_configs:
      - targets: ['IOT_HOST:8004']

  - job_name: 'metrics-service'
    static_configs:
      - targets: ['IOT_HOST:8005']
EOF

echo "✅ Instance 4 (Monitoring) - Minimal setup complete!"
echo "📋 Ready for deployment script to:"
echo "   1. Configure Prometheus targets"
echo "   2. Setup Grafana dashboards"
echo "   3. Start monitoring stack"
