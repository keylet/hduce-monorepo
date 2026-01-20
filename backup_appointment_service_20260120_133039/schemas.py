from pydantic import BaseModel
from datetime import datetime, date, time
from typing import Optional

# Modelos para Doctor y Specialty (mantener existentes)
class SpecialtyBase(BaseModel):
    name: str
    description: Optional[str] = None

class SpecialtyCreate(SpecialtyBase):
    pass

class Specialty(SpecialtyBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class DoctorBase(BaseModel):
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    specialty_id: Optional[int] = None
    is_active: bool = True

class DoctorCreate(DoctorBase):
    pass

class Doctor(DoctorBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Modelos para Appointment - CORREGIDOS
class AppointmentBase(BaseModel):
    doctor_id: int
    appointment_date: date  # Cambiado de datetime a date
    appointment_time: time  # Añadido campo time
    reason: Optional[str] = None
    status: Optional[str] = "scheduled"  # Cambiado de "pending"
    # patient_id, patient_email, patient_name NO deben estar aquí
    # Se derivan del token

class AppointmentCreate(AppointmentBase):
    pass

class AppointmentUpdate(BaseModel):
    """Esquema para actualizar citas - TODOS los campos son opcionales"""
    doctor_id: Optional[int] = None
    appointment_date: Optional[date] = None
    appointment_time: Optional[time] = None
    reason: Optional[str] = None
    status: Optional[str] = None

class AppointmentResponse(AppointmentBase):
    id: int
    patient_id: int  # Añadidos en respuesta
    patient_email: str
    patient_name: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Modelo para compatibilidad con código existente
class Appointment(AppointmentBase):
    id: int
    patient_id: int
    patient_email: str
    patient_name: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class DoctorResponse(BaseModel):
    id: int
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    specialty_id: Optional[int] = None
    is_active: bool = True

    class Config:
        from_attributes = True

