"""RabbitMQ Consumer INDEPENDIENTE para Notification Service"""
import json
import pika
from hduce_shared.config import settings
from datetime import datetime
from typing import Dict, Any
import threading
import time

# Importar NUESTRA configuración de base de datos
from database import SessionLocal
import models

class IndependentRabbitMQConsumer:
    def __init__(self):
        print("🚀 Inicializando IndependentRabbitMQConsumer...")
        self.running = False
        
    def handle_appointment_created(self, appointment_data: Dict[str, Any]) -> None:
        """Handle appointment created event - usa NUESTRO SessionLocal"""
        db = SessionLocal()  # ¡ESTA ES LA CLAVE! Usa NUESTRO SessionLocal
        try:
            appointment_id = appointment_data.get("id")
            patient_id = appointment_data.get("patient_id")
            doctor_id = appointment_data.get("doctor_id")
            appointment_date = appointment_data.get("appointment_date")
            reason = appointment_data.get("reason", "")

            print(f"🎯 Procesando cita: ID={appointment_id}, Paciente={patient_id}")

            # Validar
            if not all([appointment_id, patient_id, doctor_id, appointment_date]):
                print(f"⚠️ Datos incompletos: {appointment_data}")
                return

            # Notificación para paciente
            patient_notification = models.Notification(
                user_id=patient_id,
                notification_type="in_app",
                subject="Cita médica confirmada",
                message=f"Su cita ha sido programada para el {appointment_date}. Motivo: {reason}",
                appointment_id=appointment_id,
                status="sent",
                sent_at=datetime.now(),
                created_at=datetime.now()
            )
            db.add(patient_notification)

            # Notificación para doctor
            doctor_notification = models.Notification(
                user_id=str(doctor_id),
                notification_type="in_app",
                subject="Nueva cita asignada",
                message=f"Tiene una nueva cita programada para el {appointment_date}. Paciente: {patient_id}",
                appointment_id=appointment_id,
                status="sent",
                sent_at=datetime.now(),
                created_at=datetime.now()
            )
            db.add(doctor_notification)

            db.commit()
            print(f"✅ 2 notificaciones creadas para cita {appointment_id}")

        except Exception as e:
            print(f"❌ Error: {e}")
            import traceback
            traceback.print_exc()
            db.rollback()
        finally:
            db.close()

    def process_message(self, ch, method, properties, body):
        """Procesar mensaje de RabbitMQ"""
        try:
            message = json.loads(body.decode())
            event_type = message.get("event_type")
            data = message.get("data", {})
            
            print(f"📨 Mensaje recibido: {event_type}")
            print(f"📋 Datos: {data}")
            
            if event_type == "APPOINTMENT_CREATED":
                self.handle_appointment_created(data)
            else:
                print(f"⚠️ Evento desconocido: {event_type}")
                
            ch.basic_ack(delivery_tag=method.delivery_tag)
            
        except Exception as e:
            print(f"❌ Error procesando mensaje: {e}")
            import traceback
            traceback.print_exc()

    def start(self):
        """Iniciar consumer"""
        print("🚀 Iniciando IndependentRabbitMQConsumer...")
        self.running = True
        
        def consume():
            while self.running:
                try:
                    credentials = pika.PlainCredentials(settings.rabbitmq.rabbitmq_user, settings.rabbitmq.rabbitmq_password)
                    connection = pika.BlockingConnection(
                        pika.ConnectionParameters(
                            host="rabbitmq",
                            port=5672,
                            credentials=credentials,
                            heartbeat=600
                        )
                    )
                    
                    channel = connection.channel()
                    
                    # Asegurar exchange y queue
                    channel.exchange_declare(
                        exchange="appointments",
                        exchange_type="direct",
                        durable=True
                    )
                    
                    channel.queue_declare(
                        queue="appointment_notifications",
                        durable=True
                    )
                    
                    channel.queue_bind(
                        exchange="appointments",
                        queue="appointment_notifications",
                        routing_key="appointment.created"
                    )
                    
                    channel.basic_qos(prefetch_count=1)
                    
                    print("✅ Conectado a RabbitMQ. Esperando mensajes...")
                    
                    channel.basic_consume(
                        queue="appointment_notifications",
                        on_message_callback=self.process_message,
                        auto_ack=False
                    )
                    
                    channel.start_consuming()
                    
                except Exception as e:
                    print(f"❌ Error de conexión: {e}. Reintentando en 5 segundos...")
                    time.sleep(5)
        
        # Iniciar en thread separado
        thread = threading.Thread(target=consume, daemon=True)
        thread.start()
        return self

def start_independent_consumer():
    """Iniciar consumer independiente"""
    try:
        consumer = IndependentRabbitMQConsumer()
        consumer.start()
        print("✅ IndependentRabbitMQConsumer iniciado exitosamente")
        return consumer
    except Exception as e:
        print(f"❌ Error iniciando consumer: {e}")
        import traceback
        traceback.print_exc()
        return None

# Iniciar automáticamente
independent_consumer = start_independent_consumer()
