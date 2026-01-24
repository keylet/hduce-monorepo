# Script para probar NGINX después de la configuración

param(
    [string]$InstanceIP = "172.31.75.145",
    [string]$BastionIP = "34.236.109.17",
    [string]$KeyPath = "C:\Users\raich\Desktop\hduce-monorepo\hduce-deployment-aws\keys\hduce-qa-key.pem"
)

Write-Host "=== TEST NGINX CONFIGURATION ===" -ForegroundColor Green

$testCommands = @"
#!/bin/bash

echo "=== TESTING NGINX CONFIGURATION ==="
echo ""

# Función para probar endpoint
test_endpoint() {
    local url="\$1"
    local description="\$2"
    echo -n "Testing \$description... "
    if curl -s -f -o /dev/null "\$url"; then
        echo "✓ OK"
        return 0
    else
        echo "✗ FAILED"
        return 1
    fi
}

echo "1. Probando endpoints básicos de salud:"
test_endpoint "http://localhost/health" "NGINX Health"
test_endpoint "http://localhost/auth/health" "Auth Service"
test_endpoint "http://localhost/users/health" "User Service"
test_endpoint "http://localhost/appointments/health" "Appointment Service"
test_endpoint "http://localhost/notifications/health" "Notification Service"
test_endpoint "http://localhost/mqtt/health" "MQTT Service"
test_endpoint "http://localhost/metrics/health" "Metrics Service"

echo ""
echo "2. Probando endpoint de login:"
echo "   Enviando credenciales de prueba..."
LOGIN_RESPONSE=\$(curl -s -X POST http://localhost/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","password":"secret"}')

if echo "\$LOGIN_RESPONSE" | grep -q "access_token"; then
    echo "   ✓ Login exitoso"
    TOKEN=\$(echo "\$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    echo "   Token obtenido: \${TOKEN:0:30}..."
    
    echo ""
    echo "3. Probando endpoints protegidos (si el token fue obtenido):"
    if [ -n "\$TOKEN" ]; then
        echo "   Probando /users/me con token JWT..."
        USER_RESPONSE=\$(curl -s -f -H "Authorization: Bearer \$TOKEN" http://localhost/users/me)
        if [ \$? -eq 0 ]; then
            echo "   ✓ Endpoint protegido accesible"
            echo "   Respuesta: \$(echo "\$USER_RESPONSE" | head -c 100)..."
        else
            echo "   ✗ No se pudo acceder al endpoint protegido"
        fi
    fi
else
    echo "   ✗ Login falló"
    echo "   Respuesta: \$LOGIN_RESPONSE"
fi

echo ""
echo "=== RESUMEN ==="
echo "Para probar manualmente:"
echo "1. Login: curl -X POST http://localhost/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"testuser@example.com\",\"password\":\"secret\"}'"
echo "2. Salud: curl http://localhost/health"
echo "3. Servicios: curl http://localhost/[service]/health"
echo ""
echo "Configuración NGINX:"
echo "- Puerto: 80"
echo "- Rutas configuradas correctamente"
"@

# Guardar script de prueba
$testCommands | Out-File -FilePath "test-nginx.sh" -Encoding UTF8
Write-Host "Script de prueba creado: test-nginx.sh" -ForegroundColor Green

Write-Host ""
Write-Host "Para ejecutar las pruebas:" -ForegroundColor Cyan
Write-Host "1. Copiar a AWS:" -ForegroundColor White
Write-Host "   scp -i `"$KeyPath`" test-nginx.sh ec2-user@${BastionIP}:/tmp/" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Desde el Bastion:" -ForegroundColor White
Write-Host "   scp -i /home/ec2-user/hduce-qa-key.pem /tmp/test-nginx.sh ec2-user@${InstanceIP}:/tmp/" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Ejecutar:" -ForegroundColor White
Write-Host "   ssh -i /home/ec2-user/hduce-qa-key.pem ec2-user@${InstanceIP} 'bash /tmp/test-nginx.sh'" -ForegroundColor Yellow
