import sys
sys.path.append('/app/shared-libraries')

print("=== DIAGNÓSTICO AVANZADO ===")

# 1. Verificar TODAS las variables de entorno relacionadas
import os
print("1. Variables de entorno POSTGRES_*:")
for key, value in os.environ.items():
    if 'POSTGRES' in key or 'PASSWORD' in key or 'DB' in key:
        print(f"   {key}: {value}")

print("\n2. Configuración desde settings:")
from hduce_shared.config import settings
db = settings.database
print(f"   postgres_user: '{db.postgres_user}'")
print(f"   postgres_password: '{db.postgres_password}'")
print(f"   postgres_password length: {len(db.postgres_password)}")
print(f"   postgres_password repr: {repr(db.postgres_password)}")

# 3. Verificar si hay caracteres especiales
print("\n3. Análisis de contraseña:")
password = db.postgres_password
print(f"   ASCII codes: {[ord(c) for c in password]}")
print(f"   Is printable: {password.isprintable()}")
print(f"   Contains newline: {'\\n' in password}")
print(f"   Contains return: {'\\r' in password}")

# 4. Probar conexión con la contraseña LITERAL
print("\n4. Probando conexión con contraseña literal 'postgres':")
try:
    import psycopg2
    conn = psycopg2.connect(
        host=db.postgres_host,
        port=db.postgres_port,
        user=db.postgres_user,
        password='postgres',  # ¡Literal!
        database=db.auth_db
    )
    print("   ✅ CONECTA con 'postgres' literal")
    conn.close()
except Exception as e:
    print(f"   ❌ NO conecta con 'postgres' literal: {e}")
