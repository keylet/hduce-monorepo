Write-Host "=== PASO 5: TRANSFERENCIA A AWS ===" -ForegroundColor Cyan

# Configuración con ruta absoluta confirmada
$bastionIP = "34.236.109.17"
$databaseInstanceIP = "172.31.27.77"
$sshKey = "C:\Users\raich\Desktop\hduce-monorepo\hduce-deployment-aws\keys\hduce-qa-key.pem"
$sshUser = "ec2-user"
$localConfigDir = "..\instance-configs\instance-1-databases"
$remoteDir = "/opt/hduce/databases"

Write-Host "Configuración confirmada:" -ForegroundColor Yellow
Write-Host "  SSH Key: $sshKey" -ForegroundColor Gray
Write-Host "  Bastion: $sshUser@$bastionIP" -ForegroundColor Gray
Write-Host "  Database: $databaseInstanceIP" -ForegroundColor Gray
Write-Host "  Remote Dir: $remoteDir" -ForegroundColor Gray

# Verificar permisos de la clave SSH
Write-Host "`n--- VERIFICANDO PERMISOS SSH KEY ---" -ForegroundColor Cyan

if (Test-Path $sshKey) {
    $acl = Get-Acl $sshKey
    Write-Host " Archivo de clave existe" -ForegroundColor Green
    Write-Host "  Propietario: $($acl.Owner)" -ForegroundColor Gray
    Write-Host "  Tamaño: $((Get-Item $sshKey).Length) bytes" -ForegroundColor Gray
} else {
    Write-Host " Archivo de clave NO encontrado: $sshKey" -ForegroundColor Red
    exit 1
}

# Probar conexión simple primero
Write-Host "`n--- PRUEBA DE CONEXIÓN SIMPLE ---" -ForegroundColor Cyan

try {
    Write-Host "Conectando a Bastion ($bastionIP)..." -ForegroundColor Gray
    $testResult = ssh -i $sshKey -o StrictHostKeyChecking=no -o ConnectTimeout=10 $sshUser@$bastionIP "echo ' Conexión SSH exitosa'; whoami; date"
    Write-Host $testResult -ForegroundColor Green
    
} catch {
    Write-Host " Error en conexión SSH: $_" -ForegroundColor Red
    Write-Host "Sugerencias:" -ForegroundColor Yellow
    Write-Host "1. Verificar que la instancia esté corriendo" -ForegroundColor Gray
    Write-Host "2. Verificar grupos de seguridad (puerto 22 abierto)" -ForegroundColor Gray
    Write-Host "3. Verificar usuario correcto (ec2-user para Amazon Linux)" -ForegroundColor Gray
    exit 1
}

# Crear directorio temporal local para empaquetar
Write-Host "`n--- PREPARANDO ARCHIVOS LOCALES ---" -ForegroundColor Cyan

$tempDir = ".\temp-transfer-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Copiar todos los archivos necesarios al directorio temporal
$filesToCopy = @(
    "docker-compose.yml",
    ".env.template"
)

foreach ($file in $filesToCopy) {
    $source = Join-Path $localConfigDir $file
    $destination = Join-Path $tempDir $file
    Copy-Item -Path $source -Destination $destination -Force
    Write-Host "  Copiado: $file" -ForegroundColor DarkGreen
}

# Copiar init-scripts completo
$initScriptsSource = Join-Path $localConfigDir "init-scripts"
$initScriptsDest = Join-Path $tempDir "init-scripts"
Copy-Item -Path $initScriptsSource -Destination $initScriptsDest -Recurse -Force
Write-Host "  Copiado: init-scripts/ (directorio completo)" -ForegroundColor DarkGreen

# Verificar contenido del paquete
Write-Host "`nContenido del paquete a transferir:" -ForegroundColor Yellow
Get-ChildItem -Path $tempDir -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace((Resolve-Path $tempDir).Path + "\", "")
    Write-Host "  $relativePath" -ForegroundColor Gray
}

# Método 1: Transferencia directa usando SCP a través de Bastion
Write-Host "`n--- MÉTODO DE TRANSFERENCIA ---" -ForegroundColor Cyan
Write-Host "Usando: SCP a través de SSH tunnel (Bastion  Database Instance)" -ForegroundColor Yellow

# Primero, crear directorio remoto si no existe
Write-Host "`nCreando directorio remoto en Database Instance..." -ForegroundColor Gray

$createDirCommand = @"
ssh -i $sshKey -o StrictHostKeyChecking=no $sshUser@$bastionIP "
ssh -o StrictHostKeyChecking=no $sshUser@$databaseInstanceIP '
    sudo mkdir -p $remoteDir &&
    sudo mkdir -p $remoteDir/init-scripts &&
    sudo chown -R ec2-user:ec2-user $remoteDir &&
    echo "Directorios creados con permisos"
'"
"@

try {
    Write-Host "Ejecutando: Crear directorios remotos..." -ForegroundColor DarkGray
    Invoke-Expression $createDirCommand
    Write-Host " Directorios remotos creados" -ForegroundColor Green
    
} catch {
    Write-Host " Error creando directorios remotos: $_" -ForegroundColor Red
    Write-Host "Intentando método alternativo..." -ForegroundColor Yellow
}

# Método más simple: Copiar archivo por archivo
Write-Host "`n--- COPIANDO ARCHIVOS INDIVIDUALMENTE ---" -ForegroundColor Cyan

# Función para copiar un archivo
function Copy-FileToAWS {
    param(
        [string]$localFile,
        [string]$remotePath
    )
    
    Write-Host "Copiando: $(Split-Path $localFile -Leaf) ..." -ForegroundColor DarkGray -NoNewline
    
    $scpCommand = "scp -i `"$sshKey`" -o StrictHostKeyChecking=no -o ProxyJump=$sshUser@$bastionIP `"$localFile`" $sshUser@$databaseInstanceIP:`"$remotePath`""
    
    try {
        Invoke-Expression $scpCommand
        Write-Host " " -ForegroundColor Green
        return $true
    } catch {
        Write-Host " " -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor DarkRed
        return $false
    }
}

# Lista de archivos a copiar
$files = @(
    @{Local = "$tempDir\docker-compose.yml"; Remote = "$remoteDir/docker-compose.yml"},
    @{Local = "$tempDir\.env.template"; Remote = "$remoteDir/.env.template"},
    @{Local = "$tempDir\init-scripts\01-create-databases.sql"; Remote = "$remoteDir/init-scripts/01-create-databases.sql"},
    @{Local = "$tempDir\init-scripts\02-auth-data.sql"; Remote = "$remoteDir/init-scripts/02-auth-data.sql"},
    @{Local = "$tempDir\init-scripts\03-user-data.sql"; Remote = "$remoteDir/init-scripts/03-user-data.sql"},
    @{Local = "$tempDir\init-scripts\04-appointment-data.sql"; Remote = "$remoteDir/init-scripts/04-appointment-data.sql"},
    @{Local = "$tempDir\init-scripts\05-notification-data.sql"; Remote = "$remoteDir/init-scripts/05-notification-data.sql"}
)

$successCount = 0
$totalFiles = $files.Count

foreach ($file in $files) {
    if (Copy-FileToAWS -localFile $file.Local -remotePath $file.Remote) {
        $successCount++
    }
}

# Resultado
Write-Host "`n=== RESULTADO DE TRANSFERENCIA ===" -ForegroundColor Cyan
Write-Host "Archivos transferidos: $successCount/$totalFiles" -ForegroundColor $(if ($successCount -eq $totalFiles) { "Green" } else { "Yellow" })

if ($successCount -eq $totalFiles) {
    Write-Host " TODOS los archivos transferidos exitosamente" -ForegroundColor Green
} else {
    Write-Host " Algunos archivos no se pudieron transferir" -ForegroundColor Yellow
}

# Verificar archivos en destino
Write-Host "`n--- VERIFICANDO ARCHIVOS EN DESTINO ---" -ForegroundColor Cyan

$verifyCommand = @"
ssh -i $sshKey -o StrictHostKeyChecking=no $sshUser@$bastionIP "
ssh -o StrictHostKeyChecking=no $sshUser@$databaseInstanceIP '
    echo "=== Contenido de $remoteDir ===" &&
    ls -la $remoteDir/ &&
    echo "=== Contenido de init-scripts ===" &&
    ls -la $remoteDir/init-scripts/ &&
    echo "=== Verificación docker-compose.yml ===" &&
    head -3 $remoteDir/docker-compose.yml
'"
"@

try {
    Write-Host "Verificando archivos en AWS..." -ForegroundColor Gray
    Invoke-Expression $verifyCommand
    
} catch {
    Write-Host " Error verificando archivos: $_" -ForegroundColor Red
}

# Limpiar directorio temporal
Write-Host "`n--- LIMPIANDO TEMPORALES ---" -ForegroundColor Cyan
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Directorio temporal eliminado" -ForegroundColor Gray

Write-Host "`n=== TRANSFERENCIA COMPLETADA ===" -ForegroundColor Green
if ($successCount -eq $totalFiles) {
    Write-Host " LISTO para el siguiente paso: Iniciar contenedores de bases de datos" -ForegroundColor Green
} else {
    Write-Host " Revisar archivos no transferidos antes de continuar" -ForegroundColor Yellow
}
