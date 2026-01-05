# backend/user-service/database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# ✅ CORREGIDO: Cambiar localhost por postgres (nombre del servicio Docker)
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://hduce_user:hduce_pass@postgres:5432/hduce_db"  # <-- postgres, no localhost
)

# Create SQLAlchemy engine
engine = create_engine(DATABASE_URL)

# SessionLocal for database interactions
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base for models
Base = declarative_base()

# FastAPI dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()