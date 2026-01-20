import pika
import json
import sys

# Configuración
RABBITMQ_HOST = 'localhost'
RABBITMQ_PORT = 5672
RABBITMQ_USER = 'guest'
RABBITMQ_PASS = 'guest'
EXCHANGE_NAME = 'appointments'
ROUTING_KEY = 'notification.created'

# Crear mensaje de prueba DIRECTO
test_message = {
    "event_type": "APPOINTMENT_CREATED",
    "timestamp": "2024-03-20T10:00:00",
    "data": {
        "appointment_id": 999,
        "patient_id": 1,
        "patient_email": "testuser@example.com",
        "patient_name": "Test User",
        "doctor_id": 5,
        "appointment_date": "2024-03-25 14:30:00",
        "reason": "Prueba directa desde script",
        "status": "confirmed"
    },
    "metadata": {
        "service": "manual_test",
        "version": "1.0"
    }
}

print("📤 Enviando mensaje de prueba directa a RabbitMQ...")
print(f"Mensaje: {json.dumps(test_message, indent=2)}")

try:
    # Conectar a RabbitMQ
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    parameters = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials
    )
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    
    # Publicar mensaje
    channel.basic_publish(
        exchange=EXCHANGE_NAME,
        routing_key=ROUTING_KEY,
        body=json.dumps(test_message),
        properties=pika.BasicProperties(
            delivery_mode=2,  # Persistente
            content_type='application/json'
        )
    )
    
    print("✅ Mensaje de prueba enviado a RabbitMQ exitosamente!")
    
    connection.close()
    
except Exception as e:
    print(f"❌ Error enviando mensaje: {e}")
    sys.exit(1)
