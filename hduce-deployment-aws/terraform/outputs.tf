# ============================================
# OUTPUTS CONFIGURATION
# Important information after Terraform apply
# ============================================

# Key Pair Information

# Bastion Host Information
output "bastion_instance_public_ip" {
  description = "Public IP of Bastion Host"
  value       = aws_instance.hduce_bastion.public_ip
}

output "bastion_instance_private_ip" {
  description = "Private IP of Bastion Host"
  value       = aws_instance.hduce_bastion.private_ip
}

output "ssh_bastion_command" {
  description = "SSH command to connect to Bastion"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.hduce_bastion.public_ip}"
}

output "ssh_through_bastion_example" {
  description = "Example: SSH to Databases through Bastion"
  value       = "ssh -i ${local_file.private_key.filename} -J ec2-user@${aws_instance.hduce_bastion.public_ip} ec2-user@${aws_instance.hduce_databases.private_ip}"
}
output "ssh_key_path" {
  description = "Path to the generated SSH private key"
  value       = local_file.private_key.filename
}

output "ssh_public_key" {
  description = "Generated SSH public key"
  value       = tls_private_key.hduce_key.public_key_openssh
  sensitive   = true
}

# Instance Public IPs (for SSH access)
output "databases_instance_public_ip" {
  description = "Public IP of Databases instance"
  value       = aws_instance.hduce_databases.public_ip
}

output "core_services_instance_public_ip" {
  description = "Public IP of Core Services instance"
  value       = aws_instance.hduce_core_services.public_ip
}

output "frontend_instance_public_ip" {
  description = "Public IP of Frontend instance"
  value       = aws_instance.hduce_frontend.public_ip
}

output "monitoring_instance_public_ip" {
  description = "Public IP of Monitoring instance"
  value       = aws_instance.hduce_monitoring.public_ip
}

output "iot_instance_public_ip" {
  description = "Public IP of IoT instance"
  value       = aws_instance.hduce_iot.public_ip
}

# Instance Private IPs (for service discovery)
output "databases_instance_private_ip" {
  description = "Private IP of Databases instance"
  value       = aws_instance.hduce_databases.private_ip
}

output "core_services_instance_private_ip" {
  description = "Private IP of Core Services instance"
  value       = aws_instance.hduce_core_services.private_ip
}

output "frontend_instance_private_ip" {
  description = "Private IP of Frontend instance"
  value       = aws_instance.hduce_frontend.private_ip
}

output "monitoring_instance_private_ip" {
  description = "Private IP of Monitoring instance"
  value       = aws_instance.hduce_monitoring.private_ip
}

output "iot_instance_private_ip" {
  description = "Private IP of IoT instance"
  value       = aws_instance.hduce_iot.private_ip
}

# Service Endpoints
output "frontend_url" {
  description = "URL to access the frontend"
  value       = "http://${aws_instance.hduce_frontend.public_ip}"
}

output "grafana_url" {
  description = "URL to access Grafana dashboard"
  value       = "http://${aws_instance.hduce_monitoring.public_ip}:3000"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_instance.hduce_monitoring.public_ip}:9090"
}

output "n8n_url" {
  description = "URL to access n8n workflow automation"
  value       = "http://${aws_instance.hduce_monitoring.public_ip}:5678"
}

# Service API Endpoints
output "auth_service_url" {
  description = "Auth Service API endpoint"
  value       = "http://${aws_instance.hduce_core_services.private_ip}:8000"
}

output "user_service_url" {
  description = "User Service API endpoint"
  value       = "http://${aws_instance.hduce_core_services.private_ip}:8001"
}

output "appointment_service_url" {
  description = "Appointment Service API endpoint"
  value       = "http://${aws_instance.hduce_core_services.private_ip}:8002"
}

output "notification_service_url" {
  description = "Notification Service API endpoint"
  value       = "http://${aws_instance.hduce_core_services.private_ip}:8003"
}

output "mqtt_service_url" {
  description = "MQTT Service API endpoint"
  value       = "http://${aws_instance.hduce_iot.private_ip}:8004"
}

output "metrics_service_url" {
  description = "Metrics Service API endpoint"
  value       = "http://${aws_instance.hduce_iot.private_ip}:8005"
}

# Database Connection Info
output "postgresql_connection" {
  description = "PostgreSQL connection string"
  value       = "postgresql://postgres:postgres@${aws_instance.hduce_databases.private_ip}:5432"
  sensitive   = true
}

output "redis_connection" {
  description = "Redis connection string"
  value       = "redis://${aws_instance.hduce_databases.private_ip}:6379"
}

output "rabbitmq_connection" {
  description = "RabbitMQ connection string"
  value       = "amqp://guest:guest@${aws_instance.hduce_databases.private_ip}:5672/"
}

# SSH Commands
output "ssh_databases_command" {
  description = "SSH command for Databases instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.hduce_databases.public_ip}"
}

output "ssh_core_services_command" {
  description = "SSH command for Core Services instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.hduce_core_services.public_ip}"
}

output "ssh_frontend_command" {
  description = "SSH command for Frontend instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.hduce_frontend.public_ip}"
}

output "ssh_monitoring_command" {
  description = "SSH command for Monitoring instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.hduce_monitoring.public_ip}"
}

output "ssh_iot_command" {
  description = "SSH command for IoT instance"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.hduce_iot.public_ip}"
}

