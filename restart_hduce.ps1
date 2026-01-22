# restart_hduce.ps1 - Reinicio rápido del sistema HDuce
Write-Host "Reiniciando sistema HDuce..."

# 1. Parar servicios
docker-compose down

# 2. Esperar
Start-Sleep -Seconds 3

# 3. Levantar solo dependencias
docker-compose up -d postgres redis rabbitmq

# 4. Esperar PostgreSQL
Write-Host "Esperando PostgreSQL..."
Start-Sleep -Seconds 15

# 5. Verificar PostgreSQL
docker-compose exec postgres pg_isready -U postgres
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ PostgreSQL no listo, esperando más..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# 6. Levantar servicios de aplicación
docker-compose up -d auth-service user-service appointment-service notification-service nginx

# 7. Verificar estado
Write-Host "`nEsperando 10 segundos para que servicios inicien..."
Start-Sleep -Seconds 10

Write-Host "`nEstado final:"
docker-compose ps

# 8. Probar login automático
Write-Host "`nProbando sistema..."
$loginBody = @{
    email = "testuser@example.com"
    password = "secret"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json"
    
    $response.access_token | Out-File "token.txt" -Encoding UTF8
    Write-Host "✅ Sistema funcionando. Token guardado en token.txt" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error en login: $_" -ForegroundColor Red
}
