# -*- coding: utf-8 -*-

# backend/user-service/database.py - VERSIÓN SIMPLIFICADA
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os

# Configuración de la base de datos
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    f"postgresql://{os.getenv('POSTGRES_USER', 'postgres')}:{os.getenv('POSTGRES_PASSWORD', 'postgres')}@{os.getenv('POSTGRES_HOST', 'localhost')}:{os.getenv('POSTGRES_PORT', '5432')}/{os.getenv('USER_DB', 'user_db')}"
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    """Dependency for getting DB session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Crea todas las tablas en la base de datos"""
    # Importar aquí para evitar importación circular
    # Usar import absoluto en lugar de relativo
    import sys
    import os
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    
    from models import Base  # Ahora debería funcionar
    
    print("Creando tablas en la base de datos...")
    Base.metadata.create_all(bind=engine)
    print("Tablas creadas exitosamente")
    
    # Verificar tablas creadas
    from sqlalchemy import inspect
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"Tablas existentes en user_db: {tables}")
