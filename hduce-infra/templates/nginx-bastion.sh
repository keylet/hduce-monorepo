#!/bin/bash
ENVIRONMENT="${environment}"

echo "Configurando HDUCE NGINX para entorno: $ENVIRONMENT"

sudo yum update -y
sudo yum install -y nginx docker
sudo systemctl start docker nginx
sudo systemctl enable docker nginx

# Configuración básica de NGINX
sudo tee /etc/nginx/nginx.conf > /dev/null <<'NGINXCONF'
user nginx;
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name _;
        
        location / {
            return 200 "NGINX HDUCE - Servicio temporal\nEntorno: $ENVIRONMENT\n";
        }
        
        location /health {
            return 200 "healthy\n";
        }
    }
}
NGINXCONF

sudo systemctl restart nginx
echo "NGINX configurado. IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
