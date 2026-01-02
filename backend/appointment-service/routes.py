from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import asyncio

from database import get_db
import models
import schemas
from notification_integration import send_appointment_notification

router = APIRouter()

# ==================== CITAS MÉDICAS ====================

@router.post("/appointments", response_model=schemas.Appointment)
async def create_appointment(
    appointment: schemas.AppointmentCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Crear una nueva cita médica y enviar notificación"""
    # 1. Obtener datos del paciente y doctor
    patient = db.query(models.User).filter(models.User.id == appointment.patient_id).first()
    doctor = db.query(models.Doctor).filter(models.Doctor.id == appointment.doctor_id).first()
    
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    # 2. Crear la cita en la base de datos
    db_appointment = models.Appointment(
        **appointment.dict(),
        status="scheduled",
        created_at=datetime.now()
    )
    
    db.add(db_appointment)
    db.commit()
    db.refresh(db_appointment)
    
    # 3. Preparar datos para notificación
    appointment_data = {
        "patient_id": str(patient.id),
        "patient_email": patient.email,
        "patient_phone": None,  # Podríamos agregar teléfono al modelo User
        "doctor_name": f"Dr. {patient.name}" if hasattr(patient, 'name') else f"Doctor ID {doctor.id}",
        "appointment_date": appointment.appointment_date.isoformat() if hasattr(appointment.appointment_date, 'isoformat') else str(appointment.appointment_date),
        "appointment_id": db_appointment.id
    }
    
    # 4. Enviar notificación en background
    background_tasks.add_task(
        send_appointment_notification,
        appointment_data=appointment_data,
        notification_type="confirmation"
    )
    
    # También programar recordatorio para 24h antes
    # (esto es un ejemplo simple - en producción usaríamos Celery o similar)
    
    return db_appointment

@router.get("/appointments", response_model=List[schemas.Appointment])
async def read_appointments(
    skip: int = 0,
    limit: int = 100,
    patient_id: Optional[str] = None,
    doctor_id: Optional[int] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Leer citas médicas con filtros"""
    query = db.query(models.Appointment)
    
    if patient_id:
        query = query.filter(models.Appointment.patient_id == patient_id)
    if doctor_id:
        query = query.filter(models.Appointment.doctor_id == doctor_id)
    if status:
        query = query.filter(models.Appointment.status == status)
    
    return query.offset(skip).limit(limit).all()

@router.get("/appointments/{appointment_id}", response_model=schemas.Appointment)
async def read_appointment(
    appointment_id: int,
    db: Session = Depends(get_db)
):
    """Leer una cita médica específica"""
    appointment = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    return appointment

@router.put("/appointments/{appointment_id}", response_model=schemas.Appointment)
async def update_appointment(
    appointment_id: int,
    appointment_update: schemas.AppointmentUpdate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Actualizar una cita médica y enviar notificación de actualización"""
    db_appointment = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if db_appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Guardar estado anterior para comparar
    old_status = db_appointment.status
    
    # Actualizar campos
    update_data = appointment_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_appointment, field, value)
    
    db_appointment.updated_at = datetime.now()
    db.commit()
    db.refresh(db_appointment)
    
    # Si el estado cambió, enviar notificación
    if old_status != db_appointment.status:
        patient = db.query(models.User).filter(models.User.id == db_appointment.patient_id).first()
        doctor = db.query(models.Doctor).filter(models.Doctor.id == db_appointment.doctor_id).first()
        
        if patient and doctor:
            appointment_data = {
                "patient_id": str(patient.id),
                "patient_email": patient.email,
                "doctor_name": f"Dr. {patient.name}" if hasattr(patient, 'name') else f"Doctor ID {doctor.id}",
                "appointment_date": db_appointment.appointment_date.isoformat(),
                "appointment_id": db_appointment.id
            }
            
            background_tasks.add_task(
                send_appointment_notification,
                appointment_data=appointment_data,
                notification_type="confirmation"  # Podríamos crear un tipo "status_update"
            )
    
    return db_appointment

@router.delete("/appointments/{appointment_id}")
async def delete_appointment(
    appointment_id: int,
    db: Session = Depends(get_db)
):
    """Eliminar una cita médica"""
    appointment = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if appointment is None:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    db.delete(appointment)
    db.commit()
    
    return {"message": "Appointment deleted successfully"}

# ==================== ESPECIALIDADES ====================

@router.get("/specialties", response_model=List[schemas.Specialty])
async def read_specialties(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Leer especialidades médicas"""
    specialties = db.query(models.Specialty).offset(skip).limit(limit).all()
    return specialties

@router.post("/specialties", response_model=schemas.Specialty)
async def create_specialty(specialty: schemas.SpecialtyCreate, db: Session = Depends(get_db)):
    """Crear una nueva especialidad médica"""
    db_specialty = models.Specialty(**specialty.dict())
    db.add(db_specialty)
    db.commit()
    db.refresh(db_specialty)
    return db_specialty

# ==================== DOCTORES ====================

@router.get("/doctors", response_model=List[schemas.Doctor])
async def read_doctors(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Leer doctores"""
    doctors = db.query(models.Doctor).offset(skip).limit(limit).all()
    return doctors

@router.post("/doctors", response_model=schemas.Doctor)
async def create_doctor(doctor: schemas.DoctorCreate, db: Session = Depends(get_db)):
    """Crear un nuevo doctor"""
    db_doctor = models.Doctor(**doctor.dict())
    db.add(db_doctor)
    db.commit()
    db.refresh(db_doctor)
    return db_doctor

# ==================== TEST INTEGRACIÓN ====================

@router.post("/appointments/test-notification")
async def test_notification_integration():
    """Endpoint para probar la integración con Notification Service"""
    test_data = {
        "patient_id": "test-patient-123",
        "patient_email": "test@example.com",
        "patient_phone": "+593987654321",
        "doctor_name": "Dr. Test",
        "appointment_date": "2026-01-10 10:00:00",
        "appointment_id": 999
    }
    
    success = await send_appointment_notification(test_data, "confirmation")
    
    if success:
        return {"message": "Test notification sent successfully", "status": "success"}
    else:
        return {"message": "Failed to send test notification", "status": "error"}
