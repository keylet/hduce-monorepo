import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

print("=== TEST DE IMPORTS ===")
try:
    import routes
    print("✅ routes.py importable")
    
    # Verificar qué hay en routes
    print(f"Router: {hasattr(routes, 'router')}")
    if hasattr(routes, 'router'):
        print(f"Router prefix: {routes.router.prefix}")
except Exception as e:
    print(f"❌ Error importando routes.py: {e}")
    import traceback
    traceback.print_exc()

print("\n=== TEST DE DATABASE IMPORTS ===")
try:
    from database import get_db, User
    print("✅ database.py importable")
    
    # Probar crear sesión
    try:
        db_gen = get_db()
        db = next(db_gen)
        user_count = db.query(User).count()
        print(f"✅ Conexión a BD OK - Usuarios: {user_count}")
    except Exception as e:
        print(f"❌ Error en conexión BD: {e}")
        
except Exception as e:
    print(f"❌ Error importando database.py: {e}")

print("\n=== TEST DE AUTH_UTILS IMPORTS ===")
try:
    from auth_utils import verify_password, get_password_hash
    print("✅ auth_utils.py importable")
    
    # Probar hash/verify
    test_hash = get_password_hash("test123")
    print(f"✅ Hash generado: {test_hash[:20]}...")
except Exception as e:
    print(f"❌ Error importando auth_utils.py: {e}")
