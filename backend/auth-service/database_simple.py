# backend/auth-service/database.py - VERSIÓN SIMPLE Y FUNCIONAL
print("🔧 Configurando database SIMPLE para auth-service")

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Configuración directa - SIN shared libraries
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@hduce-postgres:5432/auth_db")

print(f"📊 Conectando a PostgreSQL: {DATABASE_URL.split('@')[1] if '@' in DATABASE_URL else DATABASE_URL}")

# Crear engine
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# SessionLocal para FastAPI
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para modelos
Base = declarative_base()

# DEPENDENCIA PARA FASTAPI - GENERADOR SIMPLE
def get_db():
    """Generador para FastAPI Depends"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Alias
def get_db_session_auth():
    return SessionLocal()

# Crear tablas
def create_auth_tables():
    Base.metadata.create_all(bind=engine)
    print("✅ Tablas creadas para auth-service")

print("✅ Database configurado (versión simple)")

__all__ = ["get_db", "get_db_session_auth", "create_auth_tables", "Base", "SessionLocal"]
