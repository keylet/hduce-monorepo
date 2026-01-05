from pydantic import BaseModel, EmailStr

class LoginRequest(BaseModel):
    """Request model for user login"""
    username: str
    password: str

class LoginResponse(BaseModel):
    """Response model for successful login"""
    access_token: str
    token_type: str = "bearer"  # Valor por defecto

class RegisterRequest(BaseModel):
    """Request model for user registration"""
    username: str
    email: EmailStr
    password: str

class TokenValidationRequest(BaseModel):
    """Request model for token validation (internal service communication)"""
    token: str

class TokenValidationResponse(BaseModel):
    """Response model for token validation"""
    user_id: str
    username: str
    email: str
    is_valid: bool
    expires_at: intS