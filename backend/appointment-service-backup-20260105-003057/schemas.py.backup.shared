from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from enum import Enum

# Enums
class AppointmentStatus(str, Enum):
    SCHEDULED = "scheduled"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"

# Esquemas base
class SpecialtyBase(BaseModel):
    name: str
    description: Optional[str] = None

class SpecialtyCreate(SpecialtyBase):
    pass

class Specialty(SpecialtyBase):
    id: int
    
    class Config:
        from_attributes = True

class DoctorBase(BaseModel):
    user_id: str
    license_number: str
    specialty_id: int
    consultation_duration: int = 30

class DoctorCreate(DoctorBase):
    pass

class Doctor(DoctorBase):
    id: int
    specialty: Optional[Specialty] = None
    
    class Config:
        from_attributes = True

class AppointmentBase(BaseModel):
    patient_id: str
    doctor_id: int
    appointment_date: datetime
    reason: Optional[str] = None
    notes: Optional[str] = None

class AppointmentCreate(AppointmentBase):
    pass

class AppointmentUpdate(BaseModel):
    status: Optional[AppointmentStatus] = None
    notes: Optional[str] = None
    reason: Optional[str] = None

class Appointment(AppointmentBase):
    id: int
    status: AppointmentStatus
    created_at: datetime
    updated_at: Optional[datetime] = None
    doctor: Optional[Doctor] = None
    
    class Config:
        from_attributes = True
