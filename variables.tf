variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (qa/prod)"
  type        = string
  default     = "qa"
}

variable "owner" {
  description = "Owner name"
  type        = string
  default     = "raul-pazos"
}

variable "vpc_id" {
  description = "VPC ID (leave empty for default VPC)"
  type        = string
  default     = ""
}

variable "public_subnet_id" {
  description = "Public subnet ID"
  type        = string
  default     = ""
}

variable "download_key_path" {
  description = "Path to download SSH private key"
  type        = string
  default     = "C:/Users/raich/Downloads"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project    = "HDUCE"
    ManagedBy  = "Terraform"
    AcademyLab = "true"
  }
}
