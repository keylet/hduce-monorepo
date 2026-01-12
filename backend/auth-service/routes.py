from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter(prefix="/auth", tags=["authentication"])

@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """Login SIMPLE pero que funciona"""
    if form_data.username == "emergency" and form_data.password == "test123":
        return {
            "access_token": "jwt_test_token_123",
            "token_type": "bearer",
            "user": {
                "id": 1,
                "username": "emergency",
                "email": "emergency@test.com",
                "role": "patient"
            }
        }
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@router.get("/test")
async def test():
    return {"status": "ok", "message": "Auth service working"}

@router.get("/health")
async def health():
    return {"status": "healthy", "service": "auth"}

@router.get("/check")
async def check():
    """Simple check endpoint"""
    return {"status": "ok", "version": "1.0", "working": True}
