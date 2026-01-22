#!/usr/bin/env python3
"""
Prueba directa de RabbitMQ desde appointment-service
"""
import os
import json
from datetime import datetime

# Configuración
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
RABBITMQ_PASS = os.getenv("RABBITMQ_PASSWORD", "guest")

print("=== PRUEBA DIRECTA RABBITMQ ===")
print(f"Host: {RABBITMQ_HOST}:{RABBITMQ_PORT}")
print(f"User: {RABBITMQ_USER}")

try:
    # Intentar importar shared library
    try:
        from hduce_shared.rabbitmq.config import RabbitMQConfig
        from hduce_shared.rabbitmq.publisher import RabbitMQPublisher
        
        print("✅ Shared library importado")
        
        # Crear configuración
        config = RabbitMQConfig(
            host=RABBITMQ_HOST,
            port=RABBITMQ_PORT,
            username=RABBITMQ_USER,
            password=RABBITMQ_PASS,
            virtual_host="/",
            exchange="appointments",
            queue="appointment_notifications",
            routing_key="notification.created"
        )
        
        # Crear publisher
        publisher = RabbitMQPublisher(config=config)
        print("✅ RabbitMQPublisher creado")
        
        # Conectar
        publisher.connect()
        print("✅ Conectado a RabbitMQ")
        
        # Crear mensaje de prueba
        test_data = {
            "id": 999,
            "patient_id": 1,
            "patient_email": "test@example.com",
            "patient_name": "Test User",
            "doctor_id": 1,
            "appointment_date": "2024-03-06",
            "appointment_time": "14:30:00",
            "status": "scheduled",
            "created_at": datetime.now().isoformat()
        }
        
        # Publicar
        success = publisher.publish_appointment_created(test_data)
        print(f"✅ Publicación exitosa: {success}")
        
        publisher.close()
        
    except ImportError as e:
        print(f"❌ Error importando shared library: {e}")
        print("Probando con pika directo...")
        
        import pika
        
        # Conexión directa con pika
        credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
        parameters = pika.ConnectionParameters(
            host=RABBITMQ_HOST,
            port=RABBITMQ_PORT,
            credentials=credentials
        )
        
        connection = pika.BlockingConnection(parameters)
        channel = connection.channel()
        
        # Declarar exchange
        channel.exchange_declare(
            exchange='appointments',
            exchange_type='direct',
            durable=True
        )
        
        # Declarar queue
        channel.queue_declare(
            queue='appointment_notifications',
            durable=True
        )
        
        # Bind
        channel.queue_bind(
            exchange='appointments',
            queue='appointment_notifications',
            routing_key='notification.created'
        )
        
        # Crear mensaje
        message = {
            "event_type": "APPOINTMENT_CREATED",
            "timestamp": datetime.now().isoformat(),
            "data": {
                "id": 999,
                "patient_email": "test@example.com",
                "doctor_id": 1,
                "appointment_date": "2024-03-06"
            }
        }
        
        # Publicar
        channel.basic_publish(
            exchange='appointments',
            routing_key='notification.created',
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=2  # Persistente
            )
        )
        
        print("✅ Mensaje publicado directamente con pika")
        connection.close()
        
except Exception as e:
    print(f"❌ Error en prueba directa: {e}")
    import traceback
    traceback.print_exc()
