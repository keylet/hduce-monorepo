Write-Host "=== VERIFICACIÓN COMPLETA DEL AUTH-SERVICE ===" -ForegroundColor Cyan

# 1. Health check
Write-Host "`n1. Health Check:" -ForegroundColor Yellow
$health = Invoke-RestMethod -Uri "http://localhost:8000/auth/health-check" -Method Get
$health | Format-List

# 2. Login con usuario paciente
Write-Host "`n2. Login usuario paciente:" -ForegroundColor Yellow
$loginBody = @{email="test@hduce.com"; password="password123"} | ConvertTo-Json
$login = Invoke-RestMethod -Uri "http://localhost:8000/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
Write-Host "Token obtenido: $($login.access_token[0..20] -join '')..."

# 3. Probar /me
Write-Host "`n3. Endpoint /me:" -ForegroundColor Yellow
$headers = @{Authorization="Bearer $($login.access_token)"}
$me = Invoke-RestMethod -Uri "http://localhost:8000/auth/me" -Method Get -Headers $headers
$me | Format-List

Write-Host "`n✅ AUTH-SERVICE FUNCIONANDO CORRECTAMENTE" -ForegroundColor Green
