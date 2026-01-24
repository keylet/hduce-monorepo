# ============================================
# EC2 INSTANCES CONFIGURATION
# 5 instances for HDuce Platform
# ============================================

# INSTANCE 0: BASTION HOST (Jump Host)
resource "aws_instance" "hduce_bastion" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.hduce_qa_key.key_name
  vpc_security_group_ids = [aws_security_group.hduce_bastion_sg.id]
  subnet_id              = var.subnet_ids[0]  # Use first subnet
  
  # Instance storage
  root_block_device {
    volume_type = "gp3"
    volume_size = 8  # GB (smaller, only for SSH)
    encrypted   = true
    tags = {
      Name = "hduce-bastion-root"
    }
  }

  # Tags
  tags = {
    Name        = "hduce-bastion-${random_id.instance_suffix.hex}"
    Role        = "bastion"
    Project     = var.project_name
    Environment = var.environment
    Components  = "ssh-jump-host"
  }

  # User data for Bastion (install basic tools)
  user_data = base64encode(templatefile("${path.module}/../scripts/instance0-bastion.sh", {
    project_name = var.project_name
  }))

  # Bastion MUST have public IP
  associate_public_ip_address = true
}
# INSTANCE 1: Databases (PostgreSQL, Redis, RabbitMQ)
resource "aws_instance" "hduce_databases" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.hduce_qa_key.key_name
  vpc_security_group_ids = [aws_security_group.hduce_databases_sg.id]
  subnet_id              = var.subnet_ids[0]  # Use first subnet
  
  # Instance storage
  root_block_device {
    volume_type = "gp3"
    volume_size = 20  # GB
    encrypted   = true
    tags = {
      Name = "hduce-databases-root"
    }
  }

  # Tags
  tags = {
    Name        = "hduce-databases-${random_id.instance_suffix.hex}"
    Role        = "databases"
    Project     = var.project_name
    Environment = var.environment
    Components  = "postgresql,redis,rabbitmq"
  }

  # User data script for initialization
  user_data = base64encode(templatefile("${path.module}/../scripts/instance1-databases.sh", {
    project_name = var.project_name
  }))

  # Ensure we get a public IP for SSH access in Academy
  associate_public_ip_address = true
}

# INSTANCE 2: Core Services (Auth, User, Appointment, Notification)
resource "aws_instance" "hduce_core_services" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.hduce_qa_key.key_name
  vpc_security_group_ids = [aws_security_group.hduce_core_services_sg.id]
  subnet_id              = var.subnet_ids[1]  # Use second subnet
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 15  # GB
    encrypted   = true
    tags = {
      Name = "hduce-core-services-root"
    }
  }

  tags = {
    Name        = "hduce-core-services-${random_id.instance_suffix.hex}"
    Role        = "core-services"
    Project     = var.project_name
    Environment = var.environment
    Components  = "auth-service,user-service,appointment-service,notification-service"
  }

  user_data = base64encode(templatefile("${path.module}/../scripts/instance2-services.sh", {
    project_name = var.project_name
    DB_INSTANCE_IP = aws_instance.hduce_databases.private_ip
    # JWT Configuration
    JWT_SECRET = "your-super-secret-jwt-key-change-in-production"
    JWT_ALGORITHM = "HS256"
    # Database URLs
    AUTH_DB_URL = "postgresql://postgres:postgres@${aws_instance.hduce_databases.private_ip}:5432/auth_db"
    USER_DB_URL = "postgresql://postgres:postgres@${aws_instance.hduce_databases.private_ip}:5432/user_db"
    APPOINTMENT_DB_URL = "postgresql://postgres:postgres@${aws_instance.hduce_databases.private_ip}:5432/appointment_db"
    NOTIFICATION_DB_URL = "postgresql://postgres:postgres@${aws_instance.hduce_databases.private_ip}:5432/notification_db"
    # Redis URL
    REDIS_URL = "redis://${aws_instance.hduce_databases.private_ip}:6379"
    # RabbitMQ URL
    RABBITMQ_URL = "amqp://guest:guest@${aws_instance.hduce_databases.private_ip}:5672"
  }))
  
  # Depend on databases instance
  depends_on = [aws_instance.hduce_databases]
}

# INSTANCE 3: Frontend (NGINX + React)
resource "aws_instance" "hduce_frontend" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.hduce_qa_key.key_name
  vpc_security_group_ids = [aws_security_group.hduce_frontend_sg.id]
  subnet_id              = var.subnet_ids[2]  # Use third subnet
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 10  # GB
    encrypted   = true
    tags = {
      Name = "hduce-frontend-root"
    }
  }

  tags = {
    Name        = "hduce-frontend-${random_id.instance_suffix.hex}"
    Role        = "frontend"
    Project     = var.project_name
    Environment = var.environment
    Components  = "nginx,react-frontend"
  }

  user_data = base64encode(templatefile("${path.module}/../scripts/instance3-frontend.sh", {
    project_name = var.project_name
    core_services_host = aws_instance.hduce_core_services.private_ip
  }))

  associate_public_ip_address = true
  
  # Depend on core services
  depends_on = [aws_instance.hduce_core_services]
}

# INSTANCE 4: Monitoring (Grafana, Prometheus, n8n)
resource "aws_instance" "hduce_monitoring" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.hduce_qa_key.key_name
  vpc_security_group_ids = [aws_security_group.hduce_monitoring_sg.id]
  subnet_id              = var.subnet_ids[3]  # Use fourth subnet
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 15  # GB
    encrypted   = true
    tags = {
      Name = "hduce-monitoring-root"
    }
  }

  tags = {
    Name        = "hduce-monitoring-${random_id.instance_suffix.hex}"
    Role        = "monitoring"
    Project     = var.project_name
    Environment = var.environment
    Components  = "grafana,prometheus,n8n"
  }

  user_data = base64encode(templatefile("${path.module}/../scripts/instance4-monitoring.sh", {
    project_name = var.project_name
  }))

  associate_public_ip_address = true
}

# INSTANCE 5: IoT (Mosquitto, MQTT Service, Metrics Service)
resource "aws_instance" "hduce_iot" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.hduce_qa_key.key_name
  vpc_security_group_ids = [aws_security_group.hduce_iot_sg.id]
  subnet_id              = var.subnet_ids[4]  # Use fifth subnet
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 15  # GB
    encrypted   = true
    tags = {
      Name = "hduce-iot-root"
    }
  }

  tags = {
    Name        = "hduce-iot-${random_id.instance_suffix.hex}"
    Role        = "iot"
    Project     = var.project_name
    Environment = var.environment
    Components  = "mosquitto,mqtt-service,metrics-service"
  }

  user_data = base64encode(templatefile("${path.module}/../scripts/instance5-iot.sh", {
    project_name = var.project_name
    database_host = aws_instance.hduce_databases.private_ip
  }))

  associate_public_ip_address = true
  
  # Depend on databases instance
  depends_on = [aws_instance.hduce_databases]
}



