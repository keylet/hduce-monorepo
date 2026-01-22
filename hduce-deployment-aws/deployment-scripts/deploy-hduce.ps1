# deploy-hduce.ps1
# Script principal para desplegar HDuce en AWS

Write-Host "=== DESPLIEGUE HDuce EN AWS ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)"`n

# Variables
$terraformDir = "..\terraform"
$dockerImagesDir = "..\docker-images"
$instanceConfigsDir = "..\instance-configs"

function Show-Menu {
    Write-Host "`n=== MENÚ PRINCIPAL ===" -ForegroundColor Yellow
    Write-Host "1. Verificar AWS y Terraform" -ForegroundColor White
    Write-Host "2. Construir imágenes Docker" -ForegroundColor White
    Write-Host "3. Desplegar infraestructura AWS" -ForegroundColor White
    Write-Host "4. Configurar instancias EC2" -ForegroundColor White
    Write-Host "5. Probar despliegue" -ForegroundColor White
    Write-Host "6. Destruir infraestructura" -ForegroundColor Red
    Write-Host "0. Salir" -ForegroundColor Gray
}

function Step1-Verify-AWS {
    Write-Host "`n PASO 1: Verificando AWS..." -ForegroundColor Green
    
    # Verificar AWS CLI
    try {
        aws --version
        Write-Host "  AWS CLI: OK" -ForegroundColor Green
    } catch {
        Write-Host "   AWS CLI no encontrado" -ForegroundColor Red
    }
    
    # Verificar Terraform
    try {
        terraform version
        Write-Host "  Terraform: OK" -ForegroundColor Green
    } catch {
        Write-Host "   Terraform no encontrado" -ForegroundColor Red
    }
    
    # Verificar archivos
    if (Test-Path $terraformDir) {
        Write-Host "  Directorio Terraform: OK" -ForegroundColor Green
    } else {
        Write-Host "   No se encuentra $terraformDir" -ForegroundColor Red
    }
}

function Step2-Build-Docker {
    Write-Host "`n PASO 2: Construyendo imágenes Docker..." -ForegroundColor Green
    
    if (Test-Path $dockerImagesDir) {
        cd $dockerImagesDir
        Write-Host "  Ejecutando build-all.ps1..." -ForegroundColor Yellow
        .\build-all.ps1
        cd ..
    } else {
        Write-Host "   No se encuentra $dockerImagesDir" -ForegroundColor Red
    }
}

function Step3-Deploy-AWS {
    Write-Host "`n  PASO 3: Desplegando en AWS..." -ForegroundColor Yellow
    Write-Host "  Esto creará 5 instancias EC2 (t3.micro)" -ForegroundColor White
    
    $confirm = Read-Host "¿Continuar? (s/n)"
    if ($confirm -ne 's') { return }
    
    if (Test-Path $terraformDir) {
        cd $terraformDir
        
        Write-Host "  Inicializando Terraform..." -ForegroundColor Yellow
        terraform init
        
        Write-Host "  Planificando despliegue..." -ForegroundColor Yellow
        terraform plan
        
        Write-Host "  Aplicando configuración..." -ForegroundColor Yellow
        terraform apply -auto-approve
        
        Write-Host "  Mostrando outputs..." -ForegroundColor Yellow
        terraform output
        
        cd ..
    } else {
        Write-Host "   No se encuentra $terraformDir" -ForegroundColor Red
    }
}

# Menú principal
do {
    Show-Menu
    $choice = Read-Host "`nSelecciona una opción"
    
    switch ($choice) {
        '1' { Step1-Verify-AWS }
        '2' { Step2-Build-Docker }
        '3' { Step3-Deploy-AWS }
        '4' { Write-Host "Configurar instancias (Pendiente)" -ForegroundColor Yellow }
        '5' { Write-Host "Probar despliegue (Pendiente)" -ForegroundColor Yellow }
        '6' { 
            Write-Host "  DESTRUIR TODO EN AWS" -ForegroundColor Red
            $confirm = Read-Host "¿Seguro? (escribe 'DESTRUIR' para confirmar)"
            if ($confirm -eq 'DESTRUIR') {
                cd $terraformDir
                terraform destroy -auto-approve
                cd ..
            }
        }
        '0' { Write-Host "Saliendo..." -ForegroundColor Gray; break }
        default { Write-Host "Opción no válida" -ForegroundColor Red }
    }
} while ($choice -ne '0')

Write-Host "`n=== FIN DEL SCRIPT ===" -ForegroundColor Cyan
