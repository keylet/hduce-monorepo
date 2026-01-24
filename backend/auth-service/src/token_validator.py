"""
Token Validator Endpoint for Auth Service
Using PyJWT from shared libraries (NO python-jose dependency)
"""
from fastapi import APIRouter, HTTPException
from hduce_shared.auth import TokenValidationRequest, TokenValidationResponse
from hduce_shared.auth import JWTManager
import os

router = APIRouter(prefix="/api/auth", tags=["authentication"])


JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
jwt_manager = JWTManager(secret_key=JWT_SECRET_KEY)

@router.post("/validate-token", response_model=TokenValidationResponse)
async def validate_token(request: TokenValidationRequest):
    """
    INTERNAL endpoint for other services to validate JWT tokens.
    Should not be publicly accessible without authentication in production.
    """
    validation_result = jwt_manager.verify_token(request.token)
    
    if not validation_result.is_valid:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token"
        )
    
    return validation_result

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "auth-service"}

