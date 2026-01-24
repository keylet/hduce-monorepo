# ============================================
# SECURITY GROUPS CONFIGURATION
# 6 Security Groups (1 Bastion + 5 HDuce instances)
# ============================================

# SECURITY GROUP 0: BASTION HOST (Jump Host)
resource "aws_security_group" "hduce_bastion_sg" {
  name        = "hduce-bastion-sg"
  description = "Security group for Bastion Host (SSH Jump Host)"
  vpc_id      = var.vpc_id

  # SSH access only from allowed CIDR (your IP or 0.0.0.0/0 for testing)
  ingress {
    description = "SSH from allowed IPs"
    from_port   = var.security_group_ports.ssh.from_port
    to_port     = var.security_group_ports.ssh.to_port
    protocol    = var.security_group_ports.ssh.protocol
    cidr_blocks = [var.bastion_allowed_cidr]
  }

  # All outbound traffic (Bastion needs to SSH to other instances)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "hduce-bastion-sg"
    Role        = "bastion"
    Project     = var.project_name
    Environment = var.environment
  }
}

# SECURITY GROUP 1: Databases Instance (NO SSH público)
resource "aws_security_group" "hduce_databases_sg" {
  name        = "hduce-databases-sg"
  description = "Security group for Databases instance (PostgreSQL, Redis, RabbitMQ)"
  vpc_id      = var.vpc_id

  # SSH access ONLY from Bastion Host
  ingress {
    description = "SSH from Bastion"
    from_port   = var.security_group_ports.ssh.from_port
    to_port     = var.security_group_ports.ssh.to_port
    protocol    = var.security_group_ports.ssh.protocol
    security_groups = [aws_security_group.hduce_bastion_sg.id]
  }

  # PostgreSQL access from core services (VPC only)
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = var.security_group_ports.postgres.from_port
    to_port     = var.security_group_ports.postgres.to_port
    protocol    = var.security_group_ports.postgres.protocol
    cidr_blocks = var.security_group_ports.postgres.cidr_blocks
  }

  # Redis access from core services (VPC only)
  ingress {
    description = "Redis from VPC"
    from_port   = var.security_group_ports.redis.from_port
    to_port     = var.security_group_ports.redis.to_port
    protocol    = var.security_group_ports.redis.protocol
    cidr_blocks = var.security_group_ports.redis.cidr_blocks
  }

  # RabbitMQ access from core services (VPC only)
  ingress {
    description = "RabbitMQ from VPC"
    from_port   = var.security_group_ports.rabbitmq.from_port
    to_port     = var.security_group_ports.rabbitmq.to_port
    protocol    = var.security_group_ports.rabbitmq.protocol
    cidr_blocks = var.security_group_ports.rabbitmq.cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "hduce-databases-sg"
    Instance    = "databases"
    Project     = var.project_name
    Environment = var.environment
  }
}

# SECURITY GROUP 2: Core Services Instance (NO SSH público)
resource "aws_security_group" "hduce_core_services_sg" {
  name        = "hduce-core-services-sg"
  description = "Security group for Core Services instance (Auth, User, Appointment, Notification)"
  vpc_id      = var.vpc_id

  # SSH access ONLY from Bastion Host
  ingress {
    description = "SSH from Bastion"
    from_port   = var.security_group_ports.ssh.from_port
    to_port     = var.security_group_ports.ssh.to_port
    protocol    = var.security_group_ports.ssh.protocol
    security_groups = [aws_security_group.hduce_bastion_sg.id]
  }

  # Auth Service (8000) - from VPC (frontend + internal)
  ingress {
    description = "Auth Service"
    from_port   = var.security_group_ports.auth_service.from_port
    to_port     = var.security_group_ports.auth_service.to_port
    protocol    = var.security_group_ports.auth_service.protocol
    cidr_blocks = var.security_group_ports.auth_service.cidr_blocks
  }

  # User Service (8001) - from VPC
  ingress {
    description = "User Service"
    from_port   = var.security_group_ports.user_service.from_port
    to_port     = var.security_group_ports.user_service.to_port
    protocol    = var.security_group_ports.user_service.protocol
    cidr_blocks = var.security_group_ports.user_service.cidr_blocks
  }

  # Appointment Service (8002) - from VPC
  ingress {
    description = "Appointment Service"
    from_port   = var.security_group_ports.appointment_service.from_port
    to_port     = var.security_group_ports.appointment_service.to_port
    protocol    = var.security_group_ports.appointment_service.protocol
    cidr_blocks = var.security_group_ports.appointment_service.cidr_blocks
  }

  # Notification Service (8003) - from VPC
  ingress {
    description = "Notification Service"
    from_port   = var.security_group_ports.notification_service.from_port
    to_port     = var.security_group_ports.notification_service.to_port
    protocol    = var.security_group_ports.notification_service.protocol
    cidr_blocks = var.security_group_ports.notification_service.cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "hduce-core-services-sg"
    Instance    = "core-services"
    Project     = var.project_name
    Environment = var.environment
  }
}

# SECURITY GROUP 3: Frontend Instance (NO SSH público)
resource "aws_security_group" "hduce_frontend_sg" {
  name        = "hduce-frontend-sg"
  description = "Security group for Frontend instance (NGINX + React)"
  vpc_id      = var.vpc_id

  # SSH access ONLY from Bastion Host
  ingress {
    description = "SSH from Bastion"
    from_port   = var.security_group_ports.ssh.from_port
    to_port     = var.security_group_ports.ssh.to_port
    protocol    = var.security_group_ports.ssh.protocol
    security_groups = [aws_security_group.hduce_bastion_sg.id]
  }

  # HTTP access from anywhere
  ingress {
    description = "HTTP from anywhere"
    from_port   = var.security_group_ports.http.from_port
    to_port     = var.security_group_ports.http.to_port
    protocol    = var.security_group_ports.http.protocol
    cidr_blocks = var.security_group_ports.http.cidr_blocks
  }

  # HTTPS access from anywhere
  ingress {
    description = "HTTPS from anywhere"
    from_port   = var.security_group_ports.https.from_port
    to_port     = var.security_group_ports.https.to_port
    protocol    = var.security_group_ports.https.protocol
    cidr_blocks = var.security_group_ports.https.cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "hduce-frontend-sg"
    Instance    = "frontend"
    Project     = var.project_name
    Environment = var.environment
  }
}

# SECURITY GROUP 4: Monitoring Instance (NO SSH público)
resource "aws_security_group" "hduce_monitoring_sg" {
  name        = "hduce-monitoring-sg"
  description = "Security group for Monitoring instance (Grafana, Prometheus, n8n)"
  vpc_id      = var.vpc_id

  # SSH access ONLY from Bastion Host
  ingress {
    description = "SSH from Bastion"
    from_port   = var.security_group_ports.ssh.from_port
    to_port     = var.security_group_ports.ssh.to_port
    protocol    = var.security_group_ports.ssh.protocol
    security_groups = [aws_security_group.hduce_bastion_sg.id]
  }

  # Grafana (3000) - from VPC only
  ingress {
    description = "Grafana dashboard"
    from_port   = var.security_group_ports.grafana.from_port
    to_port     = var.security_group_ports.grafana.to_port
    protocol    = var.security_group_ports.grafana.protocol
    cidr_blocks = var.security_group_ports.grafana.cidr_blocks
  }

  # Prometheus (9090) - from VPC only
  ingress {
    description = "Prometheus metrics"
    from_port   = var.security_group_ports.prometheus.from_port
    to_port     = var.security_group_ports.prometheus.to_port
    protocol    = var.security_group_ports.prometheus.protocol
    cidr_blocks = var.security_group_ports.prometheus.cidr_blocks
  }

  # n8n (5678) - from VPC only
  ingress {
    description = "n8n workflow automation"
    from_port   = var.security_group_ports.n8n.from_port
    to_port     = var.security_group_ports.n8n.to_port
    protocol    = var.security_group_ports.n8n.protocol
    cidr_blocks = var.security_group_ports.n8n.cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "hduce-monitoring-sg"
    Instance    = "monitoring"
    Project     = var.project_name
    Environment = var.environment
  }
}

# SECURITY GROUP 5: IoT Instance (NO SSH público)
resource "aws_security_group" "hduce_iot_sg" {
  name        = "hduce-iot-sg"
  description = "Security group for IoT instance (Mosquitto, MQTT Service, Metrics Service)"
  vpc_id      = var.vpc_id

  # SSH access ONLY from Bastion Host
  ingress {
    description = "SSH from Bastion"
    from_port   = var.security_group_ports.ssh.from_port
    to_port     = var.security_group_ports.ssh.to_port
    protocol    = var.security_group_ports.ssh.protocol
    security_groups = [aws_security_group.hduce_bastion_sg.id]
  }

  # MQTT Broker (1883) - from VPC only
  ingress {
    description = "MQTT Broker"
    from_port   = var.security_group_ports.mqtt_broker.from_port
    to_port     = var.security_group_ports.mqtt_broker.to_port
    protocol    = var.security_group_ports.mqtt_broker.protocol
    cidr_blocks = var.security_group_ports.mqtt_broker.cidr_blocks
  }

  # MQTT Service (8004) - from VPC only
  ingress {
    description = "MQTT Service API"
    from_port   = var.security_group_ports.mqtt_service.from_port
    to_port     = var.security_group_ports.mqtt_service.to_port
    protocol    = var.security_group_ports.mqtt_service.protocol
    cidr_blocks = var.security_group_ports.mqtt_service.cidr_blocks
  }

  # Metrics Service (8005) - from VPC only
  ingress {
    description = "Metrics Service API"
    from_port   = var.security_group_ports.metrics_service.from_port
    to_port     = var.security_group_ports.metrics_service.to_port
    protocol    = var.security_group_ports.metrics_service.protocol
    cidr_blocks = var.security_group_ports.metrics_service.cidr_blocks
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "hduce-iot-sg"
    Instance    = "iot"
    Project     = var.project_name
    Environment = var.environment
  }
}
