import sys
print("=== ANÁLISIS DE IMPORTS ===")

# Rutas importantes
paths = [
    r"C:\Users\raich\Desktop\hduce-monorepo\shared-libraries\hduce_shared",
    r"C:\Users\raich\Desktop\hduce-monorepo\backend\auth-service",
    r"C:\Users\raich\Desktop\hduce-monorepo\backend\user-service"
]

for p in paths:
    if p not in sys.path:
        sys.path.insert(0, p)

# Intentar importar módulos clave
modules_to_try = [
    "auth.jwt_utils",
    "config.settings", 
    "database.models",
    "users.schemas"
]

for module in modules_to_try:
    try:
        imported = __import__(module)
        print(f"✅ {module}: {imported}")
    except Exception as e:
        print(f"❌ {module}: {type(e).__name__}")
