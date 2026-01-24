Write-Host " Subiendo imágenes a Docker Hub (keylet30)..." -ForegroundColor Green

# Subir cada imagen
Write-Host "`n Subiendo auth-service..." -ForegroundColor Yellow
docker push keylet30/hduce-auth:latest

Write-Host "`n Subiendo user-service..." -ForegroundColor Yellow
docker push keylet30/hduce-user:latest

Write-Host "`n Subiendo appointment-service..." -ForegroundColor Yellow
docker push keylet30/hduce-appointment:latest

Write-Host "`n Subiendo notification-service..." -ForegroundColor Yellow
docker push keylet30/hduce-notification:latest

Write-Host "`n Imágenes subidas a Docker Hub!" -ForegroundColor Green
Write-Host " Ver en: https://hub.docker.com/u/keylet30" -ForegroundColor Cyan
