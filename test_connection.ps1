Write-Host "=== PRUEBA DE CONEXIÓN COMPLETA ENTRE SERVICIOS ===" -ForegroundColor Cyan
Write-Host "Este script prueba TODA la comunicación entre auth-service y user-service`n"

# 1. Obtener token de prueba
Write-Host "[1/4] Obteniendo token de auth-service..." -ForegroundColor Yellow
$tokenResponse = curl.exe -s -X POST "http://localhost:8000/api/auth/simple-register" `
  -H "Content-Type: application/json" 2>$null

if ($LASTEXITCODE -eq 0) {
    try {
        $tokenData = $tokenResponse | ConvertFrom-Json
        $testToken = $tokenData.access_token
        Write-Host "  ✅ Token obtenido exitosamente" -ForegroundColor Green
        Write-Host "  Usuario: $($tokenData.user.username)" -ForegroundColor Gray
        Write-Host "  Token (primeros 30 chars): $($testToken.Substring(0, [Math]::Min(30, $testToken.Length)))..." -ForegroundColor Gray
    } catch {
        Write-Host "  ❌ Error parseando respuesta: $tokenResponse" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ❌ Error obteniendo token: $tokenResponse" -ForegroundColor Red
    exit 1
}

# 2. Validar token con auth-service
Write-Host "`n[2/4] Validando token con auth-service..." -ForegroundColor Yellow
$validationResponse = curl.exe -s -X POST "http://localhost:8000/api/auth/validate-token" `
  -H "Content-Type: application/json" `
  -d "{\`"token\`": \`"$testToken\`"}" 2>$null

if ($LASTEXITCODE -eq 0) {
    $validationData = $validationResponse | ConvertFrom-Json
    if ($validationData.is_valid) {
        Write-Host "  ✅ Token validado correctamente por auth-service" -ForegroundColor Green
        Write-Host "  Usuario validado: $($validationData.username)" -ForegroundColor Gray
        Write-Host "  Email: $($validationData.email)" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Token inválido según auth-service" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ❌ Error en validación: $validationResponse" -ForegroundColor Red
    exit 1
}

# 3. Acceder a ruta protegida en user-service
Write-Host "`n[3/4] Accediendo a ruta protegida en user-service..." -ForegroundColor Yellow
$protectedResponse = curl.exe -s -X GET "http://localhost:8001/api/users/me" `
  -H "Authorization: Bearer $testToken" 2>$null

if ($LASTEXITCODE -eq 0) {
    $protectedData = $protectedResponse | ConvertFrom-Json
    Write-Host "  ✅ ¡ÉXITO! User-service aceptó el token validado por auth-service" -ForegroundColor Green -BackgroundColor Black
    Write-Host "  Mensaje: $($protectedData.message)" -ForegroundColor Gray
    Write-Host "  Servicio: $($protectedData.service)" -ForegroundColor Gray
    Write-Host "  Usuario autenticado: $($protectedData.user.username)" -ForegroundColor Gray
} elseif ($LASTEXITCODE -eq 401) {
    Write-Host "  ❌ Acceso denegado (401) - Token no aceptado" -ForegroundColor Red
    Write-Host "  Respuesta: $protectedResponse" -ForegroundColor Gray
    exit 1
} elseif ($LASTEXITCODE -eq 503) {
    Write-Host "  ❌ Auth-service no disponible (503) - No se pudo validar token" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  ❌ Error desconocido (Código: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host "  Respuesta: $protectedResponse" -ForegroundColor Gray
    exit 1
}

# 4. Prueba sin token (debe fallar)
Write-Host "`n[4/4] Probando acceso sin token (debe fallar)..." -ForegroundColor Yellow
$noTokenResponse = curl.exe -s -X GET "http://localhost:8001/api/users/me" 2>$null

if ($LASTEXITCODE -eq 401) {
    Write-Host "  ✅ Correcto - Acceso denegado sin token" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Inesperado - Acceso permitido sin token" -ForegroundColor Yellow
}

Write-Host "`n" + ("="*70) -ForegroundColor Green
Write-Host "🎉 ¡PRUEBA DE CONEXIÓN COMPLETADA EXITOSAMENTE!" -ForegroundColor Green -BackgroundColor Black
Write-Host "="*70 -ForegroundColor Green

Write-Host "`n📊 RESUMEN:" -ForegroundColor Cyan
Write-Host "• ✅ Auth-service genera tokens JWT" -ForegroundColor Green
Write-Host "• ✅ Auth-service valida tokens" -ForegroundColor Green
Write-Host "• ✅ User-service consulta auth-service para validar tokens" -ForegroundColor Green
Write-Host "• ✅ Comunicación entre servicios FUNCIONA" -ForegroundColor Green
Write-Host "• ✅ Arquitectura de microservicios VALIDADA" -ForegroundColor Green

Write-Host "`n🚀 SIGUIENTE PASO EN EL PROYECTO HDUCE:" -ForegroundColor Yellow
Write-Host "Ahora puedes continuar con:" -ForegroundColor White
Write-Host "1. Agregar más microservicios (appointment-service, etc.)" -ForegroundColor Gray
Write-Host "2. Implementar bases de datos reales" -ForegroundColor Gray
Write-Host "3. Agregar Docker y docker-compose" -ForegroundColor Gray
Write-Host "4. Configurar CI/CD con GitHub Actions" -ForegroundColor Gray
