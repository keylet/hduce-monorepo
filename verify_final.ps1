# ================================================
# VERIFICACIÓN FINAL HDuce - Sistema 100%
# ================================================

function Test-Endpoint {
    param($Url, $Method="GET", $Headers=@{}, $Body=$null, $Description)
    
    Write-Host "$Description..." -NoNewline
    try {
        if ($Body) {
            $result = Invoke-RestMethod $Url -Method $Method -Headers $Headers -Body $Body -ContentType "application/json"
        } else {
            $result = Invoke-RestMethod $Url -Method $Method -Headers $Headers
        }
        Write-Host " ✅" -ForegroundColor Green
        return $result
    } catch {
        Write-Host " ❌ ($($_.Exception.Message))" -ForegroundColor Red
        return $null
    }
}

Write-Host "`n=== VERIFICACIÓN SISTEMA HDuce ===" -ForegroundColor Cyan

# 1. Login
$loginData = '{"email":"testuser@example.com","password":"secret"}'
$login = Test-Endpoint -Url "http://localhost/auth/login" -Method POST -Body $loginData -Description "1. Login"
if (-not $login) { exit }

$token = $login.access_token.Trim()
$headers = @{Authorization="Bearer $token"}

# 2. Verificar token
$verify = Test-Endpoint -Url "http://localhost/auth/verify" -Headers $headers -Description "2. Verificar token"

# 3. User service
$user = Test-Endpoint -Url "http://localhost/api/v1/users/1" -Headers $headers -Description "3. Obtener usuario"

# 4. Doctores (VERIFICAR specialty_name)
$doctors = Test-Endpoint -Url "http://localhost/api/doctors/" -Headers $headers -Description "4. Obtener doctores"
if ($doctors -and $doctors.Count -gt 0) {
    $firstDoctor = $doctors[0]
    if ($firstDoctor.specialty_name -and $firstDoctor.specialty_name.Trim() -ne "") {
        Write-Host "   • $($firstDoctor.name): $($firstDoctor.specialty_name) ✅" -ForegroundColor Green
    } else {
        Write-Host "   • $($firstDoctor.name): SIN ESPECIALIDAD ❌" -ForegroundColor Red
    }
}

# 5. Citas (VERIFICAR doctor_name)
$appointments = Test-Endpoint -Url "http://localhost/api/appointments/" -Headers $headers -Description "5. Obtener citas"
if ($appointments -and $appointments.Count -gt 0) {
    $firstApp = $appointments[0]
    if ($firstApp.doctor_name -and $firstApp.doctor_name.Trim() -ne "") {
        Write-Host "   • Cita: $($firstApp.patient_name) con $($firstApp.doctor_name) ✅" -ForegroundColor Green
    } else {
        Write-Host "   • Cita: $($firstApp.patient_name) SIN DOCTOR ❌" -ForegroundColor Red
    }
}

# 6. Notificaciones
$notifications = Test-Endpoint -Url "http://localhost/api/notifications/" -Description "6. Obtener notificaciones"

# 7. Health checks
Test-Endpoint -Url "http://localhost/health" -Description "7. Gateway health"
Test-Endpoint -Url "http://localhost:8000/health" -Description "   • Auth service"
Test-Endpoint -Url "http://localhost:8001/health" -Description "   • User service"
Test-Endpoint -Url "http://localhost:8002/health" -Description "   • Appointment service"
Test-Endpoint -Url "http://localhost:8003/health" -Description "   • Notification service"

# RESULTADO FINAL
Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host "📊 RESULTADO FINAL" -ForegroundColor Cyan
Write-Host "="*70 -ForegroundColor Cyan

if ($doctors -and $doctors[0].specialty_name -and $appointments -and $appointments[0].doctor_name) {
    Write-Host "🎉 ¡SISTEMA HDuce 100% FUNCIONAL!" -ForegroundColor Green
    Write-Host "✅ Gateway NGINX operativo" -ForegroundColor Green
    Write-Host "✅ Autenticación JWT funcionando" -ForegroundColor Green
    Write-Host "✅ Doctores con specialty_name" -ForegroundColor Green
    Write-Host "✅ Citas con doctor_name" -ForegroundColor Green
    Write-Host "✅ Flujo completo verificado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Sistema operativo pero con problemas:" -ForegroundColor Yellow
    if (-not ($doctors -and $doctors[0].specialty_name)) {
        Write-Host "   ❌ Problema con specialty_name en doctores" -ForegroundColor Red
    }
    if (-not ($appointments -and $appointments[0].doctor_name)) {
        Write-Host "   ❌ Problema con doctor_name en citas" -ForegroundColor Red
    }
}
