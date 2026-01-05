from pydantic import BaseModel, EmailStr  # <- EmailStr con S mayúscula
from datetime import datetime
from typing import Optional

class UserProfile(BaseModel):
    """User profile for frontend/API responses"""
    id: str
    name: str
    email: EmailStr  # <- Corregido
    age: Optional[int] = None
    created_at: datetime
    updated_at: datetime

class CreateUserRequest(BaseModel):
    """Request model for creating a user"""
    name: str
    email: EmailStr  # <- Corregido
    age: Optional[int] = None

class User(BaseModel):
    """Core user model for authentication"""
    id: str
    username: str
    email: EmailStr  # <- Corregido
    is_active: bool = True  # <- Guión bajo, no espacio
    created_at: datetime

    class Config:  # <- Esta clase DENTRO de User
        from_attributes = True  # Para compatibilidad con SQLAlchemy