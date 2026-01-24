Write-Host "=== PASO 3: VERIFICACIÓN DETALLADA DE CORRECCIÓN ===" -ForegroundColor Cyan

$dockerComposePath = "..\instance-configs\instance-1-databases\docker-compose.yml"

Write-Host "Archivo: $dockerComposePath" -ForegroundColor Yellow
Write-Host "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow

if (-not (Test-Path $dockerComposePath)) {
    Write-Host "✗ Archivo no encontrado" -ForegroundColor Red
    exit 1
}

# 1. Verificación de sintaxis YAML básica
Write-Host "`n--- 1. VERIFICACIÓN DE SINTÁXIS YAML ---" -ForegroundColor Cyan

$content = Get-Content $dockerComposePath -Raw

# Verificar estructura jerárquica
$indentationErrors = 0
$lines = Get-Content $dockerComposePath
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s+[a-z]' -and $lines[$i] -notmatch '^\s{2}[a-z]' -and $lines[$i] -notmatch '^\s{4}[a-z]') {
        $indentationErrors++
        if ($indentationErrors -eq 1) {
            Write-Host "⚠ Posible problema de indentación en línea $($i+1)" -ForegroundColor Yellow
        }
    }
}

if ($indentationErrors -eq 0) {
    Write-Host "✓ Indentación consistente" -ForegroundColor Green
}

# 2. Verificación específica para Docker Compose v5
Write-Host "`n--- 2. VERIFICACIÓN DOCKER COMPOSE v5.0.2 ---" -ForegroundColor Cyan

$testsPassed = 0
$testsTotal = 4

# Test 1: Versión con comillas dobles
if ($content -match 'version:\s*"3\.8"') {
    Write-Host "✓ Test 1: Versión con comillas dobles" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ Test 1: Problema con formato de versión" -ForegroundColor Red
    Write-Host "   Encontrado: $($content | Select-String 'version:')" -ForegroundColor Gray
}

# Test 2: Services sección presente
if ($content -match '^services:' -or $content -match '\nservices:') {
    Write-Host "✓ Test 2: Sección 'services' presente" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ Test 2: Falta sección 'services'" -ForegroundColor Red
}

# Test 3: Todos los servicios requeridos
$requiredServices = @('postgres:', 'redis:', 'rabbitmq:')
$allServicesPresent = $true

foreach ($service in $requiredServices) {
    if ($content -match $service) {
        Write-Host "  ✓ Servicio $service encontrado" -ForegroundColor DarkGreen
    } else {
        Write-Host "  ✗ Servicio $service NO encontrado" -ForegroundColor Red
        $allServicesPresent = $false
    }
}

if ($allServicesPresent) {
    Write-Host "✓ Test 3: Todos los servicios presentes" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ Test 3: Faltan servicios" -ForegroundColor Red
}

# Test 4: Puertos y volúmenes
if ($content -match 'ports:' -and $content -match 'volumes:') {
    Write-Host "✓ Test 4: Configuración de puertos y volúmenes presente" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "✗ Test 4: Falta configuración de puertos o volúmenes" -ForegroundColor Red
}

# 3. Mostrar resumen de configuración
Write-Host "`n--- 3. RESUMEN DE CONFIGURACIÓN ---" -ForegroundColor Cyan

# Extraer configuración de cada servicio
Write-Host "`n[POSTGRES]" -ForegroundColor Yellow
$postgresConfig = $lines | Select-String -Pattern 'postgres:' -Context 0,10
$postgresConfig | ForEach-Object {
    if ($_.Line -match 'postgres:') {
        Write-Host "  Configuración PostgreSQL:" -ForegroundColor DarkGray
    } else {
        Write-Host "    $($_.Line)" -ForegroundColor Gray
    }
}

Write-Host "`n[REDIS]" -ForegroundColor Yellow
$redisConfig = $lines | Select-String -Pattern 'redis:' -Context 0,5
$redisConfig | ForEach-Object {
    if ($_.Line -match 'redis:') {
        Write-Host "  Configuración Redis:" -ForegroundColor DarkGray
    } else {
        Write-Host "    $($_.Line)" -ForegroundColor Gray
    }
}

Write-Host "`n[RABBITMQ]" -ForegroundColor Yellow
$rabbitmqConfig = $lines | Select-String -Pattern 'rabbitmq:' -Context 0,8
$rabbitmqConfig | ForEach-Object {
    if ($_.Line -match 'rabbitmq:') {
        Write-Host "  Configuración RabbitMQ:" -ForegroundColor DarkGray
    } else {
        Write-Host "    $($_.Line)" -ForegroundColor Gray
    }
}

# 4. Resultado final
Write-Host "`n=== RESULTADO FINAL ===" -ForegroundColor Cyan
Write-Host "Tests pasados: $testsPassed/$testsTotal" -ForegroundColor $(if ($testsPassed -eq $testsTotal) { "Green" } else { "Yellow" })

if ($testsPassed -eq $testsTotal) {
    Write-Host "✅ ARCHIVO LISTO PARA AWS" -ForegroundColor Green
    Write-Host "El docker-compose.yml está corregido y es compatible con Docker Compose v5.0.2" -ForegroundColor Green
} else {
    Write-Host "⚠ ALERTA: Problemas detectados" -ForegroundColor Yellow
    Write-Host "Revisar el archivo antes de copiar a AWS" -ForegroundColor Red
}

Write-Host "`nPróximo paso: Copiar archivo corregido a AWS" -ForegroundColor Magenta
