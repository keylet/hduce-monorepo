from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import logging

from database import get_db
from models import Appointment, Doctor
from schemas import AppointmentCreate, AppointmentUpdate, AppointmentResponse
from auth_client import verify_token
from rabbitmq_utils import publish_appointment_created as publish_appointment_event

router = APIRouter(tags=["appointments"])
logger = logging.getLogger(__name__)

async def get_current_user(current_user: dict = Depends(verify_token)):
    """Obtiene el usuario actual del token verificado"""
    return current_user

@router.get("/appointments/", response_model=List[AppointmentResponse])
def read_appointments(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    appointments = db.query(Appointment).offset(skip).limit(limit).all()
    return appointments

@router.get("/appointments/{appointment_id}", response_model=AppointmentResponse)
def read_appointment(appointment_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return appointment

@router.post("/appointments/", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def create_appointment(appointment: AppointmentCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    logger.info(f"=== CREATE APPOINTMENT DEBUG ===")
    logger.info(f"Current user from token: {current_user}")
    logger.info(f"Appointment data received: {appointment.dict()}")
    
    # Extraer información del usuario autenticado del token
    user_id = current_user.get("user_id") or current_user.get("sub")
    email = current_user.get("user", {}).get("email") or current_user.get("email")
    name = current_user.get("user", {}).get("username") or current_user.get("name") or current_user.get("username") or "Test User"
    
    logger.info(f"Extracted from token - user_id: {user_id}, email: {email}, name: {name}")
    
    # Validar que tenemos los datos necesarios
    if not user_id:
        logger.error(f"Falta user_id en token. Token completo: {current_user}")
        raise HTTPException(
            status_code=400, 
            detail=f"No user_id in token. Token data: {current_user}"
        )
    
    if not email:
        logger.error(f"Falta email en token. Token completo: {current_user}")
        raise HTTPException(
            status_code=400, 
            detail=f"No email in token. Token data: {current_user}"
        )
    
    # Verificar que el doctor existe
    doctor = db.query(Doctor).filter(Doctor.id == appointment.doctor_id).first()
    if doctor is None:
        logger.error(f"Doctor con ID {appointment.doctor_id} no encontrado")
        raise HTTPException(status_code=400, detail=f"Doctor with ID {appointment.doctor_id} not found")
    
    # Convertir user_id a entero si es string
    try:
        patient_id_int = int(user_id)
    except (ValueError, TypeError):
        logger.warning(f"user_id no es entero: {user_id}, usando 1 como fallback")
        patient_id_int = 1
    
    # Crear el objeto de cita con TODOS los campos requeridos
    # NOTA: appointment NO tiene patient_id, patient_email, patient_name
    # Estos se derivan del token y se añaden aquí
    db_appointment = Appointment(
        doctor_id=appointment.doctor_id,
        appointment_date=appointment.appointment_date,
        appointment_time=appointment.appointment_time,
        #   # Columna no existe en BD
        status=appointment.status,
        # Campos derivados del token (NO vienen en AppointmentCreate):
        patient_id=patient_id_int,
        patient_email=email,
        patient_name=name
    )
    
    logger.info(f"Intentando crear cita con datos: doctor_id={db_appointment.doctor_id}, "
                f"date={db_appointment.appointment_date}, time={db_appointment.appointment_time}, "
                f"patient_id={db_appointment.patient_id}, patient_email={db_appointment.patient_email}")
    
    try:
        db.add(db_appointment)
        db.commit()
        db.refresh(db_appointment)
        logger.info(f"? Cita creada exitosamente: ID {db_appointment.id}")
    except Exception as e:
        db.rollback()
        logger.error(f"? Error al crear cita en BD: {str(e)}")
        logger.error(f"Error type: {type(e)}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    
    # Publicar evento a RabbitMQ
    try:
        from rabbitmq_utils import publish_appointment_created
        publish_appointment_created({
            "appointment_id": db_appointment.id,
            "patient_id": db_appointment.patient_id,
            "patient_email": db_appointment.patient_email,
            "patient_name": db_appointment.patient_name,
            "doctor_id": db_appointment.doctor_id,
            "appointment_date": db_appointment.appointment_date.isoformat() if db_appointment.appointment_date else None,
            "appointment_time": db_appointment.appointment_time.isoformat() if db_appointment.appointment_time else None,
            "reason": db_appointment.reason,
            "status": db_appointment.status
        })
        logger.info(f"? Evento publicado a RabbitMQ para cita {db_appointment.id}")
    except Exception as e:
        logger.error(f"?? Error publicando evento a RabbitMQ: {e}")
        # No lanzamos excepción porque la cita ya se creó
    
    return db_appointment

@router.put("/appointments/{appointment_id}", response_model=AppointmentResponse)
def update_appointment(appointment_id: int, appointment_update: AppointmentUpdate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    db_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if db_appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    update_data = appointment_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_appointment, field, value)
    
    db.commit()
    db.refresh(db_appointment)
    return db_appointment

@router.delete("/appointments/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_appointment(appointment_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    db.delete(appointment)
    db.commit()
    return None











