from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional, List

# ============== ESPECIALIDADES ==============
class SpecialtyBase(BaseModel):
    name: str
    description: Optional[str] = None

class SpecialtyCreate(SpecialtyBase):
    pass

class Specialty(SpecialtyBase):
    id: int
    created_at: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)

# ============== DOCTORES ==============
# ¡COINCIDE CON models.py CORREGIDO!
class DoctorBase(BaseModel):
    user_id: str
    license_number: str
    specialty_id: Optional[int] = None
    consultation_duration: Optional[int] = 30

class DoctorCreate(DoctorBase):
    pass

class Doctor(DoctorBase):
    id: int
    created_at: Optional[datetime] = None
    
    # Propiedades calculadas para compatibilidad
    @property
    def name(self):
        return f"Doctor {self.user_id}"
    
    @property
    def email(self):
        return f"{self.user_id}@hospital.com"
    
    @property
    def phone(self):
        return "555-XXXX"
    
    model_config = ConfigDict(from_attributes=True)

# ============== CITAS ==============
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
    
    model_config = ConfigDict(from_attributes=True)
