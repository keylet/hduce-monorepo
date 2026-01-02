from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()
users_db = {}

class UserRegister(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

# ========== ENDPOINTS CORREGIDOS ==========

@router.post("/simple-register")
async def simple_register(user: UserRegister):
    """Registro simple - YA SABEMOS QUE FUNCIONA"""
    if user.username in users_db:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    users_db[user.username] = {
        "username": user.username,
        "email": user.email,
        "password": user.password
    }
    
    return {
        "message": "✅ Registro simple exitoso",
        "user": user.username,
        "email": user.email
    }

@router.post("/register")
async def register(user: UserRegister):
    """Registro normal - VERSIÓN CORREGIDA"""
    try:
        if user.username in users_db:
            raise HTTPException(status_code=400, detail="Username already exists")
        
        # Hash simple SIN dependencias externas
        import hashlib
        hashed = hashlib.md5(user.password.encode()).hexdigest()
        
        users_db[user.username] = {
            "username": user.username,
            "email": user.email,
            "hashed_password": hashed,
            "type": "hashed"
        }
        
        return {
            "message": "✅ Registro con hash exitoso",
            "user": user.username
        }
    except Exception as e:
        # Esto mostrará el error REAL en el servidor
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")

@router.post("/login")
async def login(user: UserLogin):
    """Login - VERSIÓN CORREGIDA"""
    try:
        if user.username not in users_db:
            raise HTTPException(status_code=401, detail="Usuario no encontrado")
        
        db_user = users_db[user.username]
        
        # Verificar password
        import hashlib
        hashed_input = hashlib.md5(user.password.encode()).hexdigest()
        
        if db_user.get("type") == "hashed":
            if db_user["hashed_password"] != hashed_input:
                raise HTTPException(status_code=401, detail="Contraseña incorrecta")
        else:
            # Para usuarios de simple-register
            if db_user.get("password") != user.password:
                raise HTTPException(status_code=401, detail="Contraseña incorrecta")
        
        # Token simple
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error en login: {str(e)}")

@router.get("/test")
async def test():
    return {"message": "✅ Router funciona"}

@router.get("/users")
async def list_users():
    return {
        "total": len(users_db),
        "users": list(users_db.keys())
    }
