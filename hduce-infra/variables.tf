# Variables globales
variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "qa"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "hduce"
}

# Variables de infraestructura existente
variable "existing_vpc_id" {
  description = "ID de la VPC existente en AWS Academy"
  type        = string
  default     = "vpc-2ddc0c50"
}

variable "existing_subnet_ids" {
  description = "Lista de subnets existentes para asignar a recursos"
  type        = list(string)
  default = [
    "subnet-1a93ed14",  # us-east-1f
    "subnet-fe77bfcf",  # us-east-1e  
    "subnet-e224a7c3",  # us-east-1a
    "subnet-bcd783f1",  # us-east-1b
    "subnet-d5a82cb3",  # us-east-1d
    "subnet-fb72f3a4",  # us-east-1c
  ]
}

# Mapeo de subnets a zonas de disponibilidad
variable "subnet_az_mapping" {
  description = "Mapeo de subnet IDs a zonas de disponibilidad"
  type        = map(string)
  default = {
    "subnet-1a93ed14" = "us-east-1f"
    "subnet-fe77bfcf" = "us-east-1e"
    "subnet-e224a7c3" = "us-east-1a"
    "subnet-bcd783f1" = "us-east-1b"
    "subnet-d5a82cb3" = "us-east-1d"
    "subnet-fb72f3a4" = "us-east-1c"
  }
}

# Variables de instancias
variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nombre del key pair SSH"
  type        = string
  default     = "hduce-key"
}

# Obtener IP pública automáticamente
variable "my_ip" {
  description = "Tu IP pública para acceso SSH"
  type        = string
}

# Tags comunes
variable "common_tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default = {
    Project     = "HDUCE"
    ManagedBy   = "Terraform"
    Environment = "qa"
    Owner       = "Raul-Pazos"
    AcademyLab  = "true"
  }
}

# Variables para credenciales de bases de datos
variable "db_password" {
  description = "Contraseña para PostgreSQL"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Contraseña para Redis"
  type        = string
  sensitive   = true
}

variable "rabbitmq_user" {
  description = "Usuario para RabbitMQ"
  type        = string
}

variable "rabbitmq_pass" {
  description = "Contraseña para RabbitMQ"
  type        = string
  sensitive   = true
}
