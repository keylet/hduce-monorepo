"""RabbitMQ Consumer for HDuce"""
import json
import pika
import threading
from typing import Callable, Dict, Any
from .config import RabbitMQConfig

class RabbitMQConsumer:
    """RabbitMQ consumer for appointment events"""
    
    def __init__(self, config: RabbitMQConfig = None):
        self.config = config or RabbitMQConfig.from_env()
        self.connection = None
        self.channel = None
        self.consuming = False
    
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
            
            # Declare exchange and queue (same as publisher)
            self.channel.exchange_declare(
                exchange=self.config.appointment_exchange,
                exchange_type="direct",
                durable=True
            )
            
            self.channel.queue_declare(
                queue=self.config.appointment_queue,
                durable=True
            )
            
            self.channel.queue_bind(
                exchange=self.config.appointment_exchange,
                queue=self.config.appointment_queue,
                routing_key=self.config.appointment_routing_key
            )
            
            # Quality of Service - process one message at a time
            self.channel.basic_qos(prefetch_count=1)
            
            print(f"✅ Consumer connected to RabbitMQ at {self.config.host}:{self.config.port}")
            
        except Exception as e:
            print(f"❌ Failed to connect consumer to RabbitMQ: {e}")
            raise
    
    def start_consuming(self, callback: Callable[[Dict[str, Any]], None]) -> None:
        """Start consuming messages with callback"""
        def on_message(ch, method, properties, body):
            try:
                message = json.loads(body.decode('utf-8'))
                print(f"📥 Message received: {message.get('event_type', 'UNKNOWN')}")
                
                # Process message
                callback(message)
                
                # Acknowledge message
                ch.basic_ack(delivery_tag=method.delivery_tag)
                print(f"✅ Message processed successfully")
                
            except json.JSONDecodeError as e:
                print(f"❌ Failed to decode JSON: {e}")
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            except Exception as e:
                print(f"❌ Error processing message: {e}")
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
        
        try:
            if not self.connection or self.connection.is_closed:
                self.connect()
            
            self.channel.basic_consume(
                queue=self.config.appointment_queue,
                on_message_callback=on_message
            )
            
            self.consuming = True
            print("🎯 Consumer started. Waiting for messages...")
            self.channel.start_consuming()
            
        except Exception as e:
            print(f"❌ Error in consumer: {e}")
            self.consuming = False
            raise
    
    def start_in_background(self, callback: Callable[[Dict[str, Any]], None]) -> threading.Thread:
        """Start consumer in background thread"""
        def consumer_loop():
            while True:
                try:
                    self.start_consuming(callback)
                except Exception as e:
                    print(f"❌ Consumer stopped, restarting in 5 seconds: {e}")
                    import time
                    time.sleep(5)
        
        thread = threading.Thread(target=consumer_loop, daemon=True)
        thread.start()
        print("✅ Consumer started in background thread")
        return thread
    
    def close(self) -> None:
        """Close connection"""
        self.consuming = False
        if self.connection and not self.connection.is_closed:
            self.connection.close()
            print("✅ Consumer connection closed")
