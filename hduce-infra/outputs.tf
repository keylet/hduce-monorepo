output "nginx_bastion_info" {
  description = "Información del NGINX + Bastion Host"
  value = {
    public_ip   = aws_instance.nginx_bastion.public_ip
    public_dns  = aws_instance.nginx_bastion.public_dns
    ssh_command = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.nginx_bastion.public_ip}"
  }
}

output "backend_services_info" {
  description = "Información del backend de microservicios"
  value = {
    private_ip    = aws_instance.backend_services.private_ip
    auth_service  = "http://${aws_instance.backend_services.private_ip}:8000"
    user_service  = "http://${aws_instance.backend_services.private_ip}:8001"
    appointment_service = "http://${aws_instance.backend_services.private_ip}:8002"
    notification_service = "http://${aws_instance.backend_services.private_ip}:8003"
  }
}

output "nginx_eip_info" {
  description = "Información de la IP elástica de NGINX"
  value = {
    public_ip = aws_eip.nginx_eip.public_ip
    public_dns = aws_eip.nginx_eip.public_dns
    url = "http://${aws_eip.nginx_eip.public_ip}"
  }
}

output "ssh_access_instructions" {
  description = "Instrucciones para acceder vía SSH"
  value = <<-EOT
    Para acceder a los microservicios:
    1. Conéctate al Bastion: ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.nginx_bastion.public_ip}
    2. Desde el Bastion, conéctate a backend: ssh ${aws_instance.backend_services.private_ip}
    
    Endpoints disponibles:
    - NGINX: http://${aws_eip.nginx_eip.public_ip}
    - Auth Service: http://${aws_eip.nginx_eip.public_ip}/auth/
    - User Service: http://${aws_eip.nginx_eip.public_ip}/users/
    
    Credenciales de prueba:
    Usuario: emergency
    Contraseña: test123
  EOT
}
