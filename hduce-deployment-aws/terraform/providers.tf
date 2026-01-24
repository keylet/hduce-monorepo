# ============================================
# PROVIDERS CONFIGURATION
# HDuce Medical Platform - AWS Academy
# Account: 696068827021
# ============================================

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "HDuce-Medical-Platform"
      Environment = "QA"
      ManagedBy   = "Terraform"
      Owner       = "Raul Pazos"
      AcademyLab  = "true"
    }
  }
}
