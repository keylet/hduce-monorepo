# backend/user-service/src/auth_dependency.py - VERSIÓN CORREGIDA
"""
Authentication Dependency for User Service
Validates JWT tokens by calling the auth-service
"""
from fastapi import HTTPException, Depends, Header
from typing import Optional
import httpx
import os

# Auth service URL - should be in environment variables
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://auth-service:8000")

async def validate_token_dependency(
    authorization: Optional[str] = Header(None)
):
    """
    Dependency that validates JWT tokens by calling auth-service.
    Use in route dependencies: user_data: dict = Depends(validate_token_dependency)
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid Authorization header. Format: Bearer <token>"
        )

    token = authorization.split(" ")[1]

    # ✅ CORREGIDO: Usar el endpoint correcto /verify/{token}
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(  # ✅ Cambiado a GET
                f"{AUTH_SERVICE_URL}/verify/{token}",  # ✅ Endpoint correcto
                timeout=5.0
            )

            if response.status_code == 200:
                data = response.json()
                # Extraer información del usuario del token
                return {
                    "user_id": data.get("user", "unknown"),
                    "username": data.get("user", "unknown"),
                    "email": f"{data.get('user', 'unknown')}@example.com"
                }
            else:
                raise HTTPException(
                    status_code=401,
                    detail="Invalid or expired token"
                )

        except httpx.RequestError as e:
            raise HTTPException(
                status_code=503,
                detail=f"Authentication service unavailable: {str(e)}"
            )

async def get_current_user(user_data: dict = Depends(validate_token_dependency)):
    """
    Get current user from validated token data.
    Returns user_id, username, and email from the token.
    """
    return user_data