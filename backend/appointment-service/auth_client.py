"""
Authentication client - Robust version with proper error handling
"""
import sys
import os


sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, '/app')  # For Docker

import logging
from typing import Dict, Any, Optional
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials


from hduce_shared.config import settings
from hduce_shared.auth import JWTManager

logger = logging.getLogger(__name__)
security = HTTPBearer()

try:
    jwt_secret_key = settings.jwt.jwt_secret_key
    logger.info(f"JWT Secret Key loaded (first 10 chars): {jwt_secret_key[:10]}...")
    jwt_manager = JWTManager(secret_key=jwt_secret_key)
    logger.info("✅ JWTManager initialized successfully")
except Exception as e:
    logger.error(f"❌ Failed to initialize JWTManager: {e}")
    raise

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """
    Verifies a JWT token using shared JWTManager
    """
    jwt_token = credentials.credentials
    
    if not jwt_token or jwt_token == "null" or jwt_token == "undefined":
        logger.error("No authentication token provided")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    logger.info(f"Verifying token (first 20 chars): {jwt_token[:20]}...")
    
    try:
       
        payload = jwt_manager.decode_token(jwt_token)
        
       
        if payload is None:
            logger.error("decode_token returned None - invalid token or secret key mismatch")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: unable to decode",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
    
        logger.info(f"✅ Token decoded successfully for subject: {payload.get('sub', 'unknown')}")
        
       
        token_data = {
            "valid": True,
            "user_id": payload.get("user_id") or payload.get("sub") or "unknown",
            "email": payload.get("email") or payload.get("sub") or "unknown@example.com",
            "username": payload.get("username") or payload.get("preferred_username") or "unknown",
            "role": payload.get("role", "patient"),
            "sub": payload.get("sub", ""),
            "exp": payload.get("exp", 0),
            "iat": payload.get("iat", 0)
        }
        
        logger.info(f"Token data prepared: user_id={token_data['user_id']}, email={token_data['email']}")
        return token_data
        
    except HTTPException:
     
        raise
    except Exception as e:
        logger.error(f"Error verifying token: {type(e).__name__}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token validation failed: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Alias for verify_token for compatibility with existing code"""
    return await verify_token(credentials)
