from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# URL de conexión a la base de datos (usando variable de entorno)
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://hduce_user:hduce_pass@localhost:5432/hduce_db")

# Crear el motor de SQLAlchemy
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# Crear SessionLocal
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base para los modelos
Base = declarative_base()

# Dependencia para obtener la sesión de base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
