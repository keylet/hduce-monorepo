# Script para verificar conexión a BD
import sys
sys.path.append('.')
from database import SessionLocal, engine
from sqlalchemy import text

try:
    # Probar conexión a PostgreSQL
    with engine.connect() as conn:
        result = conn.execute(text('SELECT 1 as test'))
        print(f"✅ Conexión a PostgreSQL OK: {result.fetchone()[0]}")
    
    # Probar SessionLocal
    db = SessionLocal()
    try:
        result = db.execute(text('SELECT COUNT(*) FROM notifications'))
        count = result.scalar()
        print(f"✅ Tabla notifications tiene {count} registros")
    finally:
        db.close()
        
except Exception as e:
    print(f"❌ Error conectando a PostgreSQL: {e}")
    import traceback
    traceback.print_exc()
