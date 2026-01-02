# backend/user-service/database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# PostgreSQL connection URL
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://hduce_user:hduce_pass@localhost:5432/hduce_db"
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