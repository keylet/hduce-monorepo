#!/usr/bin/env python3
"""
Test simple de conexion a base de datos
"""
import sys
import os

# Agregar path
sys.path.append(os.path.join(os.path.dirname(__file__), 'shared-libraries'))

try:
    print("Testing database connection...")
    
    # Importar directamente
    from sqlalchemy import create_engine, text
    
    # URL directa de appointment_db
    db_url = "postgresql://postgres:postgres@localhost:5432/appointment_db"
    
    print(f"Connecting to: {db_url}")
    
    # Crear engine directamente
    engine = create_engine(db_url)
    
    # Probar conexion
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print(f"Direct connection SUCCESS! Result: {result.fetchone()}")
        conn.commit()
    
    # Ahora probar con DatabaseManager
    print("\nNow testing DatabaseManager...")
    
    from hduce_shared.database import DatabaseManager
    
    # Probar cada servicio
    for service in ["appointments", "auth", "users", "notifications"]:
        print(f"\nTesting {service}:")
        try:
            engine = DatabaseManager.get_engine(service)
            if engine:
                print(f"  Engine obtained: {engine.url}")
                with engine.connect() as conn:
                    result = conn.execute(text("SELECT 1"))
                    print(f"  Connection test: SUCCESS")
                    conn.commit()
            else:
                print(f"  Engine: None (not created)")
        except Exception as e:
            print(f"  Error: {e}")
    
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
