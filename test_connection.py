import sys
sys.path.append('.')
try:
    from database import SessionLocal, engine
    print("✅ database.py importado correctamente")
    
    # Probar conexión
    from sqlalchemy import text
    with engine.connect() as conn:
        result = conn.execute(text("SELECT current_database(), current_user"))
        db_info = result.fetchone()
        print(f"✅ Conectado a: {db_info[0]} como {db_info[1]}")
        
        # Verificar tablas
        result = conn.execute(text("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"))
        tables = result.fetchall()
        print(f"✅ Tablas en la base de datos: {[t[0] for t in tables]}")
        
except Exception as e:
    print(f"❌ Error: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
