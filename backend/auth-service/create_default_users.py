#!/usr/bin/env python3
"""
Script para crear usuarios por defecto en la base de datos auth_db
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from database import get_auth_engine, User
from sqlalchemy.orm import sessionmaker
from auth_utils import get_password_hash
from datetime import datetime

def create_default_users():
    """Crear usuarios por defecto"""
    engine = get_auth_engine()
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    
    try:
        # Lista de usuarios por defecto
        default_users = [
            {
                "email": "doctor@hospital.com",
                "username": "doctor",
                "password": "Doctor123!",
                "full_name": "Dr. John Smith",
                "role": "doctor",
                "phone": "+593987654321",
                "city": "Quito",
                "country": "Ecuador"
            },
            {
                "email": "patient@hospital.com",
                "username": "patient",
                "password": "Patient123!",
                "full_name": "Maria Garcia",
                "role": "patient",
                "phone": "+593912345678",
                "city": "Guayaquil",
                "country": "Ecuador"
            },
            {
                "email": "nurse@hospital.com",
                "username": "nurse",
                "password": "Nurse123!",
                "full_name": "Ana Lopez",
                "role": "nurse",
                "phone": "+593923456789",
                "city": "Cuenca",
                "country": "Ecuador"
            }
        ]
        
        created_count = 0
        for user_data in default_users:
            # Verificar si el usuario ya existe
            existing_user = db.query(User).filter(User.email == user_data["email"]).first()
            if not existing_user:
                # Crear usuario
                hashed_password = get_password_hash(user_data["password"])
                user = User(
                    email=user_data["email"],
                    username=user_data["username"],
                    hashed_password=hashed_password,
                    full_name=user_data["full_name"],
                    role=user_data["role"],
                    phone=user_data["phone"],
                    city=user_data["city"],
                    country=user_data["country"],
                    is_active=True,
                    is_verified=True,
                    last_login=datetime.utcnow()
                )
                db.add(user)
                created_count += 1
                print(f"✅ Created user: {user_data['email']} ({user_data['role']})")
            else:
                print(f"⚠️ User already exists: {user_data['email']}")
        
        db.commit()
        print(f"\n🎉 Created {created_count} default users")
        
    except Exception as e:
        print(f"❌ Error creating default users: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_default_users()