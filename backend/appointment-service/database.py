"""
Database configuration for Appointment Service - Using Shared Libraries
"""
import sys
import os


sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, '/app')  # For Docker

from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager


from hduce_shared.database import Base, DatabaseManager, create_all_tables
from hduce_shared.config import settings

print("?? Configurando appointment-service database con shared libraries...")


SERVICE_NAME = "appointments"



def get_db():
    """
    FastAPI dependency for appointment-service
    Returns a SQLAlchemy session
    """
   
    context_manager = DatabaseManager.get_session(SERVICE_NAME)
    
 
    db = context_manager.__enter__()
    
    try:
        yield db
    finally:
      
        context_manager.__exit__(None, None, None)

@contextmanager
def get_db_context():
    """Alternative context manager"""
    with DatabaseManager.get_session(SERVICE_NAME) as db:
        yield db


get_db_session_appointment = lambda: DatabaseManager.get_session(SERVICE_NAME)


def get_engine():
    """Get SQLAlchemy engine for this service"""
    return DatabaseManager.get_engine(SERVICE_NAME)


def create_tables():
    """Create tables for appointment-service"""
    try:
        create_all_tables(SERVICE_NAME)
        print(f"? Tables created for service: {SERVICE_NAME}")
        return True
    except Exception as e:
        print(f"? Error creating tables: {e}")
        raise

print(f"?? Appointment-service configured to use shared libraries")
print(f"?? Service: {SERVICE_NAME}, Database: {settings.database.appointment_db}")

# Export
__all__ = ["get_db", "get_db_context", "get_db_session_appointment", "get_engine", "create_tables", "Base"]

