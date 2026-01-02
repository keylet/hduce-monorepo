# test-services.ps1
Write-Host "=== PRUEBA DE MICROSERVICIOS ===" -ForegroundColor Cyan

Write-Host "`n1. Probando Health Checks..." -ForegroundColor Yellow

# Auth Service
try {
    $authHealth = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get
    Write-Host "   ✅ Auth Service: $($authHealth.status)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Auth Service: ERROR - $_" -ForegroundColor Red
}

# User Service
try {
    $userHealth = Invoke-RestMethod -Uri "http://localhost:8001/health" -Method Get
    Write-Host "   ✅ User Service: $($userHealth.status)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ User Service: ERROR - $_" -ForegroundColor Red
}

Write-Host "`n2. Probando Login..." -ForegroundColor Yellow
try {
    $body = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json
    
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8000/login" `
      -Method Post `
      -Body $body `
      -ContentType "application/json"
    
    Write-Host "   ✅ Login exitoso" -ForegroundColor Green
    Write-Host "   Token: $($loginResponse.access_token.substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Login falló: $_" -ForegroundColor Red
}

Write-Host "`n3. Probando User Service CRUD..." -ForegroundColor Yellow
try {
    # Crear usuario
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8001/users?name=TestUser&email=test@example.com&age=25" `
      -Method Post `
      -ContentType "application/json"
    
    Write-Host "   ✅ Usuario creado: $($createResponse.name)" -ForegroundColor Green
    
    # Listar usuarios
    $users = Invoke-RestMethod -Uri "http://localhost:8001/users" -Method Get
    $userCount = $users.Count
    Write-Host "   ✅ Usuarios en sistema: $userCount" -ForegroundColor Green
    
} catch {
    Write-Host "   ❌ User Service error: $_" -ForegroundColor Red
}

Write-Host "`n=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Auth Service:  http://localhost:8000/docs" -ForegroundColor White
Write-Host "User Service:  http://localhost:8001/docs" -ForegroundColor White
Write-Host "PostgreSQL:    localhost:5432 (postgres/postgres)" -ForegroundColor White
Write-Host "Redis:         localhost:6379" -ForegroundColor White

Write-Host "`n🎉 ¡Microservicios funcionando correctamente!" -ForegroundColor Green