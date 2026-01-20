#!/usr/bin/env python3
import sys
sys.path.append('/app')

from sqlalchemy import create_engine, text
import traceback

def main():
    try:
        print('1. Creando engine de conexión...')
        engine = create_engine('postgresql://postgres:postgres@postgres:5432/notification_db')
        
        print('2. Importando modelos...')
        from models import Base
        
        print('3. Creando tablas...')
        Base.metadata.create_all(bind=engine)
        print('✅ Tablas creadas exitosamente')
        
        print('4. Verificando tablas creadas...')
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name
            """))
            
            tables = [row[0] for row in result]
            print(f'Tablas encontradas: {tables}')
            
        print('✅ Base de datos notification_db configurada correctamente')
        
    except Exception as e:
        print(f'❌ Error al crear tablas: {e}')
        traceback.print_exc()

if __name__ == "__main__":
    main()
