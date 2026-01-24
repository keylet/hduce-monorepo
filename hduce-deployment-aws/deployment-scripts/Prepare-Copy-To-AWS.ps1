Write-Host "=== PASO 4: COPIAR ARCHIVO CORREGIDO A AWS ===" -ForegroundColor Cyan

# Parámetros de conexión AWS
$bastionIP = "34.236.109.17"
$databaseInstanceIP = "172.31.27.77"
$sshKey = "..\..\keys\hduce-qa-key.pem"
$sshUser = "ec2-user"
$localConfigDir = "..\instance-configs\instance-1-databases"
$remoteDir = "/opt/hduce/databases"

Write-Host "Configuración AWS:" -ForegroundColor Yellow
Write-Host "  Bastion Host: $bastionIP" -ForegroundColor Gray
Write-Host "  Database Instance: $databaseInstanceIP" -ForegroundColor Gray
Write-Host "  SSH Key: $sshKey" -ForegroundColor Gray
Write-Host "  Usuario: $sshUser" -ForegroundColor Gray
Write-Host "  Directorio local: $localConfigDir" -ForegroundColor Gray
Write-Host "  Directorio remoto: $remoteDir" -ForegroundColor Gray

# Verificar que los archivos locales existen
Write-Host "`n--- VERIFICACIÓN LOCAL ---" -ForegroundColor Cyan

$requiredFiles = @(
    "docker-compose.yml",
    ".env.template",
    "init-scripts\01-create-databases.sql",
    "init-scripts\02-auth-data.sql",
    "init-scripts\03-user-data.sql",
    "init-scripts\04-appointment-data.sql",
    "init-scripts\05-notification-data.sql"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $localConfigDir $file
    if (Test-Path $fullPath) {
        Write-Host "  ✓ $file" -ForegroundColor DarkGreen
    } else {
        Write-Host "  ✗ $file NO encontrado" -ForegroundColor Red
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-Host "✗ Faltan archivos locales. No se puede continuar." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Todos los archivos locales verificados" -ForegroundColor Green

# Verificar archivo docker-compose.yml específicamente
$dockerComposePath = Join-Path $localConfigDir "docker-compose.yml"
$dockerComposeContent = Get-Content $dockerComposePath -Raw

Write-Host "`n--- VERIFICACIÓN ESPECÍFICA DOCKER-COMPOSE ---" -ForegroundColor Cyan

if ($dockerComposeContent -match 'version:\s*"3\.8"') {
    Write-Host "✓ Versión corregida: comillas dobles confirmadas" -ForegroundColor Green
} else {
    Write-Host "✗ PROBLEMA: Versión no corregida" -ForegroundColor Red
    Write-Host "  Contenido encontrado:" -ForegroundColor Gray
    Get-Content $dockerComposePath -TotalCount 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    exit 1
}

# Mostrar datos críticos que se van a copiar
Write-Host "`n--- DATOS CRÍTICOS QUE SE COPIARÁN ---" -ForegroundColor Cyan

# Contar appointments y notifications
$appointmentsPath = Join-Path $localConfigDir "init-scripts\04-appointment-data.sql"
$notificationsPath = Join-Path $localConfigDir "init-scripts\05-notification-data.sql"

if (Test-Path $appointmentsPath) {
    $appointmentCount = (Select-String -Path $appointmentsPath -Pattern "INSERT INTO").Count
    Write-Host "  Citas médicas: $appointmentCount registros" -ForegroundColor Gray
}

if (Test-Path $notificationsPath) {
    $notificationCount = (Select-String -Path $notificationsPath -Pattern "INSERT INTO").Count
    Write-Host "  Notificaciones: $notificationCount registros" -ForegroundColor Gray
}

Write-Host "`n¿Continuar con la copia a AWS? (S/N)" -ForegroundColor Yellow
$confirmation = Read-Host

if ($confirmation -notin @('S', 's', 'Y', 'y')) {
    Write-Host "Operación cancelada por el usuario" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n--- MÉTODO DE COPIA ---" -ForegroundColor Cyan
Write-Host "1. Primero copiar al Bastion" -ForegroundColor Yellow
Write-Host "2. Luego desde Bastion a Database Instance" -ForegroundColor Yellow
Write-Host "3. Método alternativo: SSH tunnel directo" -ForegroundColor Yellow

# Verificar conectividad primero
Write-Host "`n--- PRUEBA DE CONECTIVIDAD ---" -ForegroundColor Cyan

try {
    Write-Host "Probando conexión al Bastion..." -ForegroundColor Gray
    $bastionTest = ssh -i $sshKey -o StrictHostKeyChecking=no -o ConnectTimeout=5 $sshUser@$bastionIP "echo '✓ Bastion conectado'; hostname"
    Write-Host $bastionTest -ForegroundColor Green
    
    Write-Host "Probando conexión desde Bastion a Database Instance..." -ForegroundColor Gray
    $dbTest = ssh -i $sshKey -o StrictHostKeyChecking=no $sshUser@$bastionIP "ssh -o StrictHostKeyChecking=no $sshUser@$databaseInstanceIP 'echo ✓ Database Instance conectado; hostname'"
    Write-Host $dbTest -ForegroundColor Green
    
} catch {
    Write-Host "✗ Error de conectividad: $_" -ForegroundColor Red
    Write-Host "Verificar: SSH key, IPs, y grupos de seguridad" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== LISTO PARA COPIAR ===" -ForegroundColor Green
Write-Host "Todos los chequeos pasaron. Se puede proceder con la copia." -ForegroundColor Green
Write-Host "Próximo: Crear script específico de transferencia" -ForegroundColor Magenta
