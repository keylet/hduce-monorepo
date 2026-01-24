"""RabbitMQ service for appointment notifications"""
from typing import Dict, Any
from hduce_shared.rabbitmq import RabbitMQPublisher, RabbitMQConfig

class AppointmentNotificationService:
    """Service to publish appointment events to RabbitMQ"""
    
    def __init__(self):
        self.publisher = RabbitMQPublisher()
    
    def publish_appointment_created(self, appointment_data: Dict[str, Any]) -> bool:
        """Publish appointment created event"""
        try:
            # Prepare data for notification
            event_data = {
                "appointment_id": appointment_data.get("id"),
                "patient_id": appointment_data.get("patient_id"),
                "doctor_id": appointment_data.get("doctor_id"),
                "appointment_date": appointment_data.get("appointment_date"),
                "reason": appointment_data.get("reason"),
                "status": appointment_data.get("status", "scheduled")
            }
            
            # Publish event
            success = self.publisher.publish_appointment_created(event_data)
            
            if success:
                print(f"📤 Appointment {event_data['appointment_id']} published to RabbitMQ")
            else:
                print(f"❌ Failed to publish appointment {event_data['appointment_id']}")
            
            return success
            
        except Exception as e:
            print(f"❌ Error publishing appointment: {e}")
            return False

# Singleton instance
notification_service = AppointmentNotificationService()
