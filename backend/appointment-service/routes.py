from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import asyncio

from database import get_db
import models
import schemas
from notification_integration import send_appointment_notification
from rabbitmq_publisher import event_publisher  # NUEVO: RabbitMQ

router = APIRouter()

# ==================== CITAS MÉDICAS ====================

@router.post("/appointments", response_model=schemas.Appointment)
async def create_appointment(
    appointment: schemas.AppointmentCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Crear una nueva cita médica y enviar notificación"""
    
    # 1. Verificar que el doctor existe
    doctor = db.query(models.Doctor).filter(models.Doctor.id == appointment.doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # 2. Crear la cita en la base de datos
    db_appointment = models.Appointment(
        patient_id=appointment.patient_id,
        doctor_id=appointment.doctor_id,
        appointment_date=appointment.appointment_date,
        reason=appointment.reason,
        notes=appointment.notes,
        created_at=datetime.now()
    )
    
    db.add(db_appointment)
    db.commit()
    db.refresh(db_appointment)
    
    # 3. Preparar datos para notificación
    appointment_data = {
        "appointment_id": str(db_appointment.id),
        "patient_id": appointment.patient_id,
        "doctor_name": f"Doctor ID {doctor.id}",
        "appointment_date": appointment.appointment_date.isoformat() if hasattr(appointment.appointment_date, "isoformat") else str(appointment.appointment_date),
        "reason": appointment.reason or "Consulta médica"
    }
    
    # 4. OPCIÓN A: Enviar notificación por RabbitMQ (NUEVO)
    try:
        # Publicar evento en RabbitMQ
        rabbitmq_success = event_publisher.publish_appointment_created(appointment_data)
        if rabbitmq_success:
            print(f"✅ Evento publicado en RabbitMQ para cita {db_appointment.id}")
        else:
            print(f"⚠️  Falló RabbitMQ, usando HTTP fallback")
            # Fallback a HTTP
            background_tasks.add_task(
                send_appointment_notification,
                appointment_data=appointment_data,
                notification_type="confirmation"
            )
    except Exception as e:
        print(f"⚠️  Error con RabbitMQ: {e}. Usando HTTP fallback")
        # Fallback a HTTP
        background_tasks.add_task(
            send_appointment_notification,
            appointment_data=appointment_data,
            notification_type="confirmation"
        )
    
    return db_appointment

# ... (el resto del routes.py se mantiene igual - copia el contenido actual aquí) ...

