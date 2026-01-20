# backend/notification-service/database.py
# ? VERSIÓN CORREGIDA - Usa Base de models.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator

# Importar Base de models.py
try:
    from models import Base
    print("? Base importada desde models.py")
except ImportError as e:
    print(f"? Error importando Base de models: {e}")
    from sqlalchemy.ext.declarative import declarative_base
    Base = declarative_base()

# Configuración de la base de datos
DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/notification_db"

# Crear engine
engine = create_engine(DATABASE_URL, pool_pre_ping=True)

# Crear SessionLocal
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Función get_db para FastAPI
def get_db() -> Generator[Session, None, None]:
    """Dependency para FastAPI"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Alias para compatibilidad
get_db_session = get_db

# Función para crear tablas
def create_tables():
    """Crear todas las tablas definidas en models.py"""
    try:
        print("?? Creando tablas en notification_db...")
        Base.metadata.create_all(bind=engine)
        print("? Tablas creadas exitosamente")
        
        # Verificar tablas creadas
        from sqlalchemy import inspect
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print(f"?? Tablas existentes: {tables}")
        
    except Exception as e:
        print(f"? Error creando tablas: {e}")
        import traceback
        print(traceback.format_exc())
