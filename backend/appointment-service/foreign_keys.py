from sqlalchemy import text
from database import engine

def create_foreign_keys():
    """Crear foreign keys después de que todas las tablas existan"""
    with engine.connect() as conn:
        # Agregar foreign key para doctors.user_id -> users.id
        try:
            conn.execute(text("""
                ALTER TABLE doctors 
                ADD CONSTRAINT fk_doctors_user_id 
                FOREIGN KEY (user_id) REFERENCES users(id)
            """))
            print("Foreign key doctors.user_id creada")
        except Exception as e:
            print(f"Error creando foreign key doctors.user_id: {e}")
        
        # Agregar foreign key para appointments.patient_id -> users.id
        try:
            conn.execute(text("""
                ALTER TABLE appointments 
                ADD CONSTRAINT fk_appointments_patient_id 
                FOREIGN KEY (patient_id) REFERENCES users(id)
            """))
            print("Foreign key appointments.patient_id creada")
        except Exception as e:
            print(f"Error creando foreign key appointments.patient_id: {e}")
        
        conn.commit()

if __name__ == "__main__":
    create_foreign_keys()
