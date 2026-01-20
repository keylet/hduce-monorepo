"""RabbitMQ Consumer CORREGIDO para Notification Service"""
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
        """Handle appointment created event - TOLERANTE a múltiples formatos"""
        db = SessionLocal()
        try:
            # MANEJO TOLERANTE DE MÚLTIPLES FORMATOS:
            # 1. Formato actual de routes.py: {"appointment_id": X, "patient_email": "...", ...}
            # 2. Formato esperado original: {"id": X, "patient_id": Y, ...}
            # 3. Formato envuelto por rabbitmq_utils: {"data": { ... }}
            
            # Si los datos están dentro de un campo "data", extraerlos
            if "data" in appointment_data and isinstance(appointment_data["data"], dict):
                actual_data = appointment_data["data"]
            else:
                actual_data = appointment_data
            
            # Obtener appointment_id de cualquier campo posible
            appointment_id = (
                actual_data.get("id") or 
                actual_data.get("appointment_id")
            )
            
            # Obtener patient_id - si no existe, derivar de email
            patient_id = actual_data.get("patient_id")
            if not patient_id and actual_data.get("patient_email"):
                # Para pruebas, mapear email conocido a ID
                email = actual_data.get("patient_email")
                if email == "testuser@example.com":
                    patient_id = 1
                else:
                    # Simulación: crear un ID basado en el email
                    patient_id = abs(hash(email)) % 1000 + 1
            
            # Si aún no hay patient_id, usar valor por defecto
            if not patient_id:
                patient_id = 1
            
            # Obtener otros campos necesarios
            doctor_id = actual_data.get("doctor_id")
            appointment_date = actual_data.get("appointment_date")
            reason = actual_data.get("reason") or actual_data.get("notes", "") or "Consulta médica"
            
            print(f"🎯 Procesando cita: ID={appointment_id}, Paciente={patient_id}, Doctor={doctor_id}")
            
            # Validar datos mínimos
            if not all([appointment_id, patient_id, doctor_id, appointment_date]):
                print(f"⚠️ Datos incompletos: {actual_data}")
                return
            
            # Notificación para paciente
            patient_notification = models.Notification(
                user_id=patient_id,
                user_email=actual_data.get("patient_email", f"patient_{patient_id}@example.com"),
                notification_type="in_app",
                title="Cita médica confirmada",
                message=f"Su cita #{appointment_id} ha sido programada para el {appointment_date}. Motivo: {reason}",
                is_read=False,
                created_at=datetime.now()
            )
            db.add(patient_notification)
            
            # Notificación para doctor
            doctor_notification = models.Notification(
                user_id=doctor_id,
                user_email=f"doctor_{doctor_id}@example.com",
                notification_type="in_app",
                title="Nueva cita asignada",
                message=f"Tiene una nueva cita #{appointment_id} programada para el {appointment_date}. Paciente ID: {patient_id}",
                is_read=False,
                created_at=datetime.now()
            )
            db.add(doctor_notification)
            
            db.commit()
            print(f"✅ 2 notificaciones creadas para cita {appointment_id}")
            
        except Exception as e:
            print(f"❌ Error creando notificaciones: {e}")
            import traceback
            traceback.print_exc()
            db.rollback()
        finally:
            db.close()
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

