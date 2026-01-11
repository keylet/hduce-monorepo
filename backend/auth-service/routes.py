from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
from database import get_db, User
from hduce_shared.auth import JWTManager
from hduce_shared.config import settings
import auth_utils

router = APIRouter(prefix="/auth", tags=["authentication"])

# Configurar JWT - JWTManager usa constantes de clase
# Actualizar constantes desde settings
JWTManager.SECRET_KEY = settings.jwt.jwt_secret_key
JWTManager.ALGORITHM = settings.jwt.jwt_algorithm
JWTManager.ACCESS_TOKEN_EXPIRE_MINUTES = settings.jwt.jwt_access_token_expire_minutes

# OAuth2
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

@router.post("/register")
async def register(user_data: dict, db: Session = Depends(get_db)):
    """User registration endpoint"""
    return {"message": "Register endpoint", "user": user_data}

@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """User login endpoint"""
    try:
        # Buscar usuario
        user = db.query(User).filter(User.username == form_data.username).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario o contraseÃ±a incorrectos"
            )
        
        # Verificar contraseÃ±a
        if not auth_utils.verify_password(form_data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Usuario o contraseÃ±a incorrectos"
            )
        
        # Crear token
        token_data = {
            "sub": user.username,
            "user_id": user.id,
            "role": user.role
        }
        
        access_token = JWTManager.create_access_token(token_data)
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": user.to_dict()
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error en login: {str(e)}"
        )

@router.get("/validate")
async def validate_token(token: str = Depends(oauth2_scheme)):
    """Validate JWT token"""
    try:
        payload = JWTManager.verify_token(token)
        return {"valid": True, "payload": payload}
    except Exception as e:
        return {"valid": False, "error": str(e)}

@router.get("/test")
async def test_endpoint():
    """Test endpoint"""
    return {"status": "ok", "service": "auth", "timestamp": datetime.utcnow().isoformat()}
