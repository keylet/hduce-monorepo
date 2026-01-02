"""
Auth Service - Main Application
Using PyJWT instead of python-jose for better Windows compatibility
"""
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from datetime import datetime, timedelta
from typing import Optional
import os
from dotenv import load_dotenv

# Import from shared libraries
from hduce_shared_libs.utils.src.jwt_utils import JWTManager
from hduce_shared_libs.types.src.auth_types import LoginRequest, LoginResponse, RegisterRequest
from hduce_shared_libs.types.src.user_types import User

# Import token validator router
from src.token_validator import router as token_router

# Load environment variables
load_dotenv()

app = FastAPI(
    title="HDUCE Auth Service",
    description="Authentication and Authorization Service",
    version="1.0.0"
)

# Include token validation routes
app.include_router(token_router)

# Configuration
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Initialize JWT Manager from shared libraries
jwt_manager = JWTManager(secret_key=JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

# OAuth2 scheme for token extraction
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# Mock user database (replace with real database)
fake_users_db = {
    "testuser": {
        "id": "1",
        "username": "testuser",
        "email": "test@example.com",
        "hashed_password": "fakehashedpassword",  # In real app, use bcrypt
        "is_active": True
    }
}

def get_user(db, username: str):
    """Get user from database"""
    if username in db:
        user_dict = db[username]
        return User(**user_dict)
    return None

def authenticate_user(fake_db, username: str, password: str):
    """Authenticate user (mock implementation)"""
    user = get_user(fake_db, username)
    if not user:
        return False
    # In real app, verify password with bcrypt
    if password != "testpassword":  # Mock validation
        return False
    return user

@app.post("/api/auth/login", response_model=LoginResponse)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    Login endpoint - returns JWT token
    """
    user = authenticate_user(fake_users_db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create token data
    token_data = {
        "sub": user.id,
        "username": user.username,
        "email": user.email
    }
    
    # Create token using shared JWTManager
    access_token = jwt_manager.create_access_token(
        data=token_data,
        expires_minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer"
    )

@app.post("/api/auth/register", response_model=LoginResponse)
async def register(request: RegisterRequest):
    """
    Register new user - returns JWT token
    """
    # Check if user already exists
    if request.username in fake_users_db:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )
    
    # Create new user (in real app, hash password and save to database)
    new_user_id = str(len(fake_users_db) + 1)
    fake_users_db[request.username] = {
        "id": new_user_id,
        "username": request.username,
        "email": request.email,
        "hashed_password": "hashed_" + request.password,  # Hash in real app
        "is_active": True
    }
    
    # Create token for new user
    token_data = {
        "sub": new_user_id,
        "username": request.username,
        "email": request.email
    }
    
    access_token = jwt_manager.create_access_token(
        data=token_data,
        expires_minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer"
    )

@app.get("/api/auth/test-token")
async def test_token_protected(token: str = Depends(oauth2_scheme)):
    """
    Test endpoint that requires valid token
    """
    # Validate token using shared JWTManager
    validation_result = jwt_manager.verify_token(token)
    
    if not validation_result.is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    return {
        "message": "Token is valid",
        "user": {
            "user_id": validation_result.user_id,
            "username": validation_result.username,
            "email": validation_result.email
        }
    }

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "auth-service",
        "status": "running",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.post("/api/auth/simple-register")
async def simple_register():
    """
    Simple registration endpoint for testing
    """
    # Create test token
    token_data = {
        "sub": "123",
        "username": "testuser",
        "email": "test@hduce.com"
    }
    
    access_token = jwt_manager.create_access_token(
        data=token_data,
        expires_minutes=30
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": "123",
        "username": "testuser"
    }

@app.get("/health")
async def health():
    """Health check"""
    return {"status": "healthy", "service": "auth-service"}


@app.post("/api/auth/simple-register")
async def simple_register():
    """
    Simple registration endpoint for testing
    Returns a valid JWT token for testing purposes
    """
    # Create test token with dummy user data
    token_data = {
        "sub": "test-user-id-001",
        "username": "test_user_hduce",
        "email": "test@hduce.ec"
    }
    
    access_token = jwt_manager.create_access_token(
        data=token_data,
        expires_minutes=60
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": "test-user-id-001",
            "username": "test_user_hduce",
            "email": "test@hduce.ec"
        },
        "message": "Test token generated successfully",
        "expires_in": "60 minutes"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

