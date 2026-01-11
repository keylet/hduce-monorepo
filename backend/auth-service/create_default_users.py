#!/usr/bin/env python3
import sys
sys.path.append(".")

from database import get_auth_engine, User
from auth_utils import hash_password
from sqlalchemy.orm import sessionmaker
from datetime import datetime

def create_default_users():
    """Crear usuarios por defecto para pruebas"""
    engine = get_auth_engine()
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    
    try:
        # Verificar si ya existe admin
        admin = db.query(User).filter(User.username == "admin").first()
        if not admin:
            # Crear usuario admin
            admin_user = User(
                username="admin",
                email="admin@hduce.com",
                hashed_password=hash_password("admin123"),
                full_name="Administrador HDUCE",
                role="admin",
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.add(admin_user)
            print("✅ Usuario admin creado: admin / admin123")
        
        # Verificar si ya existe paciente de prueba
        patient = db.query(User).filter(User.username == "paciente").first()
        if not patient:
            # Crear usuario paciente
            patient_user = User(
                username="paciente",
                email="paciente@hduce.com",
                hashed_password=hash_password("paciente123"),
                full_name="Paciente de Prueba",
                role="patient",
                is_active=True,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.add(patient_user)
            print("✅ Usuario paciente creado: paciente / paciente123")
        
        db.commit()
        print("✅ Usuarios por defecto creados exitosamente")
        
    except Exception as e:
        print(f"❌ Error creando usuarios: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_default_users()
