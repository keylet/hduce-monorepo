import sys
sys.path.append('/app/shared-libraries')

print("=== PRUEBA DatabaseManager ===")

try:
    from hduce_shared.database import DatabaseManager
    
    print("1. Obteniendo engine para 'auth'...")
    engine = DatabaseManager.get_engine('auth')
    
    print(f"2. URL: {engine.url}")
    
    print("3. Probando conexión...")
    with engine.connect() as conn:
        result = conn.execute('SELECT 1 as test')
        print(f"✅ CONEXIÓN EXITOSA: {result.fetchone()}")
        
except Exception as e:
    print(f"❌ ERROR: {e}")
    import traceback
    traceback.print_exc()
