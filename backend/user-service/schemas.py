from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    name: str
    email: EmailStr
    age: Optional[int] = None

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: int  # ← CORREGIDO: cambiar de uuid.UUID a int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # Para Pydantic v2 (antes orm_mode=True)
