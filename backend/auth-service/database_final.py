# backend/auth-service/database.py - IMPLEMENTACIÓN DIRECTA
print("🔧 Configurando auth-service database - IMPLEMENTACIÓN DIRECTA")

import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from contextlib import contextmanager

# Configuración de la base de datos
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@hduce-postgres:5432/auth_db")

print(f"📊 Conectando a: {DATABASE_URL.split('@')[1] if '@' in DATABASE_URL else DATABASE_URL}")

# Crear engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=300
)

# Crear SessionLocal
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para modelos
Base = declarative_base()

# Función get_db para FastAPI
@contextmanager
def get_db() -> Session:
    """Context manager para sesiones de base de datos - FastAPI compatible"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Alias para compatibilidad
def get_db_session_auth():
    """Alias para get_db"""
    return get_db()

# Crear tablas
def create_auth_tables():
    """Crear todas las tablas"""
    Base.metadata.create_all(bind=engine)
    print("✅ Tablas creadas para auth-service")

print("✅ Configuración de database completada")

# Exportar
__all__ = ["get_db", "get_db_session_auth", "create_auth_tables", "Base", "SessionLocal"]
