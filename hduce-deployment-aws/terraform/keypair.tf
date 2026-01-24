# ============================================
# KEY PAIR CONFIGURATION
# SSH key for EC2 instance access
# ============================================

resource "tls_private_key" "hduce_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "hduce_qa_key" {
  key_name   = var.key_name
  public_key = tls_private_key.hduce_key.public_key_openssh
  
  tags = {
    Name        = "hduce-qa-ssh-key"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Save private key locally for SSH access
resource "local_file" "private_key" {
  content  = tls_private_key.hduce_key.private_key_pem
  filename = "${path.module}/../keys/hduce-qa-key.pem"
  
  # Set proper permissions (Linux/Mac)
  provisioner "local-exec" {
    command = "chmod 400 ${path.module}/../keys/hduce-qa-key.pem"
    interpreter = ["bash", "-c"]
  }
}

# Save public key locally
resource "local_file" "public_key" {
  content  = tls_private_key.hduce_key.public_key_openssh
  filename = "${path.module}/../keys/hduce-qa-key.pub"
}
