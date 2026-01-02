"""
Protected Routes for User Service
Require valid JWT token for access
"""
from fastapi import APIRouter, Depends
from src.auth_dependency import get_current_user

router = APIRouter(prefix="/api/users", tags=["users"])

@router.get("/me")
async def get_current_user_profile(
    current_user: dict = Depends(get_current_user)
):
    """
    Protected route - only accessible with valid JWT token
    Returns current user's profile information
    """
    return {
        "message": "Access granted to protected route",
        "user": current_user,
        "profile_info": "This is protected user data that requires authentication",
        "service": "user-service"
    }

@router.get("/protected-test")
async def protected_test_route(
    current_user: dict = Depends(get_current_user)
):
    """
    Another protected route for testing
    """
    return {
        "status": "success",
        "message": "You have accessed a protected route",
        "authenticated_user": current_user,
        "timestamp": "2024-01-01T00:00:00Z"  # You should use datetime.now()
    }
