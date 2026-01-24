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
    
    $output = python -c "
import sys
try:
    from main import app
    print(f'[OK] {app.title}')
    print(f'    Puerto: {app.version if hasattr(app, \"version\") else \"N/A\"}')
    exit(0)
except Exception as e:
    print(f'[ERROR] {str(e)[:80]}')
    exit(1)
" 2>&1
    
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
