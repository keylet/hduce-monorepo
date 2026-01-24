print("=== DIAGNÓSTICO COMPLETO DEL SISTEMA ===\n")

# 1. Verificar sys.path
import sys
print("1. Sys.path:")
for path in sys.path:
    print(f"   - {path}")

# 2. Verificar imports
print("\n2. Intentando importar módulos:")
try:
    from hduce_shared import config
    print("   ✅ hduce_shared.config importado")
    print(f"   SECRET_KEY: {config.SECRET_KEY[:20]}...")
except ImportError as e:
    print(f"   ❌ Error importando hduce_shared.config: {e}")

try:
    from database import SessionLocal
    print("   ✅ database.SessionLocal importado")
except ImportError as e:
    print(f"   ❌ Error importando database: {e}")

# 3. Verificar variables de entorno
import os
print("\n3. Variables de entorno relevantes:")
env_vars = ["DATABASE_URL", "DB_HOST", "DB_PORT", "DB_NAME", "DB_USER"]
for var in env_vars:
    value = os.getenv(var, "NO DEFINIDA")
    print(f"   {var}: {value}")

# 4. Verificar estructura del endpoint login
print("\n4. Verificando esquema UserLogin:")
try:
    from schemas import UserLogin
    print("   ✅ UserLogin importado")
    print(f"   Campos: {UserLogin.__fields__.keys()}")
except Exception as e:
    print(f"   ❌ Error: {e}")
