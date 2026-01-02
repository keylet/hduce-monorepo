from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class UserProfile(BaseModel):
    """User profile for frontend/API responses"""
    id: str
    name: str
    email: str  # Cambiado de EmailStr a str para simplificar
    age: Optional[int] = None
    created_at: datetime
    updated_at: datetime

class CreateUserRequest(BaseModel):
    """Request model for creating a user"""
    name: str
    email: str  # Cambiado de EmailStr a str para simplificar
    age: Optional[int] = None

class User(BaseModel):
    """Core user model for authentication"""
    id: str
    username: str
    email: str  # Cambiado de EmailStr a str para simplificar
    is_active: bool = True
    created_at: datetime

    class Config:
        from_attributes = True  # Para compatibilidad con SQLAlchemy
