"""RabbitMQ Publisher for HDuce"""
import json
import pika
from typing import Any, Dict
from .config import RabbitMQConfig

class RabbitMQPublisher:
    """RabbitMQ publisher for appointment events"""
    
    def __init__(self, config: RabbitMQConfig = None):
        self.config = config or RabbitMQConfig.from_env()
        self.connection = None
        self.channel = None
    
    def connect(self) -> None:
        """Establish connection to RabbitMQ"""
        try:
            credentials = pika.PlainCredentials(
                self.config.username, 
                self.config.password
            )
            
            self.connection = pika.BlockingConnection(
                pika.ConnectionParameters(
                    host=self.config.host,
                    port=self.config.port,
                    credentials=credentials,
                    virtual_host=self.config.virtual_host,
                    heartbeat=self.config.heartbeat,
                    blocked_connection_timeout=self.config.blocked_connection_timeout
                )
            )
            
            self.channel = self.connection.channel()
            
            # Declare exchange (durable for persistence)
            self.channel.exchange_declare(
                exchange=self.config.appointment_exchange,
                exchange_type="direct",
                durable=True
            )
            
            # Declare queue (durable for persistence)
            self.channel.queue_declare(
                queue=self.config.appointment_queue,
                durable=True
            )
            
            # Bind queue to exchange
            self.channel.queue_bind(
                exchange=self.config.appointment_exchange,
                queue=self.config.appointment_queue,
                routing_key=self.config.appointment_routing_key
            )
            
            print(f"✅ Connected to RabbitMQ at {self.config.host}:{self.config.port}")
            
        except Exception as e:
            print(f"❌ Failed to connect to RabbitMQ: {e}")
            raise
    
    def publish_appointment_created(self, appointment_data: Dict[str, Any]) -> bool:
        """Publish appointment created event"""
        try:
            if not self.connection or self.connection.is_closed:
                self.connect()
            
            message = {
                "event_type": "APPOINTMENT_CREATED",
                "timestamp": datetime.now().isoformat(),
                "data": appointment_data,
                "metadata": {
                    "service": "appointment",
                    "version": "1.0"
                }
            }
            
            self.channel.basic_publish(
                exchange=self.config.appointment_exchange,
                routing_key=self.config.appointment_routing_key,
                body=json.dumps(message, ensure_ascii=False),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Make message persistent
                    content_type='application/json',
                    timestamp=int(datetime.now().timestamp())
                )
            )
            
            print(f"✅ Event published: APPOINTMENT_CREATED - Appointment {appointment_data.get('id', 'N/A')}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to publish event: {e}")
            return False
    
    def close(self) -> None:
        """Close connection"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
            print("✅ RabbitMQ connection closed")
    
    def __enter__(self):
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

# Import datetime at module level
from datetime import datetime
