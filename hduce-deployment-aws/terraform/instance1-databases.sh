# Install Docker Compose
echo "🎭 Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.24.0"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create directory structure for HDuce
echo "📁 Creating HDuce directory structure..."
sudo mkdir -p /opt/hduce
sudo mkdir -p /opt/hduce/{databases,config,backups,scripts,logs}
sudo chown -R ec2-user:ec2-user /opt/hduce
sudo chmod -R 755 /opt/hduce

# Install PostgreSQL client tools (for backup restoration)
echo "🗄️ Installing PostgreSQL client tools..."
sudo yum install -y postgresql

# Create docker-compose template for databases
echo "⚙️ Creating docker-compose template for databases..."
cat > /opt/hduce/databases/docker-compose.template.yml << 'EOF'
# HDuce Databases - Docker Compose Template
# Will be configured during deployment phase

version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: hduce-postgres
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: hduce-redis
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: hduce-rabbitmq
    restart: always
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    ports:
      - "5672:5672"   # AMQP
      - "15672:15672" # Management UI
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:
EOF

echo "✅ Instance 1 (Databases) - Minimal setup complete!"
echo "📋 Ready for:"
echo "   1. Deployment script to start databases"
echo "   2. Backup restoration from: /opt/hduce/backups/"
