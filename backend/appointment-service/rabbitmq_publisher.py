"""
Cliente RabbitMQ para Appointment Service - Versión mejorada
"""
import pika
import json
import logging
from typing import Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)

class AppointmentEventPublisher:
    """Publica eventos de citas a RabbitMQ"""
    
    def __init__(self):
        self.connection_params = pika.ConnectionParameters(
            host='rabbitmq',
            port=5672,
            credentials=pika.PlainCredentials('admin', 'admin123'),
            heartbeat=600
        )
    
    def _publish_event(self, event_type: str, data: Dict[str, Any]) -> bool:
        """Método interno para publicar eventos"""
        try:
            connection = pika.BlockingConnection(self.connection_params)
            channel = connection.channel()
            
            # Declarar exchange
            channel.exchange_declare(
                exchange='appointment_events',
                exchange_type='direct',
                durable=True
            )
            
            # Crear mensaje completo
            message = {
                'event_type': f'appointment.{event_type}',
                'data': data,
                'timestamp': datetime.now().isoformat(),
                'service': 'appointment-service',
                'version': '1.0'
            }
            
            # Publicar
            channel.basic_publish(
                exchange='appointment_events',
                routing_key=event_type,
                body=json.dumps(message, default=str),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Persistente
                    content_type='application/json',
                    content_encoding='utf-8'
                )
            )
            
            connection.close()
            logger.info(f"📤 Evento publicado: appointment.{event_type}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error publicando evento {event_type}: {e}")
            return False
    
    def publish_appointment_created(self, appointment_data: Dict[str, Any]) -> bool:
        """Publicar evento de cita creada"""
        event_data = {
            'appointment_id': appointment_data.get('appointment_id'),
            'patient_id': appointment_data.get('patient_id'),
            'doctor_id': appointment_data.get('doctor_id'),
            'doctor_name': appointment_data.get('doctor_name'),
            'appointment_date': appointment_data.get('appointment_date'),
            'reason': appointment_data.get('reason'),
            'action': 'CREATE'
        }
        return self._publish_event('created', event_data)
    
    def publish_appointment_updated(self, appointment_data: Dict[str, Any], changes: Dict[str, Any]) -> bool:
        """Publicar evento de cita actualizada"""
        event_data = {
            'appointment_id': appointment_data.get('appointment_id'),
            'changes': changes,
            'action': 'UPDATE'
        }
        return self._publish_event('updated', event_data)
    
    def publish_appointment_cancelled(self, appointment_data: Dict[str, Any], reason: str = None) -> bool:
        """Publicar evento de cita cancelada"""
        event_data = {
            'appointment_id': appointment_data.get('appointment_id'),
            'reason': reason,
            'action': 'CANCEL'
        }
        return self._publish_event('cancelled', event_data)
    
    def publish_appointment_reminder(self, appointment_data: Dict[str, Any]) -> bool:
        """Publicar evento de recordatorio"""
        event_data = {
            'appointment_id': appointment_data.get('appointment_id'),
            'patient_id': appointment_data.get('patient_id'),
            'appointment_date': appointment_data.get('appointment_date'),
            'action': 'REMINDER'
        }
        return self._publish_event('reminder', event_data)

# Instancia global
event_publisher = AppointmentEventPublisher()
