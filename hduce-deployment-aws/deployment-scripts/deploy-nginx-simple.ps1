# Script para desplegar configuración NGINX en AWS instancia-2
# Versión simplificada - ejecutar desde el bastion host

param(
    [string]$InstanceIP = "172.31.75.145",
    [string]$BastionIP = "34.236.109.17",
    [string]$KeyPath = "C:\Users\raich\Desktop\hduce-monorepo\hduce-deployment-aws\keys\hduce-qa-key.pem"
)

Write-Host "=== DEPLOY NGINX CONFIGURATION TO AWS INSTANCE-2 ===" -ForegroundColor Green
Write-Host "Instance IP: $InstanceIP" -ForegroundColor Yellow
Write-Host "Bastion IP: $BastionIP" -ForegroundColor Yellow
Write-Host "Key Path: $KeyPath" -ForegroundColor Yellow

# Crear script Bash para ejecutar en AWS
$bashScript = @"
#!/bin/bash

echo "=============================================="
echo "INSTALANDO Y CONFIGURANDO NGINX EN INSTANCIA-2"
echo "=============================================="

# 1. Actualizar sistema
echo "1. Actualizando sistema..."
sudo yum update -y -q

# 2. Instalar NGINX
echo "2. Instalando NGINX..."
sudo amazon-linux-extras install nginx1.12 -y -q

# 3. Detener NGINX si está corriendo
echo "3. Deteniendo NGINX..."
sudo systemctl stop nginx 2>/dev/null || true

# 4. Crear directorios de configuración
echo "4. Creando directorios..."
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled
sudo mkdir -p /etc/nginx/conf.d

# 5. Respaldar configuración existente
echo "5. Respaldando configuración existente..."
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup 2>/dev/null || true
sudo cp -r /etc/nginx/conf.d /etc/nginx/conf.d.backup 2>/dev/null || true

# 6. Verificar que los servicios están corriendo
echo ""
echo "6. Verificando estado de microservicios..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10

# 7. Probar conectividad con los servicios
echo ""
echo "7. Probando conectividad con servicios..."
echo "   Auth Service (8000):      $(curl -s -f http://localhost:8000/health && echo 'OK' || echo 'FAIL')"
echo "   User Service (8001):      $(curl -s -f http://localhost:8001/health && echo 'OK' || echo 'FAIL')"
echo "   Appointment Service (8002): $(curl -s -f http://localhost:8002/health && echo 'OK' || echo 'FAIL')"
echo "   Notification Service (8003): $(curl -s -f http://localhost:8003/health && echo 'OK' || echo 'FAIL')"
echo "   MQTT Service (8004):      $(curl -s -f http://localhost:8004/health && echo 'OK' || echo 'FAIL')"
echo "   Metrics Service (8005):   $(curl -s -f http://localhost:8005/health && echo 'OK' || echo 'FAIL')"

# 8. Crear nueva configuración NGINX
echo ""
echo "8. Creando configuración NGINX..."

# Configuración principal NGINX
sudo tee /etc/nginx/nginx.conf > /dev/null << 'NGINX_MAIN'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Rate limiting para autenticación
    limit_req_zone \$binary_remote_addr zone=auth:10m rate=5r/m;

    # Incluir configuraciones de servicios
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NGINX_MAIN

# Configuración del sitio
sudo tee /etc/nginx/sites-available/hduce-api.conf > /dev/null << 'SITE_CONFIG'
# HCDeU API Gateway Configuration
# Enruta todo el tráfico API a los microservicios apropiados

upstream auth_service {
    server 127.0.0.1:8000;
    keepalive 32;
}

upstream user_service {
    server 127.0.0.1:8001;
    keepalive 32;
}

upstream appointment_service {
    server 127.0.0.1:8002;
    keepalive 32;
}

upstream notification_service {
    server 127.0.0.1:8003;
    keepalive 32;
}

upstream mqtt_service {
    server 127.0.0.1:8004;
    keepalive 32;
}

upstream metrics_service {
    server 127.0.0.1:8005;
    keepalive 32;
}

server {
    listen 80;
    server_name localhost 172.31.75.145;
    root /usr/share/nginx/html;

    # Configuración CORS
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, X-Requested-With' always;

    # Health checks
    location /health {
        return 200 '{"status": "healthy", "service": "nginx-api-gateway"}';
        add_header Content-Type application/json;
    }

    # Auth Service Routes
    location /auth/ {
        limit_req zone=auth burst=10 nodelay;
        proxy_pass http://auth_service/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # User Service Routes
    location /users/ {
        proxy_pass http://user_service/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Appointment Service Routes
    location /appointments/ {
        proxy_pass http://appointment_service/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Notification Service Routes
    location /notifications/ {
        proxy_pass http://notification_service/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # MQTT Service Routes
    location /mqtt/ {
        proxy_pass http://mqtt_service/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Metrics Service Routes
    location /metrics/ {
        proxy_pass http://metrics_service/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Service Health Checks
    location /auth/health {
        proxy_pass http://auth_service/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /users/health {
        proxy_pass http://user_service/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /appointments/health {
        proxy_pass http://appointment_service/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /notifications/health {
        proxy_pass http://notification_service/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /mqtt/health {
        proxy_pass http://mqtt_service/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /metrics/health {
        proxy_pass http://metrics_service/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    error_page 404 /404.html;
    location = /404.html {
        internal;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        internal;
    }
}
SITE_CONFIG

# 9. Crear enlace simbólico
echo "9. Creando enlace simbólico..."
sudo ln -sf /etc/nginx/sites-available/hduce-api.conf /etc/nginx/sites-enabled/

# 10. Verificar sintaxis de configuración
echo "10. Verificando sintaxis NGINX..."
if sudo nginx -t; then
    echo "✓ Configuración NGINX válida"
    
    # 11. Iniciar NGINX
    echo "11. Iniciando NGINX..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # 12. Verificar estado
    echo "12. Verificando estado NGINX..."
    sudo systemctl status nginx --no-pager | head -10
    
    # 13. Probar rutas básicas
    echo ""
    echo "13. Probando rutas NGINX..."
    echo "   Health Check: $(curl -s -f http://localhost/health && echo 'OK' || echo 'FAIL')"
    echo "   Auth Health:  $(curl -s -f http://localhost/auth/health && echo 'OK' || echo 'FAIL')"
    echo "   Users Health: $(curl -s -f http://localhost/users/health && echo 'OK' || echo 'FAIL')"
    
    echo ""
    echo "=============================================="
    echo "NGINX CONFIGURADO EXITOSAMENTE!"
    echo "=============================================="
    echo "Rutas configuradas:"
    echo "  http://localhost/auth/*        → Auth Service (8000)"
    echo "  http://localhost/users/*       → User Service (8001)"
    echo "  http://localhost/appointments/* → Appointment Service (8002)"
    echo "  http://localhost/notifications/* → Notification Service (8003)"
    echo "  http://localhost/mqtt/*       → MQTT Service (8004)"
    echo "  http://localhost/metrics/*    → Metrics Service (8005)"
    
else
    echo "✗ Error en configuración NGINX"
    sudo nginx -t 2>&1
    exit 1
fi
"@

# Guardar script Bash en archivo temporal
$bashScript | Out-File -FilePath "nginx-deploy.sh" -Encoding UTF8
Write-Host "Script bash creado: nginx-deploy.sh" -ForegroundColor Green

Write-Host ""
Write-Host "INSTRUCCIONES PARA EJECUTAR:" -ForegroundColor Cyan
Write-Host "1. Copiar el script a AWS:" -ForegroundColor White
Write-Host "   scp -i `"$KeyPath`" nginx-deploy.sh ec2-user@${BastionIP}:/tmp/" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Conectarse al Bastion Host:" -ForegroundColor White
Write-Host "   ssh -i `"$KeyPath`" ec2-user@${BastionIP}" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Desde el Bastion, copiar a instancia-2:" -ForegroundColor White
Write-Host "   scp -i /home/ec2-user/hduce-qa-key.pem /tmp/nginx-deploy.sh ec2-user@${InstanceIP}:/tmp/" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Conectarse a instancia-2 y ejecutar:" -ForegroundColor White
Write-Host "   ssh -i /home/ec2-user/hduce-qa-key.pem ec2-user@${InstanceIP}" -ForegroundColor Yellow
Write-Host "   chmod +x /tmp/nginx-deploy.sh" -ForegroundColor Yellow
Write-Host "   sudo bash /tmp/nginx-deploy.sh" -ForegroundColor Yellow

Write-Host ""
Write-Host "Los archivos de configuración están en: nginx-config\" -ForegroundColor Green
