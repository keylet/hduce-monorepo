import sys
import os

# Añadir rutas necesarias
sys.path.insert(0, '/app')
sys.path.insert(0, '/app/backend/notification_service')

try:
    from sqlalchemy import create_engine
    
    # URL de conexión
    DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/notification_db"
    engine = create_engine(DATABASE_URL)
    
    print("1. Engine creado ✅")
    
    # Probar conexión
    with engine.connect() as conn:
        conn.execute("SELECT 1")
    print("2. Conexión a PostgreSQL exitosa ✅")
    
    # Importar Base desde shared-libraries
    try:
        from hduce_shared.database import Base
        print("3. Base importada desde shared-libraries ✅")
    except ImportError as e:
        print(f"3. Error importando Base: {e}")
        # Crear Base localmente
        from sqlalchemy.ext.declarative import declarative_base
        Base = declarative_base()
        print("3. Base creada localmente ✅")
    
    # Importar modelos - IMPORTANTE: usar la ruta correcta
    try:
        # Intentar importar como módulo
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "models", 
            "/app/backend/notification_service/models.py"
        )
        models = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(models)
        print("4. Modelos importados directamente ✅")
        
        # Registrar modelos con Base
        for name in dir(models):
            obj = getattr(models, name)
            if hasattr(obj, '__table__') and hasattr(obj, '__tablename__'):
                print(f"   - Modelo encontrado: {obj.__tablename__}")
        
    except Exception as e:
        print(f"4. Error importando modelos: {e}")
        import traceback
        traceback.print_exc()
        # Crear modelo simple
        from sqlalchemy import Column, Integer, String, Text, DateTime, Enum
        import enum
        
        class NotificationType(str, enum.Enum):
            EMAIL = "email"
            IN_APP = "in_app"
        
        class NotificationStatus(str, enum.Enum):
            SENT = "sent"
            PENDING = "pending"
        
        class Notification(Base):
            __tablename__ = "notifications"
            
            id = Column(Integer, primary_key=True, index=True)
            user_id = Column(String, nullable=False, index=True)
            notification_type = Column(String(20), nullable=False)
            status = Column(String(20), default="sent")
            subject = Column(String(255))
            message = Column(Text, nullable=False)
            appointment_id = Column(Integer)
            sent_at = Column(DateTime)
            created_at = Column(DateTime, default=datetime.datetime.now)
        
        print("4. Modelo simple creado ✅")
    
    # Crear tablas
    print("5. Creando tablas...")
    Base.metadata.create_all(bind=engine)
    print("6. Tablas creadas exitosamente ✅")
    
except Exception as e:
    print(f"❌ Error general: {e}")
    import traceback
    traceback.print_exc()
