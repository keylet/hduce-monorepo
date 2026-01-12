# backend/user-service/schemas.py
from pydantic import BaseModel
from typing import Optional
from datetime import date  # ✅ IMPORTAR date desde datetime

class PatientBase(BaseModel):
    user_id: int
    first_name: str
    last_name: str
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    emergency_contact: Optional[str] = None
    blood_type: Optional[str] = None
    allergies: Optional[str] = None
    current_medications: Optional[str] = None
    medical_notes: Optional[str] = None

class PatientCreate(PatientBase):
    pass

class PatientResponse(PatientBase):
    patient_id: int
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

    class Config:
        from_attributes = True
