from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime

# Esquema para registro de usuario
class UserCreate(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=2, max_length=100)
    role: str = Field(default="patient")
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None

    @validator('password')
    def password_strength(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters')
        return v

# Esquema para login
class UserLogin(BaseModel):
    email: EmailStr
    password: str

# Esquema para respuesta de usuario
class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    full_name: str
    role: str
    phone: Optional[str]
    city: Optional[str]
    country: Optional[str]
    is_active: bool
    is_verified: bool
    
    class Config:
        from_attributes = True

# Esquema para respuesta de token
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

# Esquema para verificación de token
class TokenVerification(BaseModel):
    token: str

class TokenVerificationResponse(BaseModel):
    is_valid: bool
    user_id: Optional[str] = None
    username: Optional[str] = None
    email: Optional[str] = None
    role: Optional[str] = None
    expires_at: Optional[int] = None