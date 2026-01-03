# Versión simple y directa que SÍ inicia el consumer
import pika
import json
import threading
import time
from datetime import datetime

print("=" * 60)
print("🚀 CONSUMER RABBITMQ - VERSIÓN SIMPLE DIRECTA")
print("=" * 60)

def simple_consumer():
    """Consumer simple que SÍ se ejecuta"""
    while True:
        try:
            print("Conectando a RabbitMQ...")
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(
                    host='rabbitmq',
                    port=5672,
                    credentials=pika.PlainCredentials('admin', 'admin123')
                )
            )
            channel = connection.channel()
            
            # Exchange
            channel.exchange_declare(
                exchange='appointment_events',
                exchange_type='direct',
                durable=True
            )
            
            # Queue
            channel.queue_declare(queue='notification_queue', durable=True)
            
            # Binding
            channel.queue_bind(
                exchange='appointment_events',
                queue='notification_queue',
                routing_key='created'
            )
            
            print("✅ Consumer listo. Esperando mensajes...")
            
            def callback(ch, method, properties, body):
                print("\n" + "🎉" * 30)
                print("🎉 ¡¡¡MENSAJE RABBITMQ RECIBIDO!!!")
                print(f"📨 Mensaje: {body.decode('utf-8')[:200]}...")
                print("🎉" * 30)
                
                # Guardar en archivo de log para verificar
                with open('/app/rabbitmq_messages.log', 'a') as f:
                    f.write(f"{datetime.now()}: {body.decode('utf-8')}\n")
                
                print("✅ Mensaje guardado en log")
            
            channel.basic_consume(
                queue='notification_queue',
                on_message_callback=callback,
                auto_ack=True
            )
            
            print("🚀 Iniciando consumo...")
            channel.start_consuming()
            
        except Exception as e:
            print(f"❌ Error: {e}")
            print("🔄 Reintentando en 5 segundos...")
            time.sleep(5)

# Ejecutar en thread separado
thread = threading.Thread(target=simple_consumer, daemon=True)
thread.start()
print("✅ Consumer iniciado en thread separado")

# Mantener el script ejecutándose
print("\n📡 Consumer ejecutándose en background...")
print("Presiona Ctrl+C para detener")
while True:
    time.sleep(1)
