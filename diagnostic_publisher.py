"""
Script para diagnosticar qué está publicando el publisher
"""
import pika
import json

print("=" * 60)
print("🔍 DIAGNÓSTICO DE RABBITMQ PUBLISHER")
print("=" * 60)

try:
    # Conectar a RabbitMQ
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(
            host='rabbitmq',
            port=5672,
            credentials=pika.PlainCredentials('admin', 'admin123')
        )
    )
    channel = connection.channel()
    
    print("✅ Conectado a RabbitMQ")
    
    # 1. Verificar exchange
    print("\n1. Verificando exchange 'appointment_events'...")
    try:
        channel.exchange_declare(
            exchange='appointment_events',
            exchange_type='direct',
            durable=True,
            passive=True  # Solo verificar, no crear
        )
        print("   ✅ Exchange 'appointment_events' existe")
    except Exception as e:
        print(f"   ❌ Exchange 'appointment_events' NO existe: {e}")
    
    # 2. Verificar bindings
    print("\n2. Verificando bindings...")
    try:
        # Crear una queue temporal para ver bindings
        result = channel.queue_declare(queue='', exclusive=True)
        temp_queue = result.method.queue
        
        # Intentar binding con diferentes routing keys
        routing_keys = ['created', 'appointment.created', 'appointment_created', 'default']
        
        for routing_key in routing_keys:
            try:
                channel.queue_bind(
                    exchange='appointment_events',
                    queue=temp_queue,
                    routing_key=routing_key
                )
                print(f"   ✅ Binding válido para routing_key: '{routing_key}'")
                channel.queue_unbind(
                    exchange='appointment_events',
                    queue=temp_queue,
                    routing_key=routing_key
                )
            except:
                print(f"   ❌ No hay binding para routing_key: '{routing_key}'")
    
    except Exception as e:
        print(f"   ⚠️ Error verificando bindings: {e}")
    
    # 3. Verificar si hay mensajes en alguna queue
    print("\n3. Verificando queues existentes...")
    try:
        queues = channel.queue_declare(queue='notification_queue', passive=True)
        print(f"   Queue 'notification_queue': {queues.method.message_count} mensajes")
    except:
        print("   ❌ Queue 'notification_queue' no existe o no accesible")
    
    connection.close()
    print("\n" + "=" * 60)
    print("🔍 DIAGNÓSTICO COMPLETADO")
    print("=" * 60)
    
except Exception as e:
    print(f"❌ Error en diagnóstico: {e}")
