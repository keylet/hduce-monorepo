# TEST FINAL CORREGIDO HDuce
Write-Host "=== TEST HDuce CORREGIDO ===" -ForegroundColor Cyan

# 1. Gateway
Write-Host "1. Gateway NGINX..." -NoNewline
try {
    $gateway = Invoke-WebRequest "http://localhost/" -TimeoutSec 3
    Write-Host " ✅" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
}

# 2. Auth directo
Write-Host "2. Auth-service directo..." -NoNewline
try {
    $authDirect = Invoke-RestMethod "http://localhost:8000/health"
    Write-Host " ✅ ($($authDirect.status))" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
}

# 3. Login VIA GATEWAY
Write-Host "3. Login via gateway..." -NoNewline
$loginData = '{"email":"testuser@example.com","password":"secret"}'
try {
    $login = Invoke-RestMethod "http://localhost/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $login.access_token.Trim()
    Write-Host " ✅" -ForegroundColor Green
    
    # Guardar token
    $token | Out-File "token.txt" -Encoding UTF8
    Write-Host "   Token guardado en token.txt" -ForegroundColor Gray
    
} catch {
    Write-Host " ❌ ($($_.Exception.Message))" -ForegroundColor Red
    
    # Intentar login directo
    Write-Host "   Intentando login directo a auth-service..." -ForegroundColor Yellow
    try {
        $loginDirect = Invoke-RestMethod "http://localhost:8000/login" -Method POST -Body $loginData -ContentType "application/json"
        Write-Host "   ✅ Login directo funciona" -ForegroundColor Green
        Write-Host "   Problema es con NGINX routing" -ForegroundColor Yellow
    } catch {
        Write-Host "   ❌ Login directo también falla" -ForegroundColor Red
    }
    exit
}

# 4. Verificar token
Write-Host "4. Verificar token..." -NoNewline
$headers = @{Authorization="Bearer $token"}
try {
    $verify = Invoke-RestMethod "http://localhost/auth/verify" -Headers $headers
    Write-Host " ✅ ($($verify.user.email))" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
}

# 5. Doctores
Write-Host "5. Obtener doctores..." -NoNewline
try {
    $doctors = Invoke-RestMethod "http://localhost/api/doctors/" -Headers $headers
    Write-Host " ✅ ($($doctors.Count) doctores)" -ForegroundColor Green
    
    if ($doctors.Count -gt 0) {
        $first = $doctors[0]
        $campos = $first.PSObject.Properties.Name -join ", "
        Write-Host "   • Campos disponibles: $campos" -ForegroundColor Gray
        
        if ($first.specialty_name) {
            Write-Host "   • specialty_name: $($first.specialty_name)" -ForegroundColor $(if($first.specialty_name.Trim()){"Green"}else{"Red"})
        }
    }
} catch {
    Write-Host " ❌" -ForegroundColor Red
}

# 6. Citas
Write-Host "6. Obtener citas..." -NoNewline
try {
    $appointments = Invoke-RestMethod "http://localhost/api/appointments/" -Headers $headers
    Write-Host " ✅ ($($appointments.Count) citas)" -ForegroundColor Green
    
    if ($appointments.Count -gt 0) {
        $first = $appointments[0]
        if ($first.doctor_name) {
            Write-Host "   • doctor_name: $($first.doctor_name)" -ForegroundColor $(if($first.doctor_name.Trim()){"Green"}else{"Red"})
        }
    }
} catch {
    Write-Host " ❌" -ForegroundColor Red
}

Write-Host "`n=== RESULTADO ===" -ForegroundColor Cyan
Write-Host "🎯 HDuce System Status:" -ForegroundColor Green
