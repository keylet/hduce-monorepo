#!/bin/bash
# ============================================
# INSTANCE 3: FRONTEND - MINIMAL DOCKER SETUP
# NGINX + React Frontend
# ============================================

set -e
echo "🔄 Starting Instance 3 (Frontend) - Minimal Docker Setup..."

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

# Install Node.js (for potential frontend builds)
echo "📦 Installing Node.js..."
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Create directory structure
echo "📁 Creating HDuce directory structure..."
sudo mkdir -p /opt/hduce
sudo mkdir -p /opt/hduce/{frontend,nginx,config,logs}
sudo chown -R ec2-user:ec2-user /opt/hduce
sudo chmod -R 755 /opt/hduce

# Create nginx configuration template
echo "⚙️ Creating NGINX configuration template..."
cat > /opt/hduce/nginx/nginx.conf.template << 'EOF'
# HDuce NGINX Configuration
# Will be configured during deployment

events {
    worker_connections 1024;
}

http {
    upstream auth_service {
        server CORE_SERVICES_HOST:8000;
    }

    upstream user_service {
        server CORE_SERVICES_HOST:8001;
    }

    upstream appointment_service {
        server CORE_SERVICES_HOST:8002;
    }

    upstream notification_service {
        server CORE_SERVICES_HOST:8003;
    }

    server {
        listen 80;
        server_name _;

        # Frontend React App
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }

        # API Gateway routes
        location /api/auth/ {
            proxy_pass http://auth_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/users/ {
            proxy_pass http://user_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/appointments/ {
            proxy_pass http://appointment_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/notifications/ {
            proxy_pass http://notification_service/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Health checks
        location /health {
            return 200 "healthy";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Create docker-compose template
echo "📝 Creating docker-compose template..."
cat > /opt/hduce/frontend/docker-compose.template.yml << 'EOF'
# HDuce Frontend - Docker Compose Template
# Will be configured during deployment

version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: hduce-nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./frontend-build:/usr/share/nginx/html:ro
      - ./logs/nginx:/var/log/nginx
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

echo "✅ Instance 3 (Frontend) - Minimal setup complete!"
echo "📋 Ready for deployment script to:"
echo "   1. Build React frontend"
echo "   2. Configure NGINX"
echo "   3. Start reverse proxy"
