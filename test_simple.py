import sys
sys.path.append('/app/shared-libraries')

print("=== PRUEBA SIMPLE ===")

# 1. Verificar configuración
from hduce_shared.config import settings
db = settings.database
print(f"User: {db.postgres_user}")
print(f"Password length: {len(db.postgres_password)}")
print(f"Password: '{db.postgres_password}'")

# 2. Probar conexión directa
print("\n=== Probando conexión ===")
try:
    import psycopg2
    conn = psycopg2.connect(
        host=db.postgres_host,
        port=db.postgres_port,
        user=db.postgres_user,
        password=db.postgres_password,
        database=db.auth_db
    )
    print("✅ CONEXIÓN EXITOSA")
    conn.close()
except Exception as e:
    print(f"❌ ERROR: {e}")
