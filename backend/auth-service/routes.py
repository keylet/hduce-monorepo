# backend/auth-service/routes.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

# ✅ CORREGIDO: Router con prefix "/auth" para consistencia
router = APIRouter(prefix="/auth", tags=["authentication"])

users_db = {}

class UserRegister(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

# ========== ENDPOINTS CORREGIDOS ==========

@router.post("/register")
async def register(user: UserRegister):
    """Registro de usuario"""
    if user.username in users_db:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    import hashlib
    hashed = hashlib.md5(user.password.encode()).hexdigest()
    
    users_db[user.username] = {
        "username": user.username,
        "email": user.email,
        "hashed_password": hashed,
        "type": "hashed"
    }
    
    return {
        "message": "✅ Registro exitoso",
        "user": user.username
    }

@router.post("/login")
async def login(user: UserLogin):
    """Login de usuario"""
    if user.username not in users_db:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")
    
    db_user = users_db[user.username]
    
    import hashlib
    hashed_input = hashlib.md5(user.password.encode()).hexdigest()
    
    if db_user.get("type") == "hashed":
        if db_user["hashed_password"] != hashed_input:
            raise HTTPException(status_code=401, detail="Contraseña incorrecta")
    else:
        if db_user.get("password") != user.password:
            raise HTTPException(status_code=401, detail="Contraseña incorrecta")
    
    import time
    token = f"token_{user.username}_{int(time.time())}"
    
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "username": user.username,
            "email": db_user.get("email", "")
        }
    }

@router.get("/test")
async def test():
    return {"message": "✅ Auth router funciona"}

@router.get("/users")
async def list_users():
    return {
        "total": len(users_db),
        "users": list(users_db.keys())
    }

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "auth-service"}