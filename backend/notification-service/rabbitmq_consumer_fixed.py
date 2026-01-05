"""RabbitMQ Consumer simplificado para Notification Service"""
import json
import pika
import threading
from datetime import datetime
from typing import Dict, Any

# Importar get_db_session en lugar de SessionLocal
from database import get_db_session
import models

class SimpleRabbitMQConsumer:
    """Consumer simplificado sin dependencias de shared-libraries"""

    def __init__(self):
        self.config = {
            "host": "rabbitmq",
            "port": 5672,
            "username": "admin",
            "password": "admin123",
            "exchange": "appointments",
            "queue": "appointment_notifications",
            "routing_key": "appointment.created"
        }
        self.connection = None
        self.channel = None
        self.consuming = False

    def connect(self):
        """Conectar a RabbitMQ"""
        try:
            credentials = pika.PlainCredentials(
                self.config["username"],
                self.config["password"]
            )

            self.connection = pika.BlockingConnection(
                pika.ConnectionParameters(
                    host=self.config["host"],
                    port=self.config["port"],
                    credentials=credentials,
                    heartbeat=600,
                    blocked_connection_timeout=300
                )
            )

            self.channel = self.connection.channel()

            # Exchange y queue
            self.channel.exchange_declare(
                exchange=self.config["exchange"],
                exchange_type="direct",
                durable=True
            )

            self.channel.queue_declare(
                queue=self.config["queue"],
                durable=True
            )

            self.channel.queue_bind(
                exchange=self.config["exchange"],
                queue=self.config["queue"],
                routing_key=self.config["routing_key"]
            )

            self.channel.basic_qos(prefetch_count=1)

            print("SUCCESS: Consumer conectado a RabbitMQ")
            return True

        except Exception as e:
            print(f"ERROR: Error conectando a RabbitMQ: {e}")
            return False

    def process_message(self, message: Dict[str, Any]):
        """Procesar mensaje recibido"""
        try:
            event_type = message.get("event_type")
            data = message.get("data", {})

            print(f"INFO: Evento recibido: {event_type}")

            if event_type == "APPOINTMENT_CREATED":
                self.handle_appointment_created(data)
            else:
                print(f"WARNING: Evento no manejado: {event_type}")

        except Exception as e:
            print(f"ERROR: Error procesando mensaje: {e}")
            import traceback
            traceback.print_exc()

    def handle_appointment_created(self, appointment_data: Dict[str, Any]):
        """Manejar creación de cita"""
        # Usar get_db_session() para obtener sesión
        db = next(get_db_session())
        try:
            appointment_id = appointment_data.get("id")
            patient_id = appointment_data.get("patient_id")
            doctor_id = appointment_data.get("doctor_id")
            appointment_date = appointment_data.get("appointment_date")

            print(f"INFO: Nueva cita: ID={appointment_id}, Paciente={patient_id}")

            # Notificación para paciente
            patient_notification = models.Notification(
                user_id=patient_id,
                notification_type="in_app",
                subject="Cita médica confirmada",
                message=f"Su cita ha sido programada para el {appointment_date}",
                appointment_id=appointment_id,
                status="sent",
                sent_at=datetime.now(),
                created_at=datetime.now()
            )

            db.add(patient_notification)
            db.commit()

            print(f"SUCCESS: Notificación creada para cita {appointment_id}")

        except Exception as e:
            print(f"ERROR: Error creando notificación: {e}")
            db.rollback()
        finally:
            db.close()

    def start_consuming(self):
        """Iniciar consumo de mensajes"""
        def on_message(ch, method, properties, body):
            try:
                message = json.loads(body.decode('utf-8'))
                self.process_message(message)
                ch.basic_ack(delivery_tag=method.delivery_tag)
            except json.JSONDecodeError as e:
                print(f"ERROR: Error decodificando JSON: {e}")
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
            except Exception as e:
                print(f"ERROR: Error procesando: {e}")
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

        try:
            if not self.connect():
                return None

            self.channel.basic_consume(
                queue=self.config["queue"],
                on_message_callback=on_message
            )

            print("INFO: Consumer iniciado. Esperando mensajes...")
            self.consuming = True
            return self.channel

        except Exception as e:
            print(f"ERROR: Error iniciando consumer: {e}")
            return None

    def start_in_background(self):
        """Iniciar consumer en background"""
        def consumer_loop():
            while True:
                try:
                    channel = self.start_consuming()
                    if channel:
                        channel.start_consuming()
                except Exception as e:
                    print(f"ERROR: Consumer detenido, reintentando en 5s: {e}")
                    import time
                    time.sleep(5)

        thread = threading.Thread(target=consumer_loop, daemon=True)
        thread.start()
        print("SUCCESS: Consumer iniciado en background")
        return thread

def start_rabbitmq_consumer():
    """Función para iniciar consumer (compatible con main.py)"""
    try:
        consumer = SimpleRabbitMQConsumer()
        print("INFO: Iniciando RabbitMQ consumer simplificado...")
        thread = consumer.start_in_background()
        if thread:
            print("SUCCESS: Consumer simplificado iniciado exitosamente")
            return consumer
        else:
            print("ERROR: No se pudo iniciar consumer")
            return None
    except Exception as e:
        print(f"ERROR: Error iniciando consumer: {e}")
        import traceback
        traceback.print_exc()
        return None

# Iniciar automáticamente si se ejecuta como script
if __name__ == "__main__":
    start_rabbitmq_consumer()
    # Mantener el script vivo
    import time
    while True:
        time.sleep(1)
