# HDuce Frontend Monitor Script
# Ubicación: C:\Users\raich\Desktop\hduce-monorepo\monitor-frontend.ps1

Write-Host "=== HDuce Frontend Monitor ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow

# Configuración
$frontendUrl = "http://localhost:4200"
$frontendHealthy = $false
$responseTime = 0
$metricsFile = "C:\Users\raich\Desktop\hduce-monorepo\frontend-metrics.prom"
$logFile = "C:\Users\raich\Desktop\hduce-monorepo\frontend-monitor.log"

# 1. Verificar frontend
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-WebRequest -Uri $frontendUrl -Method GET -TimeoutSec 5 -ErrorAction Stop
    $stopwatch.Stop()
    
    $responseTime = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 2)
    
    if ($response.StatusCode -eq 200) {
        $frontendHealthy = $true
        Write-Host "✅ Frontend RESPONDE" -ForegroundColor Green
        Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "   Tiempo: ${responseTime}ms" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Frontend NO RESPONDE" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# 2. Crear métricas Prometheus
$currentTime = [int][double]::Parse((Get-Date -UFormat %s))
$prometheusMetrics = @"
# HELP frontend_up Frontend availability (1=up, 0=down)
# TYPE frontend_up gauge
frontend_up{service="frontend"} $(if($frontendHealthy) {1} else {0})

# HELP frontend_response_time_ms Frontend response time in milliseconds
# TYPE frontend_response_time_ms gauge
frontend_response_time_ms{service="frontend"} $responseTime

# HELP frontend_check_time Unix timestamp of last check
# TYPE frontend_check_time gauge
frontend_check_time{service="frontend"} $currentTime
"@

# 3. Guardar métricas en archivo
try {
    $prometheusMetrics | Out-File -FilePath $metricsFile -Encoding UTF8 -Force
    Write-Host "📊 Métricas guardadas en: $metricsFile" -ForegroundColor Cyan
    
} catch {
    Write-Host "⚠️  Error guardando métricas: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. Guardar log histórico
$logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Status: $(if($frontendHealthy) {'UP'} else {'DOWN'}) | Response: ${responseTime}ms"
$logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
Write-Host "📝 Log histórico: $logFile" -ForegroundColor Cyan

# 5. Mostrar resumen
Write-Host "`n--- RESUMEN ---" -ForegroundColor Yellow
Write-Host "Frontend: $(if($frontendHealthy) {'✅ UP'} else {'❌ DOWN'})" -ForegroundColor $(if($frontendHealthy) {'Green'} else {'Red'})
Write-Host "Response Time: ${responseTime}ms" -ForegroundColor Cyan
Write-Host "Último check: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan

Write-Host "`n=== Monitor finalizado ===" -ForegroundColor Cyan
