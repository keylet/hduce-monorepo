"""
RabbitMQ Utils Simplificado - VERSIÓN CORREGIDA
Con manejo robusto de reconexiones y conexión por demanda
"""
import json
import os
import pika
import logging
import time
from typing import Dict, Any
from datetime import datetime
from functools import wraps

# Configuración
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASS = os.getenv("RABBITMQ_PASSWORD", "guest")

EXCHANGE = "appointments"
QUEUE = "appointment_notifications"
ROUTING_KEY = "notification.created"

# Configurar logging
logger = logging.getLogger(__name__)

def retry_on_failure(max_retries=3, delay=1):
    """Decorador para reintentar operaciones en RabbitMQ"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except (pika.exceptions.AMQPConnectionError, 
                        pika.exceptions.StreamLostError,
                        ConnectionResetError) as e:
                    last_exception = e
                    if attempt < max_retries - 1:
                        logger.warning(f"Reintentando {func.__name__} ({attempt + 1}/{max_retries}): {e}")
                        time.sleep(delay * (attempt + 1))  # Backoff exponencial
                    else:
                        logger.error(f"Fallo después de {max_retries} intentos: {e}")
            raise last_exception
        return wrapper
    return decorator

class SimpleRabbitMQPublisher:
    """Publisher simple con conexión POR DEMANDA y manejo de errores"""

    _instance = None
    _connection = None
    _channel = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(SimpleRabbitMQPublisher, cls).__new__(cls)
        return cls._instance
    
    @retry_on_failure(max_retries=3, delay=2)
    def _ensure_connection(self):
        """Asegurar que hay una conexión activa (conexión por demanda)"""
        if self._connection is None or self._connection.is_closed:
            try:
                credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
                parameters = pika.ConnectionParameters(
                    host=RABBITMQ_HOST,
                    port=RABBITMQ_PORT,
                    credentials=credentials,
                    heartbeat=600,
                    blocked_connection_timeout=300,
                    connection_attempts=3,
                    retry_delay=2
                )
                
                self._connection = pika.BlockingConnection(parameters)
                self._channel = self._connection.channel()
                
                # Declarar exchange
                self._channel.exchange_declare(
                    exchange=EXCHANGE,
                    exchange_type="direct",
                    durable=True
                )
                
                # Declarar queue
                self._channel.queue_declare(
                    queue=QUEUE,
                    durable=True
                )
                
                # Bind queue to exchange
                self._channel.queue_bind(
                    exchange=EXCHANGE,
                    queue=QUEUE,
                    routing_key=ROUTING_KEY
                )
                
                logger.info(f"✅ Conectado a RabbitMQ en {RABBITMQ_HOST}:{RABBITMQ_PORT}")
                
            except Exception as e:
                logger.error(f"❌ Error conectando a RabbitMQ: {e}")
                self._cleanup()
                raise
    
    def _cleanup(self):
        """Limpiar conexiones cerradas"""
        if self._channel and self._channel.is_open:
            try:
                self._channel.close()
            except:
                pass
        self._channel = None
        
        if self._connection and self._connection.is_open:
            try:
                self._connection.close()
            except:
                pass
        self._connection = None
    
    @retry_on_failure(max_retries=3, delay=1)
    def publish(self, message: Dict[str, Any]):
        """Publicar mensaje en RabbitMQ (conexión por demanda)"""
        try:
            # Asegurar conexión
            self._ensure_connection()
            
            # Publicar mensaje
            self._channel.basic_publish(
                exchange=EXCHANGE,
                routing_key=ROUTING_KEY,
                body=json.dumps(message, ensure_ascii=False, default=str),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Persistente
                    content_type='application/json',
                    timestamp=int(time.time())
                )
            )
            
            logger.info(f"✅ Evento publicado: {message.get('event_type', 'UNKNOWN')} - Cita {message.get('data', {}).get('appointment_id', 'N/A')}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error publicando evento: {e}")
            self._cleanup()  # Limpiar conexión fallida
            raise
    
    def __del__(self):
        """Destructor - cerrar conexiones"""
        self._cleanup()

# Instancia singleton global
_publisher_instance = SimpleRabbitMQPublisher()

def publish_appointment_created(appointment_data: Dict[str, Any]):
    """
    Publicar evento de cita creada - FUNCIÓN PRINCIPAL
    Mantiene compatibilidad con el código existente
    """
    try:
        event_message = {
            "event_type": "APPOINTMENT_CREATED",
            "timestamp": datetime.utcnow().isoformat(),
            "data": appointment_data,
            "metadata": {
                "service": "appointment",
                "version": "1.0"
            }
        }
        
        return _publisher_instance.publish(event_message)
        
    except Exception as e:
        logger.error(f"❌ Error en publish_appointment_created: {e}")
        return False

# Alias para compatibilidad
publish_appointment_event = publish_appointment_created
