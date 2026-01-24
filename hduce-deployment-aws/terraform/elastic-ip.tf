# ====================================================
# elastic-ip.tf
# Configuración de IP Elástica para Bastion Host
# ====================================================

# Resource: Elastic IP para Bastion
resource "aws_eip" "hduce_bastion_eip" {
  instance = aws_instance.hduce_bastion.id
  domain   = "vpc"
  
  tags = {
    Name = "hduce-bastion-eip"
    Project = "hduce"
    Environment = "qa"
  }
}

# Output: IP Elástica del Bastion
output "bastion_elastic_ip" {
  description = "Elastic IP del Bastion Host"
  value       = aws_eip.hduce_bastion_eip.public_ip
}

output "bastion_eip_allocation_id" {
  description = "ID de asignación de la EIP"
  value       = aws_eip.hduce_bastion_eip.allocation_id
  sensitive   = true
}

# Actualizar output del comando SSH
output "ssh_bastion_command_eip" {
  description = "Comando SSH usando IP Elástica"
  value       = "ssh -i ../keys/hduce-qa-key.pem ec2-user@${aws_eip.hduce_bastion_eip.public_ip}"
}
