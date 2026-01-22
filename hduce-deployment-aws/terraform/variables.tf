variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type    = string
  default = "vpc-085bb31d677b71ae6"
}

variable "subnet_ids" {
  type = list(string)
  default = [
    "subnet-0d0091ab1e2d4b76b",
    "subnet-0ed9a3e2ef699005c",
    "subnet-011e288d231da16bb",
    "subnet-08076d5811774b09c",
    "subnet-061a70f3174f9267f"
  ]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type    = string
  default = "ami-07ff62358b87c7116"
}

variable "key_name" {
  type    = string
  default = "vockey"
}

variable "instance_names" {
  type = list(string)
  default = [
    "hduce-databases",
    "hduce-core-services",
    "hduce-frontend",
    "hduce-monitoring",
    "hduce-iot"
  ]
}

variable "allowed_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
