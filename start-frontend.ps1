Write-Host "=== HDuce Medical - Frontend ===`n" -ForegroundColor Cyan
Write-Host "Iniciando aplicación en puerto 4200..." -ForegroundColor Yellow

# Verificar backend
Write-Host "`n1. Verificando backend Docker..." -ForegroundColor White
try {
    $response = Invoke-WebRequest -Uri "http://localhost/api/doctors/" -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Backend funcionando" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️ Backend no responde" -ForegroundColor Yellow
    Write-Host "   Ejecuta en otra terminal: docker-compose up -d" -ForegroundColor Gray
}

# Iniciar frontend
Write-Host "`n2. Iniciando frontend NX..." -ForegroundColor White
Write-Host "   Puerto: 4200" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:4200" -ForegroundColor Cyan
Write-Host "`n3. Presiona Ctrl+C para detener`n" -ForegroundColor Gray

# Ejecutar NX
npx nx serve frontend
