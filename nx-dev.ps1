# nx-dev.ps1 - Scripts útiles para desarrollo con NX
param(
    [string]$Action = "help",
    [string]$Service = ""
)

switch ($Action.ToLower()) {
    "start" {
        if ($Service -eq "") {
            Write-Host "❌ Debes especificar un servicio. Ej: .\nx-dev.ps1 start auth-service" -ForegroundColor Red
        } else {
            Write-Host "🚀 Iniciando $Service..." -ForegroundColor Cyan
            npx nx run ${Service}:serve
        }
    }
    
    "build-docker" {
        if ($Service -eq "") {
            Write-Host "❌ Debes especificar un servicio. Ej: .\nx-dev.ps1 build-docker auth-service" -ForegroundColor Red
        } else {
            Write-Host "🐳 Construyendo Docker para $Service..." -ForegroundColor Cyan
            npx nx run ${Service}:docker-build
        }
    }
    
    "test" {
        if ($Service -eq "") {
            Write-Host "🧪 Ejecutando tests en todos los servicios..." -ForegroundColor Cyan
            npx nx run-many --target=test --all
        } else {
            Write-Host "🧪 Ejecutando tests en $Service..." -ForegroundColor Cyan
            npx nx run ${Service}:test
        }
    }
    
    "list" {
        Write-Host "📋 Servicios disponibles:" -ForegroundColor Cyan
        npx nx show projects
        Write-Host "`n🎯 Usa: .\nx-dev.ps1 start [servicio]" -ForegroundColor Yellow
    }
    
    "help" {
        Write-Host "🎯 COMANDOS NX PARA HDUCE" -ForegroundColor Green
        Write-Host "="*40
        Write-Host ".\nx-dev.ps1 list                 - Listar servicios"
        Write-Host ".\nx-dev.ps1 start auth-service   - Iniciar auth-service"
        Write-Host ".\nx-dev.ps1 start user-service   - Iniciar user-service"
        Write-Host ".\nx-dev.ps1 build-docker [serv]  - Construir Docker"
        Write-Host ".\nx-dev.ps1 test [serv]          - Ejecutar tests"
        Write-Host "="*40
        Write-Host "Servicios: auth-service, user-service, appointment-service, notification-service"
    }
}
