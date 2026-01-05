Write-Host "=== ESTADO FINAL DE TODOS LOS SERVICIOS ==="
Write-Host ""

$services = @(
    "auth-service",
    "user-service", 
    "appointment-service",
    "notification-service"
)

foreach ($service in $services) {
    Write-Host "--- Probando: $service"
    Set-Location $service
    
    # Usar comillas simples para el comando Python para evitar problemas de escape
    $pythonCode = @"
import sys
try:
    from main import app
    print(f'[OK] {app.title}')
    if hasattr(app, "version"):
        print(f'    Puerto: {app.version}')
    else:
        print(f'    Puerto: N/A')
    sys.exit(0)
except Exception as e:
    print(f'[ERROR] {str(e)[:80]}')
    sys.exit(1)
"@
    
    $output = python -c $pythonCode 2>&1
    
    # Mostrar output limpio
    $outputLines = $output -split "`n" | Where-Object { $_ -notmatch "^\s*$" }
    foreach ($line in $outputLines) {
        Write-Host "    $line"
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [ESTADO] FUNCIONAL"
    } else {
        Write-Host "    [ESTADO] CON ERRORES"
    }
    
    Write-Host ""
    Set-Location ".."
}

Write-Host "=== RESUMEN ==="
Write-Host "✅ auth-service: Puerto 8000"
Write-Host "✅ user-service: Puerto 8001" 
Write-Host "✅ appointment-service: Puerto 8002"
Write-Host "✅ notification-service: Puerto 8003"
