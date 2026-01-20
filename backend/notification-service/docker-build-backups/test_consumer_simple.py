#!/usr/bin/env python3
"""
Consumer de prueba simple para RabbitMQ - VERSION COMPLETA
"""
import pika
import json

print("=== CONSUMER SIMPLE DE PRUEBA - VERSION COMPLETA ===")

try:
    # Configuración
    connection_params = pika.ConnectionParameters(
        host='rabbitmq',
        port=5672,
        credentials=pika.PlainCredentials('guest', 'guest'),
        heartbeat=600
    )
    
    connection = pika.BlockingConnection(connection_params)
    channel = connection.channel()
    
    print("✅ Conectado a RabbitMQ")
    
    # Declarar exchange y queue
    channel.exchange_declare(
        exchange='appointments',
        exchange_type='direct',
        durable=True
    )
    
    # Declarar queue y obtener info
    result = channel.queue_declare(
        queue='appointment_notifications',
        durable=True
    )
    
    channel.queue_bind(
        exchange='appointments',
        queue='appointment_notifications',
        routing_key='notification.created'
    )
    
    print(f"✅ Exchange: appointments")
    print(f"✅ Queue: appointment_notifications") 
    print(f"✅ Routing key: notification.created")
    print(f"✅ Mensajes en queue: {result.method.message_count}")
    
    # Callback
    def callback(ch, method, properties, body):
        try:
            print(f"\n📥 📥 📥 MENSAJE RECIBIDO! 📥 📥 📥")
            print(f"Raw body: {body}")
            
            # Intentar parsear JSON
            try:
                message = json.loads(body.decode('utf-8'))
                print(f"✅ JSON parseado correctamente")
                print(f"Tipo de evento: {message.get('event_type', 'N/A')}")
                
                # Mostrar estructura completa
                print(f"Estructura completa:")
                for key, value in message.items():
                    print(f"  {key}: {value}")
                    
            except json.JSONDecodeError:
                print(f"⚠️  No es JSON válido, mostrando texto plano:")
                print(f"{body.decode('utf-8')}")
            
            # Confirmar mensaje
            ch.basic_ack(delivery_tag=method.delivery_tag)
            print(f"✅ Mensaje confirmado (ack)")
            
        except Exception as e:
            print(f"❌ Error en callback: {e}")
            import traceback
            traceback.print_exc()
    
    # Configurar consumer
    channel.basic_qos(prefetch_count=1)
    
    # Usar basic_consume (no consume)
    consumer_tag = channel.basic_consume(
        queue='appointment_notifications',
        on_message_callback=callback,
        auto_ack=False
    )
    
    print(f"\n✅ Consumer registrado con tag: {consumer_tag}")
    print("🎯 ESCUCHANDO MENSAJES... (Presiona Ctrl+C para salir)")
    
    # Iniciar consumo
    channel.start_consuming()
    
except Exception as e:
    print(f"❌ Error en consumer: {e}")
    import traceback
    traceback.print_exc()
