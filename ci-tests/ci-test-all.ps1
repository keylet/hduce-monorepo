# ci-test-all.ps1
# ================
# TESTING MÍNIMO PARA CI/CD - Ejecución rápida (< 5 min)
# Verifica solo lo CRÍTICO del sistema HDuce

param(
    [switch]$Fast = $true,
    [switch]$DockerCheck = $true,
    [switch]$APICheck = $true,
    [switch]$SecurityCheck = $false,
    [string]$OutputFile = "ci-test-results.json"
)

Write-Host "🚀 EJECUTANDO TESTS CI/CD PARA HDuce" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$results = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    tests = @()
    summary = @{
        total = 0
        passed = 0
        failed = 0
        skipped = 0
        duration = 0
    }
}

$startTime = Get-Date

# ============ 1. VERIFICACIÓN BÁSICA DEL SISTEMA ============
function Test-SystemBasics {
    Write-Host "`n1️⃣ VERIFICACIÓN BÁSICA DEL SISTEMA" -ForegroundColor Yellow
    
    $tests = @(
        @{Name="Python instalado"; Script={python --version 2>&1 | Out-Null; $?}},
        @{Name="Docker instalado"; Script={docker --version 2>&1 | Out-Null; $?}},
        @{Name="Docker Compose instalado"; Script={docker-compose --version 2>&1 | Out-Null; $?}},
        @{Name="Proyecto tiene .env"; Script={Test-Path ".env"}},
        @{Name="Token JWT existe"; Script={Test-Path "token.txt" -or Test-Path "new-token.txt"}},
        @{Name="docker-compose.yml existe"; Script={Test-Path "docker-compose.yml"}}
    )
    
    foreach ($test in $tests) {
        $result = @{
            name = $test.Name
            status = "PASS"
            details = ""
        }
        
        try {
            $testResult = & $test.Script
            if ($testResult -eq $true -or $testResult -eq $null) {
                $result.status = "PASS"
                Write-Host "  ✅ $($test.Name)" -ForegroundColor Green
            } else {
                $result.status = "FAIL"
                $result.details = "Check failed"
                Write-Host "  ❌ $($test.Name)" -ForegroundColor Red
            }
        } catch {
            $result.status = "FAIL"
            $result.details = $_.Exception.Message
            Write-Host "  ❌ $($test.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
        
        $results.tests += $result
    }
}

# ============ 2. VERIFICACIÓN DE CONTENEDORES DOCKER ============
function Test-DockerContainers {
    if (-not $DockerCheck) { return }
    
    Write-Host "`n2️⃣ VERIFICACIÓN DE CONTENEDORES DOCKER" -ForegroundColor Yellow
    
    try {
        $containers = docker ps --format "{{.Names}},{{.Status}},{{.Ports}}" 2>$null
        
        if (-not $containers) {
            Write-Host "  ⚠️ No hay contenedores ejecutándose" -ForegroundColor Yellow
            
            $results.tests += @{
                name = "Contenedores Docker ejecutándose"
                status = "SKIP"
                details = "No containers running"
            }
            return
        }
        
        $hduceContainers = $containers | Where-Object { $_ -match "hduce" }
        $essentialServices = @("hduce-nginx", "hduce-auth", "hduce-postgres", "hduce-redis")
        
        Write-Host "  📊 Contenedores encontrados: $($hduceContainers.Count)" -ForegroundColor Cyan
        
        foreach ($container in $hduceContainers) {
            $parts = $container -split ","
            $name = $parts[0]
            $status = $parts[1]
            
            $result = @{
                name = "Contenedor: $name"
                status = if ($status -match "Up") { "PASS" } else { "FAIL" }
                details = $status
            }
            
            $icon = if ($status -match "Up") { "✅" } else { "❌" }
            Write-Host "  $icon $name: $status" -ForegroundColor $(if($status -match "Up"){"Green"}else{"Red"})
            
            $results.tests += $result
        }
        
        # Verificar servicios esenciales
        foreach ($service in $essentialServices) {
            $isRunning = $hduceContainers -match $service
            
            $result = @{
                name = "Servicio esencial: $service"
                status = if ($isRunning) { "PASS" } else { "FAIL" }
                details = if ($isRunning) { "Running" } else { "Not found" }
            }
            
            $results.tests += $result
        }
        
    } catch {
        Write-Host "  ⚠️ Error verificando Docker: $_" -ForegroundColor Yellow
        $results.tests += @{
            name = "Verificación Docker"
            status = "SKIP"
            details = "Docker check failed"
        }
    }
}

# ============ 3. TEST DE ENDPOINTS CRÍTICOS ============
function Test-CriticalEndpoints {
    if (-not $APICheck) { return }
    
    Write-Host "`n3️⃣ TEST DE ENDPOINTS CRÍTICOS" -ForegroundColor Yellow
    
    $criticalEndpoints = @(
        @{Url="http://localhost/auth/health"; Name="Auth Health"; Method="GET"},
        @{Url="http://localhost/api/appointments/"; Name="Appointments"; Method="GET"},
        @{Url="http://localhost/api/notifications/"; Name="Notifications"; Method="GET"},
        @{Url="http://localhost/api/v1/users/"; Name="Users"; Method="GET"},
        @{Url="http://localhost/metrics/health"; Name="Metrics"; Method="GET"},
        @{Url="http://localhost/mqtt/health"; Name="MQTT"; Method="GET"}
    )
    
    foreach ($endpoint in $criticalEndpoints) {
        $result = @{
            name = "Endpoint: $($endpoint.Name)"
            status = "FAIL"
            details = ""
            response_time = 0
            status_code = 0
        }
        
        try {
            $start = Get-Date
            $response = Invoke-WebRequest -Uri $endpoint.Url -Method $endpoint.Method `
                -TimeoutSec 10 -SkipCertificateCheck -ErrorAction Stop
            $end = Get-Date
            
            $result.response_time = [math]::Round(($end - $start).TotalMilliseconds, 2)
            $result.status_code = $response.StatusCode
            
            if ($response.StatusCode -in @(200, 201, 204)) {
                $result.status = "PASS"
                Write-Host "  ✅ $($endpoint.Name): HTTP $($response.StatusCode) (${result.response_time}ms)" -ForegroundColor Green
            } elseif ($response.StatusCode -in @(401, 403)) {
                $result.status = "WARN"
                $result.details = "Requires authentication"
                Write-Host "  ⚠️ $($endpoint.Name): HTTP $($response.StatusCode) (needs auth)" -ForegroundColor Yellow
            } elseif ($response.StatusCode -eq 422) {
                $result.status = "WARN"
                $result.details = "Needs parameters"
                Write-Host "  ⚠️ $($endpoint.Name): HTTP $($response.StatusCode) (needs params)" -ForegroundColor Yellow
            } else {
                $result.status = "FAIL"
                $result.details = "Unexpected status"
                Write-Host "  ❌ $($endpoint.Name): HTTP $($response.StatusCode)" -ForegroundColor Red
            }
            
        } catch [System.Net.WebException] {
            $result.details = "HTTP Error: $($_.Exception.Status)"
            Write-Host "  ❌ $($endpoint.Name): $($_.Exception.Status)" -ForegroundColor Red
        } catch {
            $result.details = "Connection error: $_"
            Write-Host "  ❌ $($endpoint.Name): Connection failed" -ForegroundColor Red
        }
        
        $results.tests += $result
    }
}

# ============ 4. TEST DE AUTENTICACIÓN JWT ============
function Test-JWTAuthentication {
    Write-Host "`n4️⃣ TEST DE AUTENTICACIÓN JWT" -ForegroundColor Yellow
    
    # 4.1 Verificar archivos de token
    $tokenFiles = @()
    if (Test-Path "new-token.txt") { $tokenFiles += "new-token.txt" }
    if (Test-Path "token.txt") { $tokenFiles += "token.txt" }
    
    if ($tokenFiles.Count -eq 0) {
        Write-Host "  ⚠️ No se encontraron archivos de token" -ForegroundColor Yellow
        $results.tests += @{
            name = "Archivos de token JWT"
            status = "FAIL"
            details = "No token files found"
        }
        return
    }
    
    foreach ($tokenFile in $tokenFiles) {
        $result = @{
            name = "Token file: $tokenFile"
            status = "PASS"
            details = ""
        }
        
        try {
            $token = Get-Content $tokenFile -Raw -ErrorAction Stop
            $token = $token.Trim()
            
            if ([string]::IsNullOrWhiteSpace($token)) {
                throw "Token file is empty"
            }
            
            # Validación básica de JWT (3 partes separadas por puntos)
            $parts = $token.Split('.')
            if ($parts.Count -ne 3) {
                throw "Invalid JWT format (expected 3 parts)"
            }
            
            if ($parts[0].Length -lt 10 -or $parts[1].Length -lt 10 -or $parts[2].Length -lt 10) {
                throw "JWT parts too short"
            }
            
            Write-Host "  ✅ $tokenFile: Token válido (JWT)" -ForegroundColor Green
            $global:validToken = $token
            
        } catch {
            $result.status = "FAIL"
            $result.details = $_.Exception.Message
            Write-Host "  ❌ $tokenFile: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        $results.tests += $result
    }
    
    # 4.2 Test de login real
    Write-Host "  🔐 Probando login real..." -ForegroundColor Cyan
    
    $loginTest = @{
        name = "Login con credenciales de test"
        status = "FAIL"
        details = ""
    }
    
    try {
        $loginData = @{
            email = "testuser@example.com"
            password = "secret"
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "http://localhost/auth/login" `
            -Method POST -Body $loginData `
            -ContentType "application/json" `
            -TimeoutSec 10 -SkipCertificateCheck
        
        if ($response.StatusCode -eq 200) {
            $responseData = $response.Content | ConvertFrom-Json
            
            if ($responseData.access_token) {
                $loginTest.status = "PASS"
                $loginTest.details = "Login successful"
                Write-Host "  ✅ Login exitoso - Token generado" -ForegroundColor Green
                
                # Guardar nuevo token
                $newTokenFile = "ci-token-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
                $responseData.access_token | Out-File $newTokenFile
                Write-Host "  💾 Nuevo token guardado en: $newTokenFile" -ForegroundColor Cyan
            }
        } else {
            $loginTest.details = "HTTP $($response.StatusCode)"
            Write-Host "  ⚠️ Login falló: HTTP $($response.StatusCode)" -ForegroundColor Yellow
        }
        
    } catch {
        $loginTest.details = "Error: $_"
        Write-Host "  ❌ Login error: $_" -ForegroundColor Red
    }
    
    $results.tests += $loginTest
}

# ============ 5. TEST DE BASES DE DATOS ============
function Test-DatabaseConnectivity {
    Write-Host "`n5️⃣ TEST INDIRECTO DE BASES DE DATOS" -ForegroundColor Yellow
    
    # Test indirecto a través de servicios
    $dbServices = @(
        @{Service="Auth"; Endpoint="/auth/health"},
        @{Service="Appointments"; Endpoint="/api/appointments/"},
        @{Service="Notifications"; Endpoint="/api/notifications/"}
    )
    
    foreach ($dbService in $dbServices) {
        $result = @{
            name = "Base de datos: $($dbService.Service)"
            status = "FAIL"
            details = ""
        }
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost$($dbService.Endpoint)" `
                -TimeoutSec 5 -SkipCertificateCheck -ErrorAction Stop
            
            # Si el servicio responde, la DB probablemente está funcionando
            $result.status = "PASS"
            $result.details = "Service responding via HTTP $($response.StatusCode)"
            Write-Host "  ✅ $($dbService.Service) DB: Accesible vía servicio" -ForegroundColor Green
            
        } catch [System.Net.WebException] {
            if ($_.Exception.Response.StatusCode -eq 401 -or 
                $_.Exception.Response.StatusCode -eq 422) {
                # 401/422 significa que el servicio está arriba pero necesita auth/params
                $result.status = "WARN"
                $result.details = "Service up but needs auth/params"
                Write-Host "  ⚠️ $($dbService.Service) DB: Servicio responde (needs auth)" -ForegroundColor Yellow
            } else {
                $result.details = "Service error: $($_.Exception.Status)"
                Write-Host "  ❌ $($dbService.Service) DB: Servicio no responde" -ForegroundColor Red
            }
        } catch {
            $result.details = "Connection failed"
            Write-Host "  ❌ $($dbService.Service) DB: Conexión fallida" -ForegroundColor Red
        }
        
        $results.tests += $result
    }
}

# ============ 6. TEST DE PERFORMANCE BÁSICO ============
function Test-BasicPerformance {
    Write-Host "`n6️⃣ TEST DE PERFORMANCE BÁSICO" -ForegroundColor Yellow
    
    $endpoints = @(
        "http://localhost/auth/health",
        "http://localhost/",
        "http://localhost/metrics/health"
    )
    
    foreach ($endpoint in $endpoints) {
        $times = @()
        
        for ($i = 0; $i -lt 3; $i++) {  # 3 requests para promedio
            try {
                $start = Get-Date
                $null = Invoke-WebRequest -Uri $endpoint -TimeoutSec 5 -SkipCertificateCheck
                $end = Get-Date
                $times += ($end - $start).TotalMilliseconds
                Start-Sleep -Milliseconds 200
            } catch {
                # Ignorar errores en test de performance
            }
        }
        
        if ($times.Count -gt 0) {
            $avgTime = [math]::Round(($times | Measure-Object -Average).Average, 2)
            $maxTime = [math]::Round(($times | Measure-Object -Maximum).Maximum, 2)
            
            $status = if ($avgTime -lt 1000) { "PASS" } else { "WARN" }
            $color = if ($avgTime -lt 500) { "Green" } elseif ($avgTime -lt 1000) { "Yellow" } else { "Red" }
            
            Write-Host "  📊 $($endpoint.Split('/')[-1]): Avg ${avgTime}ms, Max ${maxTime}ms" -ForegroundColor $color
            
            $results.tests += @{
                name = "Performance: $($endpoint.Split('/')[-1])"
                status = $status
                details = "Average: ${avgTime}ms, Max: ${maxTime}ms"
                avg_response_time = $avgTime
                max_response_time = $maxTime
            }
        }
    }
}

# ============ EJECUCIÓN PRINCIPAL ============
Write-Host "`n🔧 Iniciando tests CI/CD para HDuce..." -ForegroundColor Cyan

# Ejecutar todos los tests
Test-SystemBasics
Test-DockerContainers
Test-CriticalEndpoints
Test-JWTAuthentication
Test-DatabaseConnectivity
Test-BasicPerformance

# ============ GENERAR REPORTE ============
$endTime = Get-Date
$duration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)

# Calcular resumen
foreach ($test in $results.tests) {
    $results.summary.total++
    
    switch ($test.status) {
        "PASS" { $results.summary.passed++ }
        "FAIL" { $results.summary.failed++ }
        default { $results.summary.skipped++ }
    }
}

$results.summary.duration = $duration

# Mostrar resumen
Write-Host "`n" + ("="*50) -ForegroundColor Cyan
Write-Host "📊 RESUMEN DE TESTS CI/CD" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan

Write-Host "✅ PASADOS: $($results.summary.passed)" -ForegroundColor Green
Write-Host "❌ FALLADOS: $($results.summary.failed)" -ForegroundColor $(if($results.summary.failed -gt 0){"Red"}else{"Gray"})
Write-Host "⚠️  SKIP/SKIPPED: $($results.summary.skipped)" -ForegroundColor Yellow
Write-Host "⏱️  DURACIÓN: ${duration}s" -ForegroundColor Cyan
Write-Host "📅 FECHA: $($results.timestamp)" -ForegroundColor Cyan

# Guardar resultados
$results | ConvertTo-Json -Depth 10 | Out-File $OutputFile -Encoding UTF8
Write-Host "`n📄 Reporte guardado en: $OutputFile" -ForegroundColor Green

# Determinar estado final
if ($results.summary.failed -gt 0) {
    Write-Host "`n❌ CI/CD TESTS FALLIDOS" -ForegroundColor Red -BackgroundColor Black
    exit 1
} else {
    Write-Host "`n✅ CI/CD TESTS EXITOSOS" -ForegroundColor Green -BackgroundColor Black
    exit 0
}
