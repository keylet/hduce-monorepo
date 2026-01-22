# Script de desarrollo rápido para HDuce
Write-Host "=== HDuce Frontend - Desarrollo ===" -ForegroundColor Cyan
Write-Host "Puerto: 4200" -ForegroundColor Yellow
Write-Host "Modo: Desarrollo" -ForegroundColor Yellow

# Verificar dependencias
if (-not (Test-Path "node_modules")) {
    Write-Host "Instalando dependencias..." -ForegroundColor Yellow
    npm install
}

# Iniciar servidor
Write-Host "`nIniciando servidor de desarrollo..." -ForegroundColor Green
Write-Host "URL: http://localhost:4200" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Usuario prueba: testuser@example.com" -ForegroundColor White
Write-Host "Contraseña: secret" -ForegroundColor White
Write-Host "`nPresiona Ctrl+C para detener" -ForegroundColor Yellow

npm run dev
