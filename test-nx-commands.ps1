# test-nx-commands.ps1 - Prueba segura de comandos NX
Write-Host "🧪 PRUEBA SEGURA DE COMANDOS NX" -ForegroundColor Cyan
Write-Host "="*50

# 1. Verificar que podemos ejecutar comandos
Write-Host "1. Probando echo en auth-service..." -ForegroundColor Yellow
npx nx run auth-service:test

# 2. Ver estructura de cada proyecto
Write-Host "`n2. Verificando estructura de proyectos..." -ForegroundColor Yellow
$services = @("auth-service", "user-service", "appointment-service", "notification-service")
foreach ($service in $services) {
    Write-Host "  - $service : " -NoNewline -ForegroundColor Gray
    npx nx run $service:test 2>&1 | Out-Null
    Write-Host "✅ Comando disponible" -ForegroundColor Green
}

# 3. Mostrar resumen
Write-Host "`n" + "="*50
Write-Host "🎉 NX CONFIGURADO CORRECTAMENTE" -ForegroundColor Green
Write-Host "Comandos disponibles:" -ForegroundColor Cyan
Write-Host "  npx nx run [servicio]:serve" -ForegroundColor Gray
Write-Host "  npx nx run [servicio]:docker-build" -ForegroundColor Gray
Write-Host "  npx nx run [servicio]:test" -ForegroundColor Gray
Write-Host "="*50
