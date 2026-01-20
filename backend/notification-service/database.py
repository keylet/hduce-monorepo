"""
Database configuration 100% usando shared libraries
Compatibilidad total con notification-service - CORREGIDO DEFINITIVAMENTE
"""

from hduce_shared.database import DatabaseManager
from sqlalchemy.orm import sessionmaker, Session

# Service name debe coincidir con el nombre de la base de datos
SERVICE_NAME = "notifications"

# Obtener engine desde DatabaseManager
engine = DatabaseManager.get_engine(SERVICE_NAME)

# Crear SessionLocal CORRECTAMENTE usando sessionmaker
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Función para crear tablas
def create_tables():
    """Create all tables if they don't exist"""
    from models import Base
    Base.metadata.create_all(bind=engine)
    return True

# Dependencia para FastAPI - CORREGIDA
def get_db() -> Session:
    """Dependency to get database session for FastAPI routes"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
