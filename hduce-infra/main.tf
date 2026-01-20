# ============================================================================
# HDUCE INFRASTRUCTURE - COMPLETE WITH BASTION HOST
# Based on Technical Report Specifications
# AWS Academy Compatible
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ============================================================================
# DATA SOURCES (AWS Academy Default VPC)
# ============================================================================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

# Security Group for BASTION HOST
resource "aws_security_group" "bastion_sg" {
  name        = "hduce-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = data.aws_vpc.default.id
  
  # SSH Access from anywhere (para pruebas)
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # All outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "hduce-bastion-sg"
    Environment = "qa"
    Project     = "HDUCE"
  }
}

# Security Group for NGINX (Public Access)
resource "aws_security_group" "nginx_sg" {
  name        = "hduce-nginx-sg"
  description = "Security group for NGINX reverse proxy"
  vpc_id      = data.aws_vpc.default.id
  
  # SSH Access only from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
  # HTTP Access from anywhere
  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS Access
  ingress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # All outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "hduce-nginx-sg"
    Environment = "qa"
    Project     = "HDUCE"
  }
}

# Security Group for Backend Services (Private)
resource "aws_security_group" "backend_sg" {
  name        = "hduce-backend-sg"
  description = "Security group for backend microservices"
  vpc_id      = data.aws_vpc.default.id
  
  # SSH Access only from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
  # Allow all traffic from NGINX
  ingress {
    description     = "All from NGINX"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.nginx_sg.id]
  }
  
  # Allow inter-service communication
  ingress {
    description = "Inter-service communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  
  # Allow all outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "hduce-backend-sg"
    Environment = "qa"
    Project     = "HDUCE"
  }
}

# ============================================================================
# BASTION HOST (Critical Security Component)
# ============================================================================

resource "aws_instance" "bastion_host" {
  ami           = "ami-0fa3fe0fa7920f68e"  # Amazon Linux 2023
  instance_type = "t2.micro"
  
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  
  key_name = "hduce-ssh-key"
  
  associate_public_ip_address = true
  
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "hduce-bastion-root"
    }
  }
  
  tags = {
    Name        = "hduce-bastion-host"
    Role        = "bastion-host"
    Environment = "qa"
    Project     = "HDUCE"
    Owner       = "raul-pazos"
  }
  
  # User Data for Bastion Setup
  user_data = <<-EOF
              #!/bin/bash
              echo "=== HDUCE BASTION HOST ==="
              echo "Secure SSH Access Point"
              echo "========================="
              sudo yum update -y
              sudo yum install -y git curl wget
              echo "Bastion ready!"
              EOF
  
  user_data_replace_on_change = true
}

# ============================================================================
# NGINX REVERSE PROXY (Public)
# ============================================================================

resource "aws_instance" "nginx_instance" {
  ami           = "ami-0fa3fe0fa7920f68e"  # Amazon Linux 2023
  instance_type = "t2.micro"
  
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  
  key_name = "hduce-ssh-key"
  
  associate_public_ip_address = true
  
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "hduce-nginx-root"
    }
  }
  
  tags = {
    Name        = "hduce-nginx-proxy"
    Role        = "nginx-reverse-proxy"
    Environment = "qa"
    Project     = "HDUCE"
    Owner       = "raul-pazos"
  }
  
  # User Data for NGINX Setup
  user_data = <<-EOF
              #!/bin/bash
              echo "=== HDUCE NGINX ==="
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "NGINX installed"
              EOF
  
  user_data_replace_on_change = true
}

# ============================================================================
# BACKEND SERVICES (Private)
# ============================================================================

resource "aws_instance" "backend_instance" {
  ami           = "ami-0fa3fe0fa7920f68e"  # Amazon Linux 2023
  instance_type = "t2.micro"
  
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  
  key_name = "hduce-ssh-key"
  
  associate_public_ip_address = false
  
  root_block_device {
    volume_size = 12
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "hduce-backend-root"
    }
  }
  
  tags = {
    Name        = "hduce-backend-services"
    Role        = "backend-microservices"
    Environment = "qa"
    Project     = "HDUCE"
    Owner       = "raul-pazos"
  }
  
  # User Data for Backend Setup
  user_data = <<-EOF
              #!/bin/bash
              echo "=== HDUCE BACKEND ==="
              sudo yum update -y
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              echo "Backend ready for Docker"
              EOF
  
  user_data_replace_on_change = true
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "bastion_public_ip" {
  value       = aws_instance.bastion_host.public_ip
  description = "Public IP address of Bastion Host"
}

output "nginx_public_ip" {
  value       = aws_instance.nginx_instance.public_ip
  description = "Public IP address of NGINX reverse proxy"
}

output "backend_private_ip" {
  value       = aws_instance.backend_instance.private_ip
  description = "Private IP address of backend services"
}

output "ssh_bastion_command" {
  value       = "ssh -i ~/.ssh/hduce-ssh-key.pem ec2-user@${aws_instance.bastion_host.public_ip}"
  description = "SSH command to connect to Bastion Host"
}

output "ssh_nginx_via_bastion" {
  value       = "ssh -i ~/.ssh/hduce-ssh-key.pem -o ProxyCommand='ssh -i ~/.ssh/hduce-ssh-key.pem -W %h:%p ec2-user@${aws_instance.bastion_host.public_ip}' ec2-user@${aws_instance.nginx_instance.private_ip}"
  description = "SSH command to connect to NGINX via Bastion"
}

output "ssh_backend_via_bastion" {
  value       = "ssh -i ~/.ssh/hduce-ssh-key.pem -o ProxyCommand='ssh -i ~/.ssh/hduce-ssh-key.pem -W %h:%p ec2-user@${aws_instance.bastion_host.public_ip}' ec2-user@${aws_instance.backend_instance.private_ip}"
  description = "SSH command to connect to Backend via Bastion"
}

output "nginx_url" {
  value       = "http://${aws_instance.nginx_instance.public_ip}"
  description = "Public URL for NGINX reverse proxy"
}

output "deployment_summary" {
  value = <<-EOT

  ====================================================
  HDUCE INFRASTRUCTURE - BASTION HOST ARCHITECTURE
  ====================================================
  
  [BASTION HOST - Secure Gateway]
    Public IP: ${aws_instance.bastion_host.public_ip}
    SSH: ssh -i ~/.ssh/hduce-ssh-key.pem ec2-user@${aws_instance.bastion_host.public_ip}
  
  [NGINX REVERSE PROXY]
    Public IP: ${aws_instance.nginx_instance.public_ip}
    URL: http://${aws_instance.nginx_instance.public_ip}
    Private IP: ${aws_instance.nginx_instance.private_ip}
  
  [BACKEND SERVICES]
    Private IP: ${aws_instance.backend_instance.private_ip}
    No public access - Bastion only
  
  [SECURITY]
     Bastion: SSH from anywhere (port 22)
     NGINX: HTTP/HTTPS public, SSH from Bastion only
     Backend: SSH from Bastion only, traffic from NGINX
  
  [NEXT STEPS]
  1. Create SSH key: ssh-keygen -t rsa -b 4096 -f ~/.ssh/hduce-ssh-key
  2. Import key to AWS: aws ec2 import-key-pair --key-name hduce-ssh-key --public-key-material fileb://~/.ssh/hduce-ssh-key.pub
  3. Access via: ${aws_instance.bastion_host.public_ip}
  
  ====================================================
  EOT
  
  description = "Complete deployment summary"
}
