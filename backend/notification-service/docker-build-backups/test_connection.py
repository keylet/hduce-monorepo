import sys
import os
sys.path.insert(0, '/app')

from hduce_shared.database import DatabaseManager
from sqlalchemy import text

print("=== TEST DE CONEXIÓN A NOTIFICATION_DB ===")

try:
    # Obtener engine
    engine = DatabaseManager.get_engine("notification")
    print(f"✅ Engine obtenido: {engine}")
    
    # Probar conexión
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print(f"✅ Conexión exitosa: {result.fetchone()}")
        
        # Verificar tabla
        result = conn.execute(text("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications')"))
        table_exists = result.fetchone()[0]
        print(f"✅ Tabla notifications existe: {table_exists}")
        
        if table_exists:
            # Verificar estructura
            result = conn.execute(text("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'notifications' ORDER BY ordinal_position"))
            print("📊 Estructura de tabla notifications:")
            for row in result:
                print(f"  {row[0]}: {row[1]} (nullable: {row[2]})")
        
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    print(traceback.format_exc())
