# backend/user-service/src/protected_routes.py
"""
Protected Routes for User Service
Require valid JWT token for access
"""
from fastapi import APIRouter, Depends
from src.auth_dependency import get_current_user

# ✅ CORREGIDO: Router con prefix "/protected" para rutas protegidas
router = APIRouter(prefix="/protected", tags=["protected"])

@router.get("/me")
async def get_current_user_profile(
    current_user: dict = Depends(get_current_user)
):
    """
    Protected route - only accessible with valid JWT token
    """
    return {
        "message": "Access granted to protected route",
        "user": current_user,
        "profile_info": "This is protected user data that requires authentication",
        "service": "user-service"
    }

@router.get("/test")
async def protected_test_route(
    current_user: dict = Depends(get_current_user)
):
    """
    Another protected route for testing
    """
    from datetime import datetime
    return {
        "status": "success",
        "message": "You have accessed a protected route",
        "authenticated_user": current_user,
        "timestamp": datetime.now().isoformat()
    }

@router.get("/users")
async def list_protected_users():
    """List users (protected endpoint)"""
    return {
        "message": "Protected users endpoint",
        "users": ["user1", "user2", "user3"]
    }