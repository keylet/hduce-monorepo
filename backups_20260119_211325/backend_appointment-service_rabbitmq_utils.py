"""
Wrapper para RabbitMQ que utiliza el shared library hduce_shared.rabbitmq.publisher
Mantiene compatibilidad con el código existente en routes.py
"""

import json
import os
from typing import Dict, Any

try:
    from hduce_shared.rabbitmq.publisher import RabbitMQPublisher
    SHARED_LIB_AVAILABLE = True
except ImportError:
    SHARED_LIB_AVAILABLE = False
    print("⚠️  Advertencia: hduce_shared.rabbitmq.publisher no disponible, usando fallback simple")

# Configuración de RabbitMQ desde variables de entorno
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASS = os.getenv("RABBITMQ_PASSWORD", "guest")

# Exchange y queues definidos en el sistema
APPOINTMENT_EXCHANGE = "appointments"
APPOINTMENT_QUEUE = "appointment_notifications"
NOTIFICATION_ROUTING_KEY = "notification.created"

class RabbitMQUtils:
    """Clase utilitaria para publicar mensajes en RabbitMQ"""
    
    _publisher = None
    
    @classmethod
    def get_publisher(cls):
        """Obtener instancia singleton del publisher"""
        if cls._publisher is None:
            if SHARED_LIB_AVAILABLE:
                cls._publisher = RabbitMQPublisher(
                    host=RABBITMQ_HOST,
                    port=RABBITMQ_PORT,
                    username=RABBITMQ_USER,
                    password=RABBITMQ_PASS
                )
            else:
                cls._publisher = SimpleRabbitMQPublisher(
                    host=RABBITMQ_HOST,
                    port=RABBITMQ_PORT,
                    username=RABBITMQ_USER,
                    password=RABBITMQ_PASS
                )
        return cls._publisher
    
    @classmethod
    def publish_appointment_created(cls, appointment_data: Dict[str, Any]) -> bool:
        """
        Publica evento de creación de cita
        
        Args:
            appointment_data: Datos de la cita creada
            
        Returns:
            bool: True si se publicó exitosamente
        """
        try:
            publisher = cls.get_publisher()
            
            # Configurar el mensaje
            message = {
                "event_type": "appointment.created",
                "data": appointment_data,
                "timestamp": appointment_data.get("created_at")
            }
            
            # Publicar al exchange de citas
            success = publisher.publish(
                exchange=APPOINTMENT_EXCHANGE,
                routing_key=NOTIFICATION_ROUTING_KEY,
                message=json.dumps(message)
            )
            
            if success:
                print(f"✅ Evento appointment.created publicado: {appointment_data.get('id')}")
            else:
                print(f"❌ Error al publicar evento appointment.created")
                
            return success
            
        except Exception as e:
            print(f"❌ Error en publish_appointment_created: {str(e)}")
            return False
    
    @classmethod
    def publish_appointment_updated(cls, appointment_data: Dict[str, Any]) -> bool:
        """
        Publica evento de actualización de cita
        """
        try:
            publisher = cls.get_publisher()
            
            message = {
                "event_type": "appointment.updated",
                "data": appointment_data,
                "timestamp": appointment_data.get("updated_at")
            }
            
            success = publisher.publish(
                exchange=APPOINTMENT_EXCHANGE,
                routing_key=NOTIFICATION_ROUTING_KEY,
                message=json.dumps(message)
            )
            
            return success
            
        except Exception as e:
            print(f"❌ Error en publish_appointment_updated: {str(e)}")
            return False
    
    @classmethod
    def close_connection(cls):
        """Cierra la conexión RabbitMQ"""
        if cls._publisher and hasattr(cls._publisher, 'close_connection'):
            cls._publisher.close_connection()


class SimpleRabbitMQPublisher:
    """
    Fallback simple si el shared library no está disponible
    """
    
    def __init__(self, host="rabbitmq", port=5672, username="guest", password="guest"):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.connection = None
        self.channel = None
    
    def publish(self, exchange, routing_key, message):
        """Publica un mensaje simple"""
        try:
            import pika
            
            # Crear conexión
            credentials = pika.PlainCredentials(self.username, self.password)
            parameters = pika.ConnectionParameters(
                host=self.host,
                port=self.port,
                credentials=credentials,
                connection_attempts=3,
                retry_delay=5
            )
            
            connection = pika.BlockingConnection(parameters)
            channel = connection.channel()
            
            # Asegurar que el exchange existe
            channel.exchange_declare(
                exchange=exchange,
                exchange_type='direct',
                durable=True
            )
            
            # Publicar mensaje
            channel.basic_publish(
                exchange=exchange,
                routing_key=routing_key,
                body=message,
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Hacer mensaje persistente
                )
            )
            
            print(f"📤 Publicado en {exchange}/{routing_key}: {message[:100]}...")
            connection.close()
            return True
            
        except Exception as e:
            print(f"❌ Error en SimpleRabbitMQPublisher.publish: {str(e)}")
            return False
    
    def close_connection(self):
        """Cierra conexión (no hace nada en esta implementación simple)"""
        pass


# Funciones de conveniencia para mantener compatibilidad con el código existente
def publish_to_rabbitmq(event_data: Dict[str, Any], event_type: str = None) -> bool:
    """
    Función de conveniencia para mantener compatibilidad con imports existentes
    
    Args:
        event_data: Datos del evento
        event_type: Tipo de evento (si es None, se intenta inferir)
        
    Returns:
        bool: True si se publicó exitosamente
    """
    if event_type is None:
        # Intentar inferir el tipo de evento
        if "id" in event_data and "status" in event_data:
            event_type = "appointment.updated"
        else:
            event_type = "appointment.created"
    
    if event_type == "appointment.created":
        return RabbitMQUtils.publish_appointment_created(event_data)
    elif event_type == "appointment.updated":
        return RabbitMQUtils.publish_appointment_updated(event_data)
    else:
        # Publicación genérica
        try:
            publisher = RabbitMQUtils.get_publisher()
            message = {
                "event_type": event_type,
                "data": event_data
            }
            return publisher.publish(
                exchange="events",
                routing_key=event_type.replace(".", "_"),
                message=json.dumps(message)
            )
        except Exception as e:
            print(f"❌ Error en publish_to_rabbitmq: {str(e)}")
            return False

# Función específica para mantener compatibilidad exacta con routes.py línea 8
def publish_appointment_created(appointment_data: Dict[str, Any]) -> bool:
    """Alias para publish_to_rabbitmq con tipo appointment.created"""
    return publish_to_rabbitmq(appointment_data, "appointment.created")
