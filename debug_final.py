import sys
sys.path.insert(0, '/app')
from hduce_shared.database import DatabaseManager
from sqlalchemy import text

print("=== VERIFICACIÓN FINAL DE CONEXIÓN ===")

# 1. Verificar que appointment-service vea los doctores
with DatabaseManager.get_session("appointments") as db:
    # Verificar base de datos
    result = db.execute(text("SELECT current_database()"))
    current_db = result.fetchone()[0]
    print(f"1. Base de datos: {current_db}")
    
    # Contar doctores
    result = db.execute(text("SELECT COUNT(*) FROM doctors"))
    doctor_count = result.fetchone()[0]
    print(f"2. Total doctores en {current_db}: {doctor_count}")
    
    if doctor_count > 0:
        # Ver doctor específico con ID 1
        result = db.execute(text("SELECT id, name, email FROM doctors WHERE id = 1"))
        doctor = result.fetchone()
        if doctor:
            print(f"3. Doctor ID 1 encontrado: {doctor[1]} ({doctor[2]})")
            
            # Verificar estructura de tabla doctors
            result = db.execute(text("""
                SELECT column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name = 'doctors' 
                ORDER BY ordinal_position
            """))
            columns = result.fetchall()
            print(f"4. Columnas de tabla doctors:")
            for col in columns:
                print(f"   - {col[0]}: {col[1]}")
        else:
            print("3. ❌ Doctor ID 1 NO encontrado (pero hay otros doctores)")
    else:
        print("3. ❌ NO HAY DOCTORES en la base de datos")
        
    # Verificar también la tabla appointments
    result = db.execute(text("SELECT COUNT(*) FROM appointments"))
    appointment_count = result.fetchone()[0]
    print(f"5. Total citas existentes: {appointment_count}")
