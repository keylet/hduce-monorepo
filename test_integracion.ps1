Write-Host "=== PRUEBA DE INTEGRACIÓN APPOINTMENT → NOTIFICATION ===" -ForegroundColor Cyan

# 1. Primero restaurar el Appointment Service original
Write-Host "`n1. Restaurando Appointment Service original..." -ForegroundColor Yellow
docker-compose stop appointment-service

# Copiar backup de vuelta
cd backend\appointment-service
Copy-Item routes_backup.py routes.py -Force
cd ../..

# 2. Reconstruir Appointment Service
Write-Host "`n2. Reconstruyendo Appointment Service..." -ForegroundColor Yellow
docker-compose up -d --build appointment-service

Start-Sleep -Seconds 10

# 3. Verificar que funciona
Write-Host "`n3. Verificando servicios..." -ForegroundColor Yellow
docker-compose ps | Select-String "appointment"

# 4. Crear script de demostración de integración
Write-Host "`n4. Creando demostración de integración..." -ForegroundColor Yellow

# Script Python que muestra cómo se integrarían
$demoScript = @'
import httpx
import asyncio

async def demo_appointment_to_notification():
    """Demostración de cómo Appointment Service llamaría a Notification Service"""
    
    print("=== DEMO: Integración Appointment → Notification ===")
    
    # Datos de ejemplo
    appointment_data = {
        "patient_id": "86d53850-7cfc-4939-b7c1-1974f2c56ba0",
        "patient_email": "john.smith@hospital.com",
        "doctor_name": "Dr. John Smith",
        "appointment_date": "2026-01-15 14:30:00",
        "appointment_id": 1001
    }
    
    # Llamar a Notification Service
    async with httpx.AsyncClient() as client:
        # Enviar email de confirmación
        email_url = "http://localhost:8003/api/v1/notifications/email"
        email_params = {
            "user_id": appointment_data["patient_id"],
            "subject": f"Confirmación de cita con {appointment_data['doctor_name']}",
            "message": f"Su cita ha sido confirmada para {appointment_data['appointment_date']}",
            "recipient_email": appointment_data["patient_email"]
        }
        
        print(f"Enviando email a {appointment_data['patient_email']}...")
        response = await client.post(email_url, params=email_params)
        
        if response.status_code == 200:
            print(f"✓ Email enviado exitosamente")
            print(f"  Respuesta: {response.json()}")
        else:
            print(f"✗ Error enviando email: {response.text}")
    
    print("`n=== FIN DEMOSTRACIÓN ===")

if __name__ == "__main__":
    asyncio.run(demo_appointment_to_notification())
