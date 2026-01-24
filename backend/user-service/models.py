from sqlalchemy import Column, String, Integer, DateTime, inspect
from sqlalchemy.sql import func
import sys

print("=== DIAGNÓSTICO DE MODELS.PY ===")
print("Python version:", sys.version)
print("SQLAlchemy path:", sys.modules.get('sqlalchemy'))

# Importar Base desde shared libraries
try:
    from hduce_shared.database.base import Base
    print("✅ Usando Base de shared libraries")
except ImportError as e:
    print(f"❌ Error importando shared Base: {e}")
    # Fallback si no hay shared libraries
    from sqlalchemy.ext.declarative import declarative_base
    Base = declarative_base()
    print("⚠️ Usando Base local (fallback)")

class User(Base):
    __tablename__ = "users"
    print(f"Definiendo tabla: {__tablename__}")

    # CORRECCIÓN: Usar Integer como la tabla real (no UUID)
    id = Column(Integer, primary_key=True, autoincrement=True)
    print(f"  id: Integer, primary_key=True, autoincrement=True")
    
    name = Column(String(255))
    email = Column(String(255), unique=True, nullable=False, index=True)
    age = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=func.now())
    updated_at = Column(DateTime(timezone=True), default=func.now(), onupdate=func.now())

    def __repr__(self):
        return f"<User(id={self.id}, name='{self.name}', email='{self.email}')>"

print("=== FIN DIAGNÓSTICO ===")
