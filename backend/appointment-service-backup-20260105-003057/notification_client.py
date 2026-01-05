"""
Cliente HTTP para comunicación con Notification Service
"""
import httpx
import logging
from typing import Optional, Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)

class NotificationClient:
    def __init__(self, base_url: str = "http://notification-service:8003"):
        self.base_url = base_url
    
    async def send_appointment_created(
        self,
        appointment_id: str,
        patient_name: str,
        patient_email: str,
        patient_phone: Optional[str],
        doctor_name: str,
        appointment_date: datetime,
        reason: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Envía notificación cuando se crea una cita"""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                url = f"{self.base_url}/api/v1/notifications/send"
                
                formatted_date = appointment_date.strftime("%d/%m/%Y a las %H:%M")
                
                data = {
                    "type": "APPOINTMENT_CREATED",
                    "subject": "Confirmación de cita médica",
                    "message": f"""Hola {patient_name},

Tu cita con el Dr. {doctor_name} ha sido confirmada para el {formatted_date}.

Motivo: {reason or 'Consulta médica'}

Recibirás un recordatorio 24h antes.

Saludos,
Hospital HDUCE""",
                    "metadata": {
                        "appointment_id": appointment_id,
                        "doctor_name": doctor_name,
                        "appointment_date": appointment_date.isoformat()
                    }
                }
                
                if patient_phone:
                    data["channels"] = ["email", "sms"]
                else:
                    data["channels"] = ["email"]
                
                response = await client.post(url, json=data)
                response.raise_for_status()
                
                logger.info(f"✅ Notificación de creación enviada para cita {appointment_id}")
                return response.json()
                
        except Exception as e:
            logger.error(f"❌ Error enviando notificación: {e}")
            return None
    
    async def send_appointment_reminder(
        self,
        patient_id: str,
        patient_email: str,
        patient_phone: Optional[str],
        doctor_name: str,
        appointment_date: datetime
    ) -> Optional[Dict[str, Any]]:
        """Envía recordatorio de cita (usa el endpoint existente)"""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                url = f"{self.base_url}/api/v1/notifications/appointment/reminder"
                
                params = {
                    "patient_id": patient_id,
                    "patient_email": patient_email,
                    "patient_phone": patient_phone or "",
                    "doctor_name": doctor_name,
                    "appointment_date": appointment_date.isoformat()
                }
                
                response = await client.post(url, params=params)
                response.raise_for_status()
                
                logger.info(f"✅ Recordatorio enviado para paciente {patient_id}")
                return response.json()
                
        except Exception as e:
            logger.error(f"❌ Error enviando recordatorio: {e}")
            return None

# Instancia global para usar
notification_client = NotificationClient()
