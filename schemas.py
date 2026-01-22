from typing import List, Optional
from pydantic import BaseModel, EmailStr
from datetime import datetime, date, time

# ==================== Specialty Schemas ====================
class SpecialtyBase(BaseModel):
    name: str
    description: Optional[str] = None

class SpecialtyCreate(SpecialtyBase):
    pass

class SpecialtyResponse(SpecialtyBase):
    id: int
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# ==================== Doctor Schemas ====================
class DoctorBase(BaseModel):
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    specialty_id: Optional[int] = None
    is_active: bool = True

class DoctorCreate(DoctorBase):
    pass

class DoctorUpdate(DoctorBase):
    pass

# DoctorResponse CORREGIDO - maneja la relación specialty correctamente
class DoctorResponse(DoctorBase):
    id: int
    created_at: Optional[datetime] = None
    # Cambiado: en lugar de specialty: Optional[str], usamos specialty: Optional[SpecialtyResponse]
    specialty: Optional[SpecialtyResponse] = None
    
    class Config:
        from_attributes = True

# ==================== Appointment Schemas ====================
class AppointmentBase(BaseModel):
    doctor_id: int
    appointment_date: date
    appointment_time: time
    reason: Optional[str] = None
    status: Optional[str] = "scheduled"

class AppointmentCreate(AppointmentBase):
    pass

class AppointmentUpdate(BaseModel):
    """Esquema para actualizar citas - todos los campos opcionales"""
    doctor_id: Optional[int] = None
    appointment_date: Optional[date] = None
    appointment_time: Optional[time] = None
    reason: Optional[str] = None
    status: Optional[str] = None

class AppointmentResponse(AppointmentBase):
    id: int
    patient_id: int
    patient_email: str
    patient_name: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Alias para compatibilidad con código existente
Appointment = AppointmentResponse

# ==================== Webhook Schemas ====================
class WebhookPayload(BaseModel):
    event: str
    data: dict
    timestamp: datetime

class WebhookResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None
