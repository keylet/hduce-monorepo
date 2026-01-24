# backend/user-service/database.py
# ✅ ACTUALIZADO para usar shared-libraries
from sqlalchemy import Column, String, Integer
from sqlalchemy.dialects.postgresql import UUID
import uuid

# Importar Base desde shared-libraries
from hduce_shared.database import Base, TimestampMixin

class UserDB(Base, TimestampMixin):
    """User model for user-service"""
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    age = Column(Integer, nullable=True)
    
    # TimestampMixin ya proporciona created_at y updated_at automáticamente
    
    def __repr__(self):
        return f"<User(name='{self.name}', email='{self.email}')>"
