# backend/auth-service/routes.py - VERSIÓN COMPLETA
from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
import traceback
import logging
from typing import Dict, Any

from database import get_db
from auth_utils import (
    get_password_hash,
    verify_password,
    create_access_token,
    authenticate_user,
    get_current_user_from_token,
    verify_token
)
from models import User
from schemas import UserCreate, UserResponse, TokenResponse

logger = logging.getLogger(__name__)
router = APIRouter()

# ============================================================================
# HEALTH CHECK & ROOT
# ============================================================================

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "auth-service"}

@router.get("/")
async def root():
    """Root endpoint with service info"""
    return {
        "service": "auth-service",
        "version": "1.0.0",
        "endpoints": [
            "/health",
            "/login",
            "/me",
            "/verify",
            "/auth/docs"
        ]
    }

# ============================================================================
# LOGIN CON DEBUG DETALLADO
# ============================================================================

@router.post("/login")
async def login(
    email: str = Body(..., description="User email"),
    password: str = Body(..., description="User password"),
    db: Session = Depends(get_db)
):
    """Login user and return access token - VERSIÓN CON DEBUG"""
    try:
        logger.info(f"🔍 Intentando login para: {email}")

        # 1. Verificar que authenticate_user existe
        logger.info("Paso 1: Verificando authenticate_user...")

        # 2. Autenticar usuario
        logger.info(f"Paso 2: Llamando authenticate_user({email}, ***)")
        user = authenticate_user(db, email, password)

        if not user:
            logger.warning(f"❌ Autenticación fallida para: {email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )

        logger.info(f"✅ Usuario autenticado: {user.email}, ID: {user.id}")

        # 3. Crear token
        logger.info("Paso 3: Creando token JWT...")
        access_token = create_access_token(
            data={
                "sub": user.email,
                "email": user.email,
                "username": user.username or user.email.split("@")[0],
                "user_id": str(user.id)
            }
        )

        logger.info(f"✅ Token creado (longitud: {len(access_token)})")

        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user.id,
            "email": user.email,
            "role": user.role
        }

    except Exception as e:
        logger.error(f"❌ ERROR EN LOGIN DETALLADO: {e}")
        logger.error("Traceback completo:")
        logger.error(traceback.format_exc())

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )

# ============================================================================
# GET CURRENT USER (/me)
# ============================================================================

@router.get("/me")
async def get_current_user_info(
    current_user: User = Depends(get_current_user_from_token)
) -> Dict[str, Any]:
    """Get current authenticated user info"""
    try:
        logger.info(f"🔍 Obteniendo info usuario: {current_user.email}")
        
        return {
            "id": current_user.id,
            "email": current_user.email,
            "username": current_user.username,
            "role": current_user.role,
            "is_active": current_user.is_active,
            "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
            "updated_at": current_user.updated_at.isoformat() if current_user.updated_at else None
        }
    
    except Exception as e:
        logger.error(f"❌ Error en /me: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user info: {str(e)}"
        )

# ============================================================================
# VERIFY TOKEN (/verify)
# ============================================================================

@router.get("/verify")
async def verify_user_token(
    current_user: User = Depends(get_current_user_from_token)
) -> Dict[str, Any]:
    """Verify if token is valid and return user info"""
    try:
        logger.info(f"✅ Token verificado para usuario: {current_user.email}")
        
        return {
            "valid": True,
            "user": {
                "id": current_user.id,
                "email": current_user.email,
                "username": current_user.username,
                "role": current_user.role
            },
            "message": "Token is valid"
        }
    
    except HTTPException as e:
        logger.warning(f"❌ Token inválido: {e.detail}")
        raise
    except Exception as e:
        logger.error(f"❌ Error en /verify: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Token verification failed: {str(e)}"
        )

# ============================================================================
# QUICK VERIFY TOKEN (sin dependencia de base de datos)
# ============================================================================

@router.post("/verify-token")
async def verify_token_quick(
    token: str = Body(..., embed=True)
) -> Dict[str, Any]:
    """Verify token quickly without database query"""
    try:
        logger.info("🔍 Verificando token (quick)...")
        
        payload = verify_token(token)
        if not payload:
            logger.warning("❌ Token inválido o expirado")
            return {"valid": False, "message": "Invalid or expired token"}
        
        logger.info(f"✅ Token válido para: {payload.get('email')}")
        return {
            "valid": True,
            "user": {
                "email": payload.get("email"),
                "username": payload.get("username"),
                "user_id": payload.get("user_id")
            },
            "exp": payload.get("exp"),
            "message": "Token is valid"
        }
    
    except Exception as e:
        logger.error(f"❌ Error en verify-token: {e}")
        return {"valid": False, "message": f"Verification error: {str(e)}"}



