# backend/notification-service/database.py
# ✅ VERSIÓN CORREGIDA - Crea su propia get_db_session

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator

# Configuración de la base de datos
DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/notification_db"

# Crear engine
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# Crear SessionLocal
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Función get_db para FastAPI (sin parámetros)
def get_db() -> Generator[Session, None, None]:
    """Dependency para FastAPI - versión SIMPLIFICADA"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Alias para compatibilidad
get_db_session = get_db  # ¡ESTA ES LA CLAVE! Sin parámetros

# Importar Base desde shared-libraries para modelos
try:
    from hduce_shared.database import Base, create_all_tables, TimestampMixin
    print("✅ Shared-libraries importado correctamente")
except ImportError:
    # Fallback si no hay shared-libraries
    from sqlalchemy.ext.declarative import declarative_base
    from sqlalchemy import Column, DateTime
    from datetime import datetime
    
    Base = declarative_base()
    
    class TimestampMixin:
        created_at = Column(DateTime, default=datetime.now)
        updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    def create_all_tables(engine):
        Base.metadata.create_all(bind=engine)
    
    print("⚠️ Usando versión local (shared-libraries no disponible)")
