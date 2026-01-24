#!/usr/bin/env python3
"""
Script de diagnostico para appointment-service
"""

import sys
import os
import logging

# Agregar paths
sys.path.append(os.path.join(os.path.dirname(__file__), 'shared-libraries'))

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

print("DIAGNOSTICO DE APPOINTMENT-SERVICE")
print("=" * 50)

try:
    # 1. Verificar importaciones
    print("\n1. Probando importaciones...")
    from hduce_shared.database import DatabaseManager
    print("   DatabaseManager importado")
    
    from hduce_shared.database import check_db_connection
    print("   check_db_connection importado")
    
    try:
        from hduce_shared.config.settings import get_settings
        print("   get_settings importado")
    except Exception as e:
        print(f"   get_settings importado: ERROR - {e}")
    
    # 2. Verificar variables de entorno
    print("\n2. Variables de entorno para 'appointments':")
    env_vars = ["DATABASE_URL", "DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD"]
    for var in env_vars:
        value = os.environ.get(f"APPOINTMENT_{var}") or os.environ.get(var)
        if value:
            if "PASSWORD" in var and value:
                print(f"   {var}: {'*' * len(value)}")
            else:
                print(f"   {var}: {value}")
        else:
            print(f"   {var}: NO DEFINIDA")
    
    # 3. Verificar la configuracion del DatabaseManager
    print("\n3. Verificando configuracion de DatabaseManager...")
    
    # Ver que configuracion tiene en postgres.py
    try:
        # Leer el archivo postgres.py para ver la config
        postgres_path = os.path.join(os.path.dirname(__file__), 'shared-libraries', 'hduce_shared', 'database', 'postgres.py')
        if os.path.exists(postgres_path):
            with open(postgres_path, 'r') as f:
                content = f.read()
                if 'settings.database.appointment_db' in content:
                    print("   Config encontrada para appointments en postgres.py")
                else:
                    print("   NO hay config para appointments en postgres.py")
                    
                # Buscar la estructura de config
                import re
                db_config_match = re.search(r'db_config\s*=\s*{([^}]+)}', content, re.DOTALL)
                if db_config_match:
                    print("   Estructura db_config encontrada")
    except Exception as e:
        print(f"   Error leyendo postgres.py: {e}")
    
    # 4. Probar DatabaseManager directamente
    print("\n4. Probando DatabaseManager.get_engine()...")
    
    services = ["appointments", "auth", "users", "notifications"]
    
    for service in services:
        try:
            print(f"\n   Probando servicio: {service}")
            
            # Intentar obtener el engine
            try:
                engine = DatabaseManager.get_engine(service)
                if engine:
                    print(f"      Engine obtenido: SI")
                    print(f"      URL: {engine.url}")
                    
                    # Probar conexion
                    from sqlalchemy import text
                    try:
                        with engine.connect() as conn:
                            result = conn.execute(text("SELECT 1"))
                            print(f"      Test SELECT 1: EXITOSA")
                            conn.commit()
                    except Exception as e:
                        print(f"      Test SELECT 1: FALLO - {e}")
                else:
                    print(f"      Engine obtenido: None (nulo)")
                    
            except Exception as e:
                print(f"      Engine obtenido: ERROR - {e}")
                
        except Exception as e:
            print(f"      Error general: {e}")
    
    print("\n" + "=" * 50)
    print("DIAGNOSTICO COMPLETADO")
    
except Exception as e:
    print(f"\nERROR GLOBAL: {e}")
    import traceback
    traceback.print_exc()
