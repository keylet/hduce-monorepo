# backend/auth-service/database.py - VERSIÓN CON POSTGRESQL REAL
print("🔧 Configurando database para auth-service - POSTGRESQL")

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Configuración CORRECTA para PostgreSQL del docker-compose
DATABASE_URL = "postgresql://postgres:postgres@hduce-postgres:5432/auth_db"

print(f"📊 Conectando a PostgreSQL REAL: postgresql://postgres:***@hduce-postgres:5432/auth_db")

# Crear engine para PostgreSQL
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=300,
    echo=False  # Cambiar a True para debug
)

# SessionLocal para FastAPI
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para modelos
Base = declarative_base()

# DEPENDENCIA PARA FASTAPI
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
    """Crear tablas en PostgreSQL"""
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Tablas creadas en PostgreSQL para auth-service")
    except Exception as e:
        print(f"❌ Error creando tablas: {e}")
        raise

print("✅ Database configurado para PostgreSQL")

__all__ = ["get_db", "get_db_session_auth", "create_auth_tables", "Base", "SessionLocal"]
