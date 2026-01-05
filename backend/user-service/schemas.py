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
