from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

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
    user_id: str
    license_number: str
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    specialty_id: Optional[int] = None
    consultation_duration: Optional[int] = 30

class DoctorCreate(DoctorBase):
    pass

class Doctor(DoctorBase):
    id: int
    created_at: Optional[datetime] = None
    
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

class Appointment(AppointmentBase):
    id: int
    status: str = "scheduled"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True
