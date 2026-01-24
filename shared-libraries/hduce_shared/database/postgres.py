import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from typing import Optional, Dict
from contextlib import contextmanager

from ..config.settings import settings

Base = declarative_base()

class DatabaseManager:
    """Manages PostgreSQL database connections for all services"""
    
    _engines: Dict[str, any] = {}
    _sessions: Dict[str, any] = {}
    
    @classmethod
    def get_engine(cls, service_name: str):
        """Get or create SQLAlchemy engine for specific service"""
        if service_name not in cls._engines:
            # Configuración específica por servicio
            db_config = {
                "auth": {
                    "database": settings.database.auth_db,
                    "schema": "public"
                },
                "users": {
                    "database": settings.database.user_db,
                    "schema": "public"
                },
                "appointments": {
                "database": settings.database.appointment_db,
                "schema": "public"
            },
            "notifications": {
                "database": settings.database.notification_db,
                "schema": "public"
            },
            "medical": {
                    "database": settings.database.appointment_db,
                    "schema": "public"
                },
                "medical": {
                    "database": settings.database.medical_db,
                    "schema": "public"
                }
            }
            
            config = db_config.get(service_name, db_config["auth"])
            
            connection_string = (
                f"postgresql://{settings.database.postgres_user}:"
                f"{settings.database.postgres_password}@"
                f"{settings.database.postgres_host}:{settings.database.postgres_port}/"
                f"{config['database']}"
            )
            
            cls._engines[service_name] = create_engine(
                connection_string,
                pool_pre_ping=True,
                pool_size=10,
                max_overflow=20,
                echo=False  # Cambiar a True para debugging
            )
            
            # Configurar schema si es diferente de public
            if config["schema"] != "public":
                from sqlalchemy.event import listen
                from sqlalchemy.pool import Pool
                
                def set_schema(dbapi_con, connection_record):
                    dbapi_con.cursor().execute(f"SET search_path TO {config['schema']}")
                
                listen(cls._engines[service_name], 'connect', set_schema)
        
        return cls._engines[service_name]
    
    @classmethod
    @contextmanager
    def get_session(cls, service_name: str):
        """Get database session with context manager for automatic cleanup"""
        engine = cls.get_engine(service_name)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        try:
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()

# Funciones de conveniencia
def get_db_session(service_name: str):
    """Convenience function to get database session context manager"""
    return DatabaseManager.get_session(service_name)

def get_db_engine(service_name: str):
    """Convenience function to get database engine"""
    return DatabaseManager.get_engine(service_name)

def create_all_tables(service_name: str):
    """Create all tables for a service"""
    engine = get_db_engine(service_name)
    Base.metadata.create_all(bind=engine)

# Modelos base compartidos
class TimestampMixin:
    """Mixin para agregar timestamps a los modelos"""
    from sqlalchemy import Column, DateTime
    from sqlalchemy.sql import func
    
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)

class SoftDeleteMixin:
    """Mixin para soft delete"""
    from sqlalchemy import Column, Boolean
    
    is_active = Column(Boolean, default=True, nullable=False)

