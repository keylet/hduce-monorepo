# Create-DockerHub-Repos.ps1
Write-Host "=== INSTRUCCIONES PARA CREAR REPOSITORIOS EN DOCKER HUB ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date -Format 'yyyy-MM-dd:ss')" -ForegroundColor Yellow
Write-Host "`n"

$DOCKER_HUB_USER = "keylet30"
$SERVICES = @("auth", "user", "appointment", "notification", "mqtt", "metrics")

Write-Host "⚠️  MANUAL REQUIRED: Debes crear estos 6 repositorios en Docker Hub manualmente" -ForegroundColor Yellow
Write-Host "`nSigue estos pasos:" -ForegroundColor Green
Write-Host "1. Ve a https://hub.docker.com" -ForegroundColor Blue
Write-Host "2. Inicia sesión con tu cuenta: $DOCKER_HUB_USER" -ForegroundColor Blue
Write-Host "3. Haz clic en 'Create Repository'" -ForegroundColor Blue
Write-Host "4. Repite para cada uno de estos nombres:" -ForegroundColor Blue
Write-Host "`n"

$counter = 1
foreach ($service in $SERVICES) {
    Write-Host "$counter. Nombre del repositorio: $DOCKER_HUB_USER/hduce-$service" -ForegroundColor Cyan
    Write-Host "   - Visibilidad: Pública" -ForegroundColor Gray
    Write-Host "   - Descripción: HDCE Microservice - $service service" -ForegroundColor Gray
    Write-Host "   - Build settings: Dejar por defecto" -ForegroundColor Gray
    Write-Host ""
    $counter++
}

Write-Host "`n6. Después de crear los 6 repositorios, ejecuta: .\DockerHub-Push-Simple.ps1" -ForegroundColor Green

Write-Host "`n=== URLs DIRECTAS PARA CREAR REPOSITORIOS ===" -ForegroundColor Cyan
foreach ($service in $SERVICES) {
    Write-Host "https://hub.docker.com/repository/create?namespace=$DOCKER_HUB_USER&name=hduce-$service&visibility=public" -ForegroundColor Blue
}

Write-Host "`n=== VERIFICACIÓN DESPUÉS DE CREAR ===" -ForegroundColor Cyan
Write-Host "Una vez creados, puedes verificar en:" -ForegroundColor Green
Write-Host "https://hub.docker.com/u/$DOCKER_HUB_USER/repositories" -ForegroundColor Blue
