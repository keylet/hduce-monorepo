output "frontend_url" {
  value = "http://${aws_instance.frontend.public_ip}"
}

output "grafana_url" {
  value = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "instance_ips" {
  value = {
    databases = {
      private = aws_instance.databases.private_ip
      public  = aws_instance.databases.public_ip
    }
    core_services = {
      private = aws_instance.core_services.private_ip
      public  = aws_instance.core_services.public_ip
    }
    frontend = {
      private = aws_instance.frontend.private_ip
      public  = aws_instance.frontend.public_ip
    }
    monitoring = {
      private = aws_instance.monitoring.private_ip
      public  = aws_instance.monitoring.public_ip
    }
    iot = {
      private = aws_instance.iot.private_ip
      public  = aws_instance.iot.public_ip
    }
  }
}

output "ssh_commands" {
  value = <<-EOT
  Databases: ssh -i ${var.key_name}.pem ec2-user@${aws_instance.databases.public_ip}
  Services: ssh -i ${var.key_name}.pem ec2-user@${aws_instance.core_services.public_ip}
  Frontend: ssh -i ${var.key_name}.pem ec2-user@${aws_instance.frontend.public_ip}
  Monitoring: ssh -i ${var.key_name}.pem ec2-user@${aws_instance.monitoring.public_ip}
  IoT: ssh -i ${var.key_name}.pem ec2-user@${aws_instance.iot.public_ip}
  EOT
}
