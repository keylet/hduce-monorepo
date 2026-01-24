# Script de diagnóstico para notification-service
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

print("=== DIAGNÓSTICO NOTIFICATION-SERVICE ===")

# 1. Verificar imports
try:
    from models import Base
    print("? Models importado correctamente")
    print(f"   Base: {Base}")
    print(f"   Metadata tables: {list(Base.metadata.tables.keys())}")
except ImportError as e:
    print(f"? Error importando models: {e}")

# 2. Verificar database.py
try:
    from database import engine, create_tables
    print("? Database importado correctamente")
    
    # 3. Crear tablas
    print("Intentando crear tablas...")
    create_tables()
    
except ImportError as e:
    print(f"? Error importando database: {e}")
except Exception as e:
    print(f"? Error ejecutando diagnóstico: {e}")
    import traceback
    traceback.print_exc()
