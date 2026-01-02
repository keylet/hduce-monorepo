import httpx
import logging
from typing import Optional
from datetime import datetime

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class NotificationClient:
    def __init__(self, base_url: str = "http://notification-service:8003"):
        self.base_url = base_url
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def send_appointment_confirmation(
        self,
        patient_id: str,
        patient_email: Optional[str],
        patient_phone: Optional[str],
        doctor_name: str,
        appointment_date: str,
        appointment_id: int
    ):
        """Enviar confirmación de cita al Notification Service"""
        try:
            # Primero, enviar email si hay dirección
            if patient_email:
                email_url = f"{self.base_url}/api/v1/notifications/email"
                email_params = {
                    "user_id": patient_id,
                    "subject": f"Confirmación de cita con {doctor_name}",
                    "message": f"""
                    Su cita médica ha sido confirmada:
                    
                    Doctor: {doctor_name}
                    Fecha y hora: {appointment_date}
                    ID de cita: {appointment_id}
                    
                    Por favor, llegue 15 minutos antes.
                    
                    Saludos,
                    Hospital UCE - HDUCE
                    """,
                    "recipient_email": patient_email
                }
                
                response = await self.client.post(email_url, params=email_params)
                if response.status_code == 200:
                    logger.info(f"Appointment confirmation email sent to {patient_email}")
                else:
                    logger.error(f"Failed to send email: {response.text}")
            
            # Luego, enviar SMS si hay teléfono
            if patient_phone:
                sms_url = f"{self.base_url}/api/v1/notifications/sms"
                sms_params = {
                    "user_id": patient_id,
                    "message": f"Cita confirmada con {doctor_name} para {appointment_date}. ID: {appointment_id}",
                    "recipient_phone": patient_phone
                }
                
                response = await self.client.post(sms_url, params=sms_params)
                if response.status_code == 200:
                    logger.info(f"Appointment confirmation SMS sent to {patient_phone}")
                else:
                    logger.error(f"Failed to send SMS: {response.text}")
            
            return True
            
        except Exception as e:
            logger.error(f"Error sending appointment confirmation: {str(e)}")
            return False
    
    async def send_appointment_reminder(
        self,
        patient_id: str,
        patient_email: Optional[str],
        patient_phone: Optional[str],
        doctor_name: str,
        appointment_date: str,
        appointment_id: int,
        hours_before: int = 24
    ):
        """Enviar recordatorio de cita"""
        try:
            reminder_url = f"{self.base_url}/api/v1/notifications/appointment/reminder"
            params = {
                "patient_id": patient_id,
                "doctor_name": doctor_name,
                "appointment_date": appointment_date,
                "hours_before": hours_before
            }
            
            if patient_email:
                params["patient_email"] = patient_email
            if patient_phone:
                params["patient_phone"] = patient_phone
            
            response = await self.client.post(reminder_url, params=params)
            
            if response.status_code == 200:
                logger.info(f"Appointment reminder sent for appointment {appointment_id}")
                return True
            else:
                logger.error(f"Failed to send reminder: {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Error sending appointment reminder: {str(e)}")
            return False
    
    async def close(self):
        """Cerrar el cliente HTTP"""
        await self.client.aclose()

# Cliente global (singleton)
notification_client = NotificationClient()

async def send_appointment_notification(
    appointment_data: dict,
    notification_type: str = "confirmation"
):
    """Función helper para enviar notificaciones de citas"""
    try:
        if notification_type == "confirmation":
            success = await notification_client.send_appointment_confirmation(
                patient_id=appointment_data.get("patient_id"),
                patient_email=appointment_data.get("patient_email"),
                patient_phone=appointment_data.get("patient_phone"),
                doctor_name=appointment_data.get("doctor_name", "Doctor"),
                appointment_date=appointment_data.get("appointment_date"),
                appointment_id=appointment_data.get("appointment_id")
            )
            return success
        elif notification_type == "reminder":
            success = await notification_client.send_appointment_reminder(
                patient_id=appointment_data.get("patient_id"),
                patient_email=appointment_data.get("patient_email"),
                patient_phone=appointment_data.get("patient_phone"),
                doctor_name=appointment_data.get("doctor_name", "Doctor"),
                appointment_date=appointment_data.get("appointment_date"),
                appointment_id=appointment_data.get("appointment_id"),
                hours_before=24
            )
            return success
        else:
            logger.warning(f"Unknown notification type: {notification_type}")
            return False
            
    except Exception as e:
        logger.error(f"Error in send_appointment_notification: {str(e)}")
        return False
