"""
Routes for appointment service - Versión corregida con DatabaseManager correcto
"""
import logging
from typing import List
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session

# Importar de shared-libraries
from hduce_shared.database import DatabaseManager
from hduce_shared.rabbitmq.publisher import RabbitMQPublisher

# Importar modelos y esquemas locales
from models import Appointment, Doctor
from schemas import AppointmentCreate, AppointmentResponse, DoctorResponse
from auth_client import get_current_user

logger = logging.getLogger(__name__)

# Crear router SIN prefix aquí - el prefix /api se añade en main.py
router = APIRouter()

# Dependencia de base de datos - usar DatabaseManager.get_session correctamente
def get_db():
    """CORRECTO: Usar DatabaseManager.get_session() como context manager"""
    with DatabaseManager.get_session("appointments") as session:
        try:
            yield session
        except Exception:
            # El context manager ya maneja commit/rollback automáticamente
            raise

def publish_appointment_created(appointment_data: dict):
    """Publica evento de cita creada a RabbitMQ"""
    try:
        publisher = RabbitMQPublisher()
        success = publisher.publish_appointment_created({
            "appointment_id": appointment_data.get("id"),
            "patient_id": appointment_data.get("patient_id"),
            "patient_email": appointment_data.get("patient_email", ""),
            "doctor_id": appointment_data.get("doctor_id"),
            "appointment_date": str(appointment_data.get("appointment_date")),
            "appointment_time": str(appointment_data.get("appointment_time")),
            "reason": appointment_data.get("reason", "Consulta médica"),
            "created_at": datetime.utcnow().isoformat()
        })
        if success:
            logger.info(f"✅ Evento publicado a RabbitMQ para cita #{appointment_data.get('id')}")
        else:
            logger.error(f"❌ Error al publicar evento a RabbitMQ para cita #{appointment_data.get('id')}")
    except Exception as e:
        logger.error(f"❌ Error en RabbitMQ publisher: {e}")

@router.get("/appointments/", response_model=List[AppointmentResponse])
async def get_appointments(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get all appointments - GET /api/appointments/"""
    try:
        appointments = db.query(Appointment).offset(skip).limit(limit).all()
        return appointments
    except Exception as e:
        logger.error(f"Error al obtener citas: {e}")
        raise HTTPException(status_code=500, detail=f"Error getting appointments: {str(e)}")

@router.get("/appointments/{appointment_id}", response_model=AppointmentResponse)
async def get_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get specific appointment by ID - GET /api/appointments/{id}"""
    try:
        appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
        if not appointment:
            raise HTTPException(status_code=404, detail="Appointment not found")
        return appointment
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error al obtener cita {appointment_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Error getting appointment: {str(e)}")

@router.post("/appointments/", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    appointment: AppointmentCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Create a new appointment - POST /api/appointments/"""
    try:
        # Obtener patient_id del usuario actual
        user_id = current_user.get("user_id")
        if not user_id:
            logger.error(f"Usuario no tiene user_id válido: {current_user}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Usuario no tiene un ID válido"
            )

        # Convertir user_id a int (patient_id)
        try:
            patient_id = int(user_id)
        except (ValueError, TypeError):
            logger.error(f"user_id no es un número válido: {user_id}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="ID de usuario no válido"
            )

        # Crear diccionario con datos de la cita
        appointment_dict = appointment.dict()

        # Añadir información del paciente desde el usuario actual
        appointment_dict["patient_id"] = patient_id
        appointment_dict["patient_email"] = current_user.get("email", f"user{patient_id}@example.com")
        appointment_dict["patient_name"] = current_user.get("username", f"Paciente {patient_id}")

        # Crear objeto de cita
        db_appointment = Appointment(**appointment_dict)
        db.add(db_appointment)
        db.commit()
        db.refresh(db_appointment)

        logger.info(f"✅ Cita creada: ID={db_appointment.id}, Paciente={db_appointment.patient_id}")

        # Preparar datos para RabbitMQ
        rabbitmq_data = {
            "id": db_appointment.id,
            "patient_id": db_appointment.patient_id,
            "patient_email": db_appointment.patient_email,
            "doctor_id": db_appointment.doctor_id,
            "appointment_date": str(db_appointment.appointment_date),
            "appointment_time": str(db_appointment.appointment_time),
            "reason": db_appointment.reason
        }

        # Publicar a RabbitMQ en background
        background_tasks.add_task(publish_appointment_created, rabbitmq_data)

        return db_appointment

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"❌ Error al crear cita: {e}")
        raise HTTPException(status_code=500, detail=f"Error creating appointment: {str(e)}")

@router.put("/appointments/{appointment_id}", response_model=AppointmentResponse)
async def update_appointment(
    appointment_id: int,
    appointment_update: AppointmentCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Update an appointment - PUT /api/appointments/{id}"""
    try:
        db_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
        if not db_appointment:
            raise HTTPException(status_code=404, detail="Appointment not found")

        for key, value in appointment_update.dict().items():
            setattr(db_appointment, key, value)

        db.commit()
        db.refresh(db_appointment)
        return db_appointment
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error al actualizar cita {appointment_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Error updating appointment: {str(e)}")

@router.delete("/appointments/{appointment_id}")

@router.get('/doctors/', response_model=List[DoctorResponse])
async def get_doctors(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all doctors - GET /api/doctors/"""
    try:
        doctors = db.query(Doctor).offset(skip).limit(limit).all()
        return doctors
    except Exception as e:
        logger.error(f'Error al obtener doctores: {e}')
        raise HTTPException(status_code=500, detail=f'Error getting doctors: {str(e)}')

async def delete_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Delete an appointment - DELETE /api/appointments/{id}"""
    try:
        db_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
        if not db_appointment:
            raise HTTPException(status_code=404, detail="Appointment not found")

        db.delete(db_appointment)
        db.commit()
        return {"message": "Appointment deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error al eliminar cita {appointment_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Error deleting appointment: {str(e)}")



