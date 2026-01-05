#!/usr/bin/env python3
"""Test script for RabbitMQ connectivity"""
import pika
import json
from datetime import datetime

def test_rabbitmq_connection():
    """Test RabbitMQ connection"""
    try:
        credentials = pika.PlainCredentials('admin', 'admin123')
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host='localhost',
                port=5672,
                credentials=credentials
            )
        )
        
        channel = connection.channel()
        
        # Test exchange and queue
        channel.exchange_declare(
            exchange='appointments',
            exchange_type='direct',
            durable=True
        )
        
        channel.queue_declare(
            queue='appointment_notifications',
            durable=True
        )
        
        channel.queue_bind(
            exchange='appointments',
            queue='appointment_notifications',
            routing_key='appointment.created'
        )
        
        # Test message
        test_message = {
            "event_type": "TEST_MESSAGE",
            "timestamp": datetime.now().isoformat(),
            "data": {"test": "RabbitMQ is working!"},
            "metadata": {"test": True}
        }
        
        channel.basic_publish(
            exchange='appointments',
            routing_key='appointment.created',
            body=json.dumps(test_message),
            properties=pika.BasicProperties(
                delivery_mode=2,
                content_type='application/json'
            )
        )
        
        print("✅ RabbitMQ connection test SUCCESSFUL")
        print(f"📤 Message published: {test_message['event_type']}")
        
        # Try to consume
        def callback(ch, method, properties, body):
            msg = json.loads(body.decode())
            print(f"📥 Message consumed: {msg['event_type']}")
            ch.basic_ack(delivery_tag=method.delivery_tag)
            connection.close()
        
        channel.basic_consume(
            queue='appointment_notifications',
            on_message_callback=callback,
            auto_ack=False
        )
        
        print("⏳ Waiting for message (timeout 5 seconds)...")
        channel.start_consuming()
        
    except Exception as e:
        print(f"❌ RabbitMQ connection test FAILED: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_rabbitmq_connection()
