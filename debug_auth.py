import sys
sys.path.append("shared-libraries")

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.auth-service.database import get_auth_engine, User
from backend.auth-service.auth_utils import authenticate_user

# Crear sesión
engine = get_auth_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

try:
    # Buscar usuario test@hduce.com
    user = db.query(User).filter(User.email == "test@hduce.com").first()
    print(f"Usuario encontrado: {user}")
    print(f"Username: {user.username if user else 'No encontrado'}")
    print(f"Email: {user.email if user else 'No encontrado'}")
    print(f"Password hash: {user.hashed_password if user else 'No encontrado'}")
    
    # Probar autenticación
    if user:
        from backend.auth-service.auth_utils import verify_password
        is_valid = verify_password("test123", user.hashed_password)
        print(f"Password válido: {is_valid}")
        
        auth_result = authenticate_user(db, "test@hduce.com", "test123")
        print(f"Resultado autenticación: {auth_result}")
        
except Exception as e:
    print(f"Error: {type(e).__name__}: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
