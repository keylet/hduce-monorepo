import sys
sys.path.insert(0, '/app')
from hduce_shared.database import DatabaseManager
from hduce_shared.config import settings

print("=== DIAGNÓSTICO COMPLETO ===")
print(f"1. Servicio: appointment")
print(f"2. Configuración esperada: {settings.database.appointment_db}")

# Obtener engine directamente
engine = DatabaseManager.get_engine("appointment")
print(f"3. URL de conexión: {engine.url}")

# Verificar conexión directa
context_manager = DatabaseManager.get_session("appointment")
db = context_manager.__enter__()

try:
    # Verificar base de datos actual
    result = db.execute("SELECT current_database()")
    current_db = result.fetchone()[0]
    print(f"4. Base de datos conectada actualmente: {current_db}")
    
    # Verificar si es la correcta
    if current_db != "appointment_db":
        print(f"❌ ERROR: Conectado a {current_db} en lugar de appointment_db")
    
    # Verificar todos los doctores en esta conexión
    result = db.execute("SELECT id, name FROM doctors ORDER BY id LIMIT 5")
    doctors = result.fetchall()
    
    if doctors:
        print(f"5. Doctores encontrados en {current_db}: {len(doctores)}")
        for doc in doctors:
            print(f"   - ID {doc[0]}: {doc[1]}")
    else:
        print(f"5. No hay doctores en {current_db}")
        
    # Verificar todas las tablas
    result = db.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name
    """)
    tables = result.fetchall()
    print(f"6. Tablas en {current_db}: {[t[0] for t in tables]}")
    
finally:
    context_manager.__exit__(None, None, None)
