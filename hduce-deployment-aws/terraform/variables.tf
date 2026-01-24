# ============================================
# VARIABLES CONFIGURATION
# AWS Academy - HDuce Platform
# ============================================

# AWS Academy Fixed Resources
variable "vpc_id" {
  description = "VPC ID from AWS Academy lab"
  type        = string
  default     = "vpc-085bb31d677b71ae6"
}

variable "subnet_ids" {
  description = "List of subnet IDs from AWS Academy lab"
  type        = list(string)
  default = [
    "subnet-0d0091ab1e2d4b76b",
    "subnet-0ed9a3e2ef699005c",
    "subnet-011e288d231da16bb",
    "subnet-08076d5811774b09c",
    "subnet-061a70f3174f9267f",
    "subnet-06df82a7983560094"
  ]
}

# Instance Configuration
variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID"
  type        = string
  default     = "ami-07ff62358b87c7116"
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro only in Academy)"
  type        = string
  default     = "t3.micro"
}

# Project Configuration
variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "hduce-medical"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "qa"
}

# Key Pair Configuration
variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "hduce-qa-key"
}

# Bastion Security Configuration
variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to access Bastion host (SSH)"
  type        = string
  default     = "0.0.0.0/0"  # ⚠️ Change to your specific IP in production
}

# Security Groups Ports
variable "security_group_ports" {
  description = "Ports to open for HDuce services"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Public access
    }
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Public access
    }
    postgres = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    redis = {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    rabbitmq = {
      from_port   = 5672
      to_port     = 5672
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    # Microservices ports
    auth_service = {
      from_port   = 8000
      to_port     = 8000
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    user_service = {
      from_port   = 8001
      to_port     = 8001
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    appointment_service = {
      from_port   = 8002
      to_port     = 8002
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    notification_service = {
      from_port   = 8003
      to_port     = 8003
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    mqtt_service = {
      from_port   = 8004
      to_port     = 8004
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    metrics_service = {
      from_port   = 8005
      to_port     = 8005
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    # Monitoring ports
    grafana = {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    prometheus = {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    n8n = {
      from_port   = 5678
      to_port     = 5678
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
    # MQTT broker
    mqtt_broker = {
      from_port   = 1883
      to_port     = 1883
      protocol    = "tcp"
      cidr_blocks = ["172.31.0.0/16"]  # VPC internal only
    }
  }
}
