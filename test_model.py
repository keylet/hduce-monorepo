import sys
import os

# Añadir rutas necesarias
sys.path.append(".")
sys.path.append("shared-libraries")
sys.path.append("backend/auth-service")

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from hduce_shared.config import settings

# Crear engine directamente
connection_string = f"postgresql://{settings.database.postgres_user}:{settings.database.postgres_password}@{settings.database.postgres_host}:{settings.database.postgres_port}/{settings.database.auth_db}"
engine = create_engine(connection_string)

# Importar usando importlib para manejar el guión
import importlib.util
spec = importlib.util.spec_from_file_location("database", "backend/auth-service/database.py")
database_module = importlib.util.module_from_spec(spec)
sys.modules["database"] = database_module
spec.loader.exec_module(database_module)

User = database_module.User

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

try:
    # Buscar usuario
    user = db.query(User).filter(User.email == "test@hduce.com").first()
    print(f"Usuario encontrado: {user.email if user else 'No encontrado'}")
    print(f"Columnas del modelo: {[col.name for col in User.__table__.columns]}")
    
    # Verificar longitud de columnas
    for col in User.__table__.columns:
        if hasattr(col.type, 'length'):
            print(f"  {col.name}: {col.type.length}")
        else:
            print(f"  {col.name}: {col.type}")
            
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
