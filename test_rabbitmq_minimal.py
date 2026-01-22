#!/usr/bin/env python3
"""
Prueba mínima de RabbitMQ - Diagnóstico
"""
import os
import json
from datetime import datetime

print("=== PRUEBA MÍNIMA RABBITMQ ===")

# Configuración básica
RABBITMQ_HOST = "rabbitmq"
RABBITMQ_PORT = 5672
RABBITMQ_USER = "guest"
RABBITMQ_PASS = "guest"

try:
    # Intentar importar shared library primero
    print("1. Intentando importar shared library...")
    try:
        from hduce_shared.rabbitmq.config import RabbitMQConfig
        from hduce_shared.rabbitmq.publisher import RabbitMQPublisher
        print("   ✅ Shared library importado")
        
        # Mostrar atributos de RabbitMQConfig
        print("   Atributos de RabbitMQConfig:")
        import inspect
        config_attrs = [attr for attr in dir(RabbitMQConfig) if not attr.startswith('_')]
        print(f"   {config_attrs}")
        
        # Crear configuración
        print("2. Creando configuración...")
        config = RabbitMQConfig(
            host=RABBITMQ_HOST,
            port=RABBITMQ_PORT,
            username=RABBITMQ_USER,
            password=RABBITMQ_PASS,
            virtual_host="/",
            exchange="appointments",
            queue="appointment_notifications",
            routing_key="notification.created",
            heartbeat=600,
            blocked_connection_timeout=300
        )
        
        print(f"   ✅ Config creada")
        print(f"   exchange: {config.exchange}")
        print(f"   queue: {config.queue}")
        print(f"   routing_key: {config.routing_key}")
        
        # Crear publisher
        print("3. Creando publisher...")
        publisher = RabbitMQPublisher(config=config)
        print("   ✅ Publisher creado")
        
        # Conectar
        print("4. Conectando...")
        publisher.connect()
        print("   ✅ Conectado")
        
        # Datos de prueba
        test_data = {
            "id": 999,
            "patient_email": "test@example.com",
            "doctor_id": 1,
            "appointment_date": "2024-03-06"
        }
        
        # Publicar
        print("5. Publicando...")
        success = publisher.publish_appointment_created(test_data)
        print(f"   ✅ Publicación: {success}")
        
        # Cerrar
        publisher.close()
        print("   ✅ Conexión cerrada")
        
    except Exception as e:
        print(f"   ❌ Error con shared library: {e}")
        import traceback
        traceback.print_exc()
        
        # Intentar con pika directo
        print("\n6. Intentando con pika directo...")
        import pika
        
        credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
        parameters = pika.ConnectionParameters(
            host=RABBITMQ_HOST,
            port=RABBITMQ_PORT,
            credentials=credentials
        )
        
        connection = pika.BlockingConnection(parameters)
        channel = connection.channel()
        
        print("   ✅ Conectado con pika")
        
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
        
        # Mensaje
        message = {
            "event_type": "TEST_DIRECT",
            "timestamp": datetime.now().isoformat(),
            "data": {"test": "direct pika"}
        }
        
        channel.basic_publish(
            exchange='appointments',
            routing_key='notification.created',
            body=json.dumps(message),
            properties=pika.BasicProperties(delivery_mode=2)
        )
        
        print("   ✅ Mensaje publicado con pika")
        connection.close()
        
except Exception as e:
    print(f"❌ Error general: {e}")
    import traceback
    traceback.print_exc()
