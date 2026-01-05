"""RabbitMQ Consumer for Notification Service"""
import json
from datetime import datetime
from sqlalchemy.orm import Session
from typing import Dict, Any
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Importar modelos
import models

# Crear engine y session local directamente
def get_db_engine():
    """Crear engine de base de datos"""
    DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/notification_db"
    return create_engine(DATABASE_URL)

def get_session_local():
    """Crear session factory"""
    engine = get_db_engine()
    return sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Session factory global
SessionLocal = get_session_local()

def process_appointment_event(message: Dict[str, Any]) -> None:
    """Process appointment events from RabbitMQ"""
    try:
        event_type = message.get("event_type")
        data = message.get("data", {})
        timestamp = message.get("timestamp", datetime.now().isoformat())

        print(f"🎯 Processing event: {event_type}")
        print(f"📋 Event data: {data}")

        if event_type == "APPOINTMENT_CREATED":
            handle_appointment_created(data, timestamp)
        else:
            print(f"⚠️  Unknown event type: {event_type}")

    except Exception as e:
        print(f"❌ Error processing event: {e}")
        import traceback
        print(traceback.format_exc())

def handle_appointment_created(appointment_data: Dict[str, Any], timestamp: str) -> None:
    """Handle appointment created event - CORREGIDO"""
    db: Session = SessionLocal()
    try:
        # ¡CORRECCIÓN! appointment_data tiene "id", no "appointment_id"
        appointment_id = appointment_data.get("id")
        patient_id = appointment_data.get("patient_id")
        doctor_id = appointment_data.get("doctor_id")
        appointment_date = appointment_data.get("appointment_date")
        reason = appointment_data.get("reason", "")

        print(f"📅 Nueva cita creada: ID={appointment_id}, Paciente={patient_id}")

        # Validar campos requeridos
        if not all([appointment_id, patient_id, doctor_id, appointment_date]):
            print(f"⚠️ Datos incompletos: {appointment_data}")
            return

        # Crear notificación para el paciente
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

        # También podrías crear notificación para el doctor
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

        print(f"✅ Notificaciones creadas para cita {appointment_id}")
        print(f"   - Notificación para paciente: {patient_id}")
        print(f"   - Notificación para doctor: {doctor_id}")

    except Exception as e:
        print(f"❌ Error creating notifications: {e}")
        import traceback
        print(traceback.format_exc())
        db.rollback()
    finally:
        db.close()

# NOTA: El resto del archivo (start_rabbitmq_consumer, etc.) se mantiene igual
# Solo necesitamos reemplazar las funciones de arriba
