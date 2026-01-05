import pika
import json

message = {
    'event_type': 'APPOINTMENT_CREATED',
    'data': {
        'appointment_id': 999,
        'patient_id': 'test_patient',
        'doctor_id': 1,
        'appointment_date': '2026-01-06T10:00:00'
    },
    'timestamp': '2026-01-05T16:30:00'
}

credentials = pika.PlainCredentials('admin', 'admin123')
connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host='localhost',
        port=5672,
        credentials=credentials
    )
)

channel = connection.channel()
channel.exchange_declare(exchange='appointments', exchange_type='direct')
channel.queue_declare(queue='appointment_notifications', durable=True)
channel.queue_bind(exchange='appointments', queue='appointment_notifications', routing_key='appointment.created')

channel.basic_publish(
    exchange='appointments',
    routing_key='appointment.created',
    body=json.dumps(message),
    properties=pika.BasicProperties(
        delivery_mode=2,
        content_type='application/json'
    )
)

print('✅ Mensaje de prueba publicado a RabbitMQ')
connection.close()
