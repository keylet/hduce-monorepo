from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
import logging

router = APIRouter(prefix="/auth", tags=["authentication"])
logger = logging.getLogger(__name__)

@router.get("/test")
async def test():
    return {"status": "ok", "message": "Auth service ULTRA SIMPLE"}

@router.get("/health")
async def health():
    return {"status": "healthy", "service": "auth"}

@router.post("/login-test")
async def login_test(form_data: OAuth2PasswordRequestForm = Depends()):
    """Login TEST con verificación SIMPLE"""
    if form_data.username == "emergency" and form_data.password == "test123":
        return {
            "access_token": "test_jwt_token",
            "token_type": "bearer",
            "user": {
                "id": 1,
                "username": "emergency",
                "email": "emergency@test.com",
                "role": "patient"
            },
            "message": "SIMPLE_LOGIN_WORKING"
        }
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")

# Endpoint para probar SI SE COPIA EL ARCHIVO
@router.get("/file-check")
async def file_check():
    """Verificar que este archivo se cargó"""
    return {
        "status": "ok",
        "message": "THIS IS THE ULTRA SIMPLE ROUTES.PY - FILE LOADED CORRECTLY",
        "version": "ultra-simple-1.0"
    }
