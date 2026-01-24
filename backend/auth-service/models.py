# backend/auth-service/models.py
# Modelos para auth-service - VERSIÓN CORREGIDA

from sqlalchemy import Column, Integer, String, Boolean, DateTime
from datetime import datetime

# ✅ IMPORTAR Base desde nuestro NUEVO database.py (que usa shared libraries)
try:
    from database import Base
    print("✅ Models.py: Base importada desde database.py")
except ImportError:
    # Fallback si database.py no está disponible
    from sqlalchemy.ext.declarative import declarative_base
    Base = declarative_base()
    print("⚠️ Models.py: Usando Base local (fallback)")

class User(Base):
    """Modelo de usuario para autenticación"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="patient", nullable=False)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, role={self.role})>"
    
    def to_dict(self):
        """Convertir usuario a diccionario"""
        return {
            "id": self.id,
            "email": self.email,
            "username": self.username,
            "full_name": self.full_name,
            "role": self.role,
            "is_active": self.is_active,
            "is_superuser": self.is_superuser,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
