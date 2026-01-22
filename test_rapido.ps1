# Test rápido del sistema HDuce
Write-Host "=== TEST RÁPIDO HDuce ===" -ForegroundColor Cyan

# 1. Gateway health
Write-Host "1. Gateway health..." -NoNewline
try {
    $health = Invoke-RestMethod "http://localhost/health" -TimeoutSec 3
    Write-Host " ✅ ($health)" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
    exit
}

# 2. Login
Write-Host "2. Login..." -NoNewline
$loginData = '{"email":"testuser@example.com","password":"secret"}'
try {
    $login = Invoke-RestMethod "http://localhost/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $login.access_token.Trim()
    Write-Host " ✅" -ForegroundColor Green
} catch {
    Write-Host " ❌" -ForegroundColor Red
    exit
}

# 3. Doctores
Write-Host "3. Obtener doctores..." -NoNewline
$headers = @{Authorization="Bearer $token"}
try {
    $doctors = Invoke-RestMethod "http://localhost/api/doctors/" -Headers $headers
    Write-Host " ✅ ($($doctors.Count) doctores)" -ForegroundColor Green
    
    if ($doctors.Count -gt 0) {
        $firstDoctor = $doctors[0]
        Write-Host "   • $($firstDoctor.name)" -ForegroundColor Gray
        
        # Verificar campos
        $campos = $firstDoctor.PSObject.Properties.Name -join ", "
        Write-Host "   • Campos: $campos" -ForegroundColor Gray
        
        if ($firstDoctor.PSObject.Properties['specialty_name']) {
            if ($firstDoctor.specialty_name -and $firstDoctor.specialty_name.Trim() -ne "") {
                Write-Host "   ✅ specialty_name: $($firstDoctor.specialty_name)" -ForegroundColor Green
            } else {
                Write-Host "   ❌ specialty_name vacío" -ForegroundColor Red
            }
        } else {
            Write-Host "   ❌ NO tiene specialty_name" -ForegroundColor Red
        }
    }
} catch {
    Write-Host " ❌ ($($_.Exception.Message))" -ForegroundColor Red
}

# 4. Citas
Write-Host "4. Obtener citas..." -NoNewline
try {
    $appointments = Invoke-RestMethod "http://localhost/api/appointments/" -Headers $headers
    Write-Host " ✅ ($($appointments.Count) citas)" -ForegroundColor Green
    
    if ($appointments.Count -gt 0) {
        $firstApp = $appointments[0]
        
        if ($firstApp.PSObject.Properties['doctor_name']) {
            if ($firstApp.doctor_name -and $firstApp.doctor_name.Trim() -ne "") {
                Write-Host "   ✅ doctor_name: $($firstApp.doctor_name)" -ForegroundColor Green
            } else {
                Write-Host "   ❌ doctor_name vacío" -ForegroundColor Red
            }
        } else {
            Write-Host "   ❌ NO tiene doctor_name" -ForegroundColor Red
        }
    }
} catch {
    Write-Host " ❌ ($($_.Exception.Message))" -ForegroundColor Red
}

Write-Host "`n=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "🎯 Sistema HDuce con NGINX restaurado" -ForegroundColor Green
