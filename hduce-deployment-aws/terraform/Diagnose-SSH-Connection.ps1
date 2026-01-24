# ====================================================
# DIAGNOSE-SSH-CONNECTION.PS1
# Script de diagnóstico para problemas SSH AWS
# ====================================================

param(
    [string]$BastionIP = "54.157.13.54",
    [string]$SshKeyPath = "C:\Users\raich\Desktop\hduce-monorepo\hduce-deployment-aws\keys\hduce-qa-key.pem",
    [string]$SshUser = "ec2-user"
)

function Show-Header {
    Write-Host "`n DIAGNÓSTICO DE CONEXIÓN SSH AWS" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray
    Write-Host "Bastion IP: $BastionIP" -ForegroundColor White
    Write-Host "Usuario: $SshUser" -ForegroundColor White
    Write-Host "Clave: $SshKeyPath" -ForegroundColor White
}

function Test-Connectivity {
    Write-Host "`n1.  PRUEBA DE CONECTIVIDAD:" -ForegroundColor Yellow
    
    # Ping test
    Write-Host "   Probando ping a $BastionIP..." -ForegroundColor Gray
    try {
        $ping = Test-Connection -ComputerName $BastionIP -Count 2 -Quiet
        if ($ping) {
            Write-Host "    Ping exitoso" -ForegroundColor Green
        } else {
            Write-Host "    Ping fallido" -ForegroundColor Red
        }
    } catch {
        Write-Host "    Error en ping: $_" -ForegroundColor Yellow
    }
    
    # Port test
    Write-Host "   Probando puerto 22..." -ForegroundColor Gray
    try {
        $portTest = Test-NetConnection -ComputerName $BastionIP -Port 22 -WarningAction SilentlyContinue
        if ($portTest.TcpTestSucceeded) {
            Write-Host "    Puerto 22 accesible" -ForegroundColor Green
        } else {
            Write-Host "    Puerto 22 no accesible" -ForegroundColor Red
        }
    } catch {
        Write-Host "    Error en test de puerto: $_" -ForegroundColor Yellow
    }
}

function Check-SSH-Key {
    Write-Host "`n2.  VERIFICACIÓN DE CLAVE SSH:" -ForegroundColor Yellow
    
    if (Test-Path $SshKeyPath) {
        $key = Get-Item $SshKeyPath
        Write-Host "    Archivo existe: $($key.Name)" -ForegroundColor Green
        Write-Host "   Tamaño: $($key.Length) bytes" -ForegroundColor Gray
        
        # Check format
        $firstLine = Get-Content $SshKeyPath -First 1
        if ($firstLine -match "BEGIN.*PRIVATE KEY") {
            Write-Host "    Formato de clave válido" -ForegroundColor Green
        } else {
            Write-Host "    Formato no reconocido" -ForegroundColor Red
            Write-Host "   Primera línea: $firstLine" -ForegroundColor White
        }
        
        # Fix permissions
        Write-Host "   Ajustando permisos..." -ForegroundColor Gray
        try {
            icacls $SshKeyPath /inheritance:r /grant:r "$env:USERNAME:(R)" | Out-Null
            Write-Host "    Permisos ajustados" -ForegroundColor Green
        } catch {
            Write-Host "    No se pudieron ajustar permisos" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "    Archivo NO encontrado" -ForegroundColor Red
        Write-Host "   Ruta: $SshKeyPath" -ForegroundColor White
    }
}

function Test-SSH-Connection {
    Write-Host "`n3.  PRUEBA DE CONEXIÓN SSH:" -ForegroundColor Yellow
    
    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Host "    SSH no está instalado en Windows" -ForegroundColor Red
        Write-Host "   Instalar con: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor White
        return $false
    }
    
    Write-Host "   Ejecutando prueba simple..." -ForegroundColor Gray
    $testCmd = "ssh -i `"$SshKeyPath`" -o ConnectTimeout=10 -o StrictHostKeyChecking=no $SshUser@$BastionIP 'echo SSH_TEST_OK' 2>&1"
    
    try {
        $result = Invoke-Expression $testCmd
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    CONEXIÓN SSH EXITOSA!" -ForegroundColor Green
            Write-Host "   Respuesta: $result" -ForegroundColor White
            return $true
        } else {
            Write-Host "    Error SSH (código: $LASTEXITCODE)" -ForegroundColor Red
            Write-Host "   Salida: $result" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "    Excepción: $_" -ForegroundColor Red
        return $false
    }
}

function Show-Next-Steps {
    Write-Host "`n4.  PRÓXIMOS PASOS RECOMENDADOS:" -ForegroundColor Magenta
    
    Write-Host "   A. VERIFICAR AWS CONSOLE:" -ForegroundColor White
    Write-Host "     1. EC2  Instances  Estado 'running'" -ForegroundColor Gray
    Write-Host "     2. IP Pública correcta" -ForegroundColor Gray
    Write-Host "     3. Security Groups  Puerto 22 abierto (0.0.0.0/0)" -ForegroundColor Gray
    
    Write-Host "`n   B. PRUEBA MANUAL DETALLADA:" -ForegroundColor White
    Write-Host "     ssh -vvv -i `"$SshKeyPath`" $SshUser@$BastionIP" -ForegroundColor Green
    
    Write-Host "`n   C. SOLUCIONES ALTERNATIVAS:" -ForegroundColor White
    Write-Host "     1. Usar PuTTY con clave convertida a .ppk" -ForegroundColor Gray
    Write-Host "     2. Verificar conexión desde otra red" -ForegroundColor Gray
    Write-Host "     3. Contactar soporte AWS Academy" -ForegroundColor Gray
}

# Ejecutar diagnóstico
Show-Header
Test-Connectivity
Check-SSH-Key
$sshSuccess = Test-SSH-Connection

if (-not $sshSuccess) {
    Show-Next-Steps
}

Write-Host "`n DIAGNÓSTICO COMPLETADO" -ForegroundColor Green
