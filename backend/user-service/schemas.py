# backend/user-service/schemas.py
# ✅ Schemas específicos para user-service (no duplicados de auth)
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
import uuid

class UserBase(BaseModel):
    """Base schema for user data"""
    name: str
    email: EmailStr  # Podemos usar EmailStr ahora
    age: Optional[int] = None

class UserCreate(UserBase):
    """Schema for creating a user"""
    pass  # Puedes agregar campos específicos de creación si es necesario

class UserResponse(UserBase):
    """Schema for user response"""
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # For SQLAlchemy compatibility

# Schema para actualización parcial
class UserUpdate(BaseModel):
    """Schema for updating user (partial update)"""
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    age: Optional[int] = None


# ============ PATIENT SCHEMAS ============
class PatientBase(BaseModel):
    """Base schema for patient data"""
    user_id: int
    date_of_birth: date
    gender: str
    blood_type: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    allergies: Optional[str] = None
    chronic_conditions: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    insurance_provider: Optional[str] = None
    insurance_policy_number: Optional[str] = None

class PatientCreate(PatientBase):
    """Schema for creating a patient"""
    pass

class PatientResponse(PatientBase):
    """Schema for patient response"""
    patient_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
