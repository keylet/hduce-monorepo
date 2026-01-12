# ============================================================================
# HDUCE INFRASTRUCTURE - AWS ACADEMY DEPLOYMENT
# Microservices Architecture for Hospital System
# ============================================================================

locals {
  name_prefix = "hduce-"
  
  subnet_mapping = {
    bastion    = var.existing_subnet_ids[0]  # us-east-1f
    public     = var.existing_subnet_ids[2]  # us-east-1a
    private    = var.existing_subnet_ids[4]  # us-east-1d
  }
  
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Deployment  = "Terraform"
    AcademyLab  = "true"
  })
}

# Security Group for Bastion/NGINX (Public)
resource "aws_security_group" "public_sg" {
  name        = "${local.name_prefix}public-sg"
  description = "Security group for public services (Bastion, NGINX)"
  vpc_id      = var.existing_vpc_id
  
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}public-sg"
    Type = "public"
  })
}

# Security Group for Backend Microservices (Private)
resource "aws_security_group" "backend_sg" {
  name        = "${local.name_prefix}backend-sg"
  description = "Security group for backend microservices"
  vpc_id      = var.existing_vpc_id
  
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  
  ingress {
    description     = "Auth Service (8000) from NGINX"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  
  ingress {
    description     = "User Service (8001) from NGINX"
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  
  ingress {
    description     = "Appointment Service (8002) from NGINX"
    from_port       = 8002
    to_port         = 8002
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  
  ingress {
    description     = "Notification Service (8003) from NGINX"
    from_port       = 8003
    to_port         = 8003
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  
  ingress {
    description = "Internal microservices communication"
    from_port   = 8000
    to_port     = 8005
    protocol    = "tcp"
    self        = true
  }
  
  ingress {
    description = "PostgreSQL (5432) internal"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }
  
  ingress {
    description = "Redis (6379) internal"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    self        = true
  }
  
  ingress {
    description = "RabbitMQ (5672) internal"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    self        = true
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}backend-sg"
    Type = "backend"
  })
}

# SSH Key for access
resource "aws_key_pair" "hduce_ssh_key" {
  key_name   = "${local.name_prefix}ssh-key"
  public_key = file("~/.ssh/id_rsa.pub")
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}ssh-key"
  })
}

# INSTANCE 1: NGINX + BASTION (Public)
resource "aws_instance" "nginx_bastion" {
  ami                    = "ami-0fa3fe0fa7920f68e"
  instance_type          = "t2.micro"
  subnet_id              = local.subnet_mapping.public
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name               = aws_key_pair.hduce_ssh_key.key_name
  
  associate_public_ip_address = true
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  
  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}nginx-bastion"
    Role        = "nginx-bastion"
    Component   = "frontend-proxy"
    Service     = "nginx,ssh-bastion"
  })
  
  user_data = base64encode(templatefile("./templates/nginx-bastion.sh", {
    environment = var.environment
  }))
}

# INSTANCE 2: ALL MICROSERVICES + DATABASES (Private)
resource "aws_instance" "backend_services" {
  ami                    = "ami-0fa3fe0fa7920f68e"
  instance_type          = "t2.medium"
  subnet_id              = local.subnet_mapping.private
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = aws_key_pair.hduce_ssh_key.key_name
  
  associate_public_ip_address = false
  
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }
  
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }
  
  tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}backend-services"
    Role        = "backend-all-in-one"
    Component   = "microservices-databases"
    Services    = "auth,users,appointments,notifications,postgres,redis,rabbitmq"
  })
  
  user_data = base64encode(templatefile("./templates/backend-services.sh", {
    environment    = var.environment
    postgres_pass  = var.db_password
    redis_pass     = var.redis_password
    rabbitmq_user  = var.rabbitmq_user
    rabbitmq_pass  = var.rabbitmq_pass
  }))
  
  depends_on = [aws_instance.nginx_bastion]
}

# Elastic IP for NGINX (Fixed IP)
resource "aws_eip" "nginx_eip" {
  domain = "vpc"
  instance = aws_instance.nginx_bastion.id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}nginx-eip"
    Role = "static-ip"
  })
}

# CloudWatch Alarms (Basic monitoring)
resource "aws_cloudwatch_metric_alarm" "high_cpu_backend" {
  alarm_name          = "${local.name_prefix}backend-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "High CPU on backend instance"
  alarm_actions       = []
  
  dimensions = {
    InstanceId = aws_instance.backend_services.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}backend-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_nginx" {
  alarm_name          = "${local.name_prefix}nginx-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "High CPU on NGINX instance"
  alarm_actions       = []
  
  dimensions = {
    InstanceId = aws_instance.nginx_bastion.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}nginx-cpu-alarm"
  })
}
