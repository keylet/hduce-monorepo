"""
Función para enviar notificaciones al Notification Service - Versión simplificada
"""
import httpx
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

async def send_appointment_notification(
    appointment_data: Dict[str, Any],
    notification_type: str = "confirmation"
) -> bool:
    """
    Envía notificación al Notification Service
    
    Args:
        appointment_data: Diccionario con datos de la cita
        notification_type: Tipo de notificación
    
    Returns:
        bool: True si se envió correctamente, False si hubo error
    """
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Construir la URL del Notification Service
            base_url = "http://notification-service:8003"
            
            # Usar el endpoint de recordatorios (ya existe)
            url = f"{base_url}/api/v1/notifications/appointment/reminder"
            
            # Preparar parámetros
            params = {
                "patient_id": appointment_data.get("patient_id", ""),
                "patient_email": "test@example.com",  # Email por defecto para pruebas
                "patient_phone": "+1234567890",  # Teléfono por defecto para pruebas
                "doctor_name": appointment_data.get("doctor_name", "Doctor"),
                "appointment_date": appointment_data.get("appointment_date", "")
            }
            
            response = await client.post(url, params=params)
            response.raise_for_status()
            
            logger.info(f"✅ Notificación enviada para cita {appointment_data.get('appointment_id')}")
            return True
            
    except httpx.HTTPError as e:
        logger.error(f"❌ Error HTTP al enviar notificación: {e}")
        return False
    except Exception as e:
        logger.error(f"❌ Error inesperado: {e}")
        return False
