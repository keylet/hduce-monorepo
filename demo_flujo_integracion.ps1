Write-Host "=== 🏥 DEMOSTRACIÓN VISUAL: FLUJO APPOINTMENT → NOTIFICATION ===" -ForegroundColor Cyan
Write-Host "`nEste script muestra cómo se integrarían los servicios:" -ForegroundColor White

# 1. Primero, mostrar el estado actual
Write-Host "`n1. 📊 ESTADO ACTUAL DE LOS SERVICIOS:" -ForegroundColor Yellow
docker-compose ps | Select-String -Pattern "appointment|notification" -Context 0,1

# 2. Crear una cita (sin integración aún)
Write-Host "`n2. 📅 CREANDO UNA NUEVA CITA:" -ForegroundColor Yellow

# Obtener un paciente y doctor
$patients = Invoke-RestMethod -Uri "http://localhost:8001/users" -Method Get -ErrorAction SilentlyContinue
$doctors = Invoke-RestMethod -Uri "http://localhost:8002/doctors" -Method Get -ErrorAction SilentlyContinue

if ($patients -and $doctors) {
    $patient = $patients[0]
    $doctor = $doctors[0]
    
    Write-Host "   Paciente: $($patient.name)" -ForegroundColor Gray
    Write-Host "   Doctor: ID $($doctor.id)" -ForegroundColor Gray
    
    # Crear la cita
    $appointmentData = @{
        patient_id = $patient.id
        doctor_id = $doctor.id
        appointment_date = "2026-01-20T10:00:00"
        reason = "Demostración de integración"
        status = "scheduled"
    } | ConvertTo-Json
    
    try {
        $appointment = Invoke-RestMethod -Uri "http://localhost:8002/appointments" -Method Post -Body $appointmentData -ContentType "application/json"
        Write-Host "   ✅ Cita creada: ID $($appointment.id)" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ No se pudo crear cita (Appointment Service puede estar fallando)" -ForegroundColor Red
        Write-Host "   Continuando con demostración conceptual..." -ForegroundColor Gray
    }
}

# 3. Mostrar cómo sería la llamada a Notification Service
Write-Host "`n3. 📧 CÓMO SE LLAMARÍA AL NOTIFICATION SERVICE:" -ForegroundColor Yellow

$codigoEjemplo = @'
# CÓDIGO EN APPOINTMENT SERVICE (notification_integration.py)

async def send_appointment_confirmation(appointment_data):
    """Después de crear una cita, enviar notificación"""
    
    # Preparar datos
    notification_payload = {
        "user_id": appointment_data["patient_id"],
        "notification_type": "email",
        "subject": "Confirmación de cita",
        "message": f"Cita confirmada para {appointment_data['date']}",
        "recipient_email": appointment_data["patient_email"]
    }
    
    # Llamar HTTP a Notification Service
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://notification-service:8003/api/v1/notifications/email",
            params=notification_payload
        )
        
    if response.status_code == 200:
        print("✅ Notificación enviada exitosamente")
    else:
        print("❌ Error enviando notificación")
