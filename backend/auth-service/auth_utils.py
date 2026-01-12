from passlib.context import CryptContext

# Configurar bcrypt con passlib
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash"""
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception:
        # Si falla la verificaci?n, retornar False
        return False

def get_password_hash(password: str) -> str:
    """Generate password hash"""
    return pwd_context.hash(password)
