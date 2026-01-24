from hduce_shared.config import settings
from database import get_auth_engine

print("Probando database.py corregido...")
print(f"User: {settings.database.postgres_user}")
print(f"Password configurada: {'SÍ' if settings.database.postgres_password else 'NO'}")

try:
    engine = get_auth_engine()
    print("✅ Engine creado exitosamente")
    
    with engine.connect() as conn:
        print("✅ Conexión a auth_db exitosa!")
        # Intentar crear tabla si no existe
        conn.execute("CREATE TABLE IF NOT EXISTS test_connection (id SERIAL PRIMARY KEY, test TEXT)")
        print("✅ Tabla de prueba creada/verificada")
        
except Exception as e:
    print(f"❌ Error: {type(e).__name__}: {e}")
