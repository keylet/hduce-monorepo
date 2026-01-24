#!/usr/bin/env python3
"""
Script para sembrar datos iniciales usando shared libraries.
USO: python scripts/seed_data.py
"""
import sys
import os

# Configurar paths como lo hacen los servicios
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, "shared-libraries"))

import bcrypt
from sqlalchemy.orm import Session
from hduce_shared.database import DatabaseManager
from hduce_shared.config import settings

def seed_auth_data():
    """Sembrar datos en auth_db"""
    print("=== SEMBRANDO DATOS EN AUTH_DB ===")
    
    # Obtener sesión usando DatabaseManager (igual que los servicios)
    db_context = DatabaseManager.get_session("auth")
    db = db_context.__enter__()
    
    try:
        # 1. Primero, verificar si ya existe el usuario
        from sqlalchemy import text
        
        check_user = db.execute(text("SELECT id FROM users WHERE username = 'testuser'"))
        existing_user = check_user.fetchone()
        
        if existing_user:
            print(f"⚠️ Usuario testuser ya existe (ID: {existing_user[0]}). Eliminando...")
            db.execute(text("DELETE FROM users WHERE username = 'testuser'"))
            db.commit()
        
        # 2. Crear hash de contraseña
        password = "secret"
        hashed_password = bcrypt.hashpw(
            password.encode('utf-8'),
            bcrypt.gensalt(rounds=12)
        ).decode('utf-8')
        
        print(f"✅ Hash generado: {hashed_password[:30]}...")
        
        # 3. Insertar usuario
        insert_sql = text("""
            INSERT INTO users (email, username, full_name, hashed_password, role, is_active, is_superuser, created_at, updated_at)
            VALUES (:email, :username, :full_name, :hashed_password, :role, :is_active, :is_superuser, NOW(), NOW())
        """)
        
        db.execute(insert_sql, {
            'email': 'testuser@example.com',
            'username': 'testuser',
            'full_name': 'Usuario de Prueba',
            'hashed_password': hashed_password,
            'role': 'patient',
            'is_active': True,
            'is_superuser': False
        })
        
        db.commit()
        
        # 4. Verificar
        result = db.execute(text("""
            SELECT id, username, email, LENGTH(hashed_password) as hash_len
            FROM users WHERE username = 'testuser'
        """))
        user = result.fetchone()
        
        if user:
            print(f"✅ Usuario creado: ID={user[0]}, {user[1]}, Hash length={user[3]}")
        else:
            print("❌ Error: Usuario no creado")
            
    except Exception as e:
        db.rollback()
        print(f"❌ Error en auth_db: {e}")
        raise
    finally:
        db_context.__exit__(None, None, None)

def seed_appointment_data():
    """Sembrar datos en appointment_db"""
    print("\n=== SEMBRANDO DATOS EN APPOINTMENT_DB ===")
    
    # Obtener sesión para appointments
    db_context = DatabaseManager.get_session("appointments")
    db = db_context.__enter__()
    
    try:
        # 1. Crear especialidades
        specialties = [
            ('Cardiología', 'Especialidad en enfermedades del corazón'),
            ('Pediatría', 'Especialidad en cuidado infantil'),
            ('Dermatología', 'Especialidad en enfermedades de la piel'),
            ('Neurología', 'Especialidad en enfermedades del sistema nervioso'),
            ('Ortopedia', 'Especialidad en sistema musculoesquelético')
        ]
        
        print("Insertando especialidades...")
        for name, description in specialties:
            # Verificar si ya existe
            check = db.execute(
                text("SELECT id FROM specialties WHERE name = :name"),
                {'name': name}
            )
            
            if not check.fetchone():
                insert_spec = text("""
                    INSERT INTO specialties (name, description, created_at)
                    VALUES (:name, :description, NOW())
                """)
                db.execute(insert_spec, {'name': name, 'description': description})
        
        db.commit()
        
        # 2. Obtener IDs de especialidades
        spec_result = db.execute(text("SELECT id, name FROM specialties ORDER BY id"))
        specialties_dict = {name: id for id, name in spec_result.fetchall()}
        
        print(f"✅ {len(specialties_dict)} especialidades disponibles")
        
        # 3. Insertar doctores
        doctors = [
            ('doc_001', 'MED-12345', 'Dr. Juan Pérez', 'juan.perez@hospital.com', '+1-555-0101', 'Cardiología', 30),
            ('doc_002', 'MED-67890', 'Dra. María López', 'maria.lopez@hospital.com', '+1-555-0102', 'Pediatría', 45),
            ('doc_003', 'MED-54321', 'Dr. Carlos Gómez', 'carlos.gomez@hospital.com', '+1-555-0103', 'Dermatología', 30)
        ]
        
        print("Insertando doctores...")
        for user_id, license_num, name, email, phone, specialty_name, duration in doctors:
            # Verificar si ya existe
            check = db.execute(
                text("SELECT id FROM doctors WHERE license_number = :license"),
                {'license': license_num}
            )
            
            if not check.fetchone():
                specialty_id = specialties_dict.get(specialty_name)
                if specialty_id:
                    insert_doc = text("""
                        INSERT INTO doctors (user_id, license_number, name, email, phone, specialty_id, consultation_duration, created_at)
                        VALUES (:user_id, :license, :name, :email, :phone, :spec_id, :duration, NOW())
                    """)
                    db.execute(insert_doc, {
                        'user_id': user_id,
                        'license': license_num,
                        'name': name,
                        'email': email,
                        'phone': phone,
                        'spec_id': specialty_id,
                        'duration': duration
                    })
        
        db.commit()
        
        # 4. Verificar
        doc_count = db.execute(text("SELECT COUNT(*) FROM doctors")).fetchone()[0]
        spec_count = db.execute(text("SELECT COUNT(*) FROM specialties")).fetchone()[0]
        
        print(f"✅ {doc_count} doctores creados")
        print(f"✅ {spec_count} especialidades creadas")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error en appointment_db: {e}")
        raise
    finally:
        db_context.__exit__(None, None, None)

def main():
    """Función principal"""
    print("🚀 SEMBRADOR DE DATOS HDUCE (usando shared libraries)")
    print("=" * 50)
    
    try:
        seed_auth_data()
        seed_appointment_data()
        
        print("\n" + "=" * 50)
        print("✅ DATOS SEMBRADOS EXITOSAMENTE")
        print("\nResumen:")
        print("- Usuario: testuser / secret")
        print("- 5 especialidades médicas")
        print("- 3 doctores disponibles")
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
