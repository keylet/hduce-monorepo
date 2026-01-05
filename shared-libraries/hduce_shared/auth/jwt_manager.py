import jwt
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from pydantic import BaseModel

# Definir TokenValidationResponse
class TokenValidationResponse(BaseModel):
    """Response model for token validation"""
    user_id: str
    username: str
    email: str
    is_valid: bool
    expires_at: int

class JWTManager:
    def __init__(self, secret_key: str, algorithm: str = "HS256"):
        self.secret_key = secret_key
        self.algorithm = algorithm

    def create_access_token(self, data: Dict[str, Any], expires_minutes: int = 30) -> str:
        """Create JWT access token with expiration"""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(minutes=expires_minutes)
        to_encode.update({"exp": expire, "type": "access"})
        return jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)

    def decode_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Decode JWT token without validation (for debugging)"""
        try:
            return jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
        except jwt.PyJWTError:
            return None

    def verify_token(self, token: str) -> TokenValidationResponse:
        """Verify token and return standardized validation response"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])

            # Extract user information from payload
            user_id = payload.get("sub") or payload.get("user_id") or ""
            username = payload.get("username") or payload.get("preferred_username") or ""
            email = payload.get("email") or ""
            expires_at = payload.get("exp") or 0

            return TokenValidationResponse(
                user_id=str(user_id),
                username=str(username),
                email=str(email),
                is_valid=True,
                expires_at=int(expires_at)
            )

        except jwt.ExpiredSignatureError:
            return TokenValidationResponse(
                user_id="",
                username="",
                email="",
                is_valid=False,
                expires_at=0
            )
        except jwt.InvalidTokenError:
            return TokenValidationResponse(
                user_id="",
                username="",
                email="",
                is_valid=False,
                expires_at=0
            )

# Funciones estáticas (para compatibilidad con el código existente)
def decode_token(token: str, secret_key: str) -> Optional[Dict]:
    """Static method to decode JWT token"""
    try:
        return jwt.decode(token, secret_key, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

def create_token(data: Dict, secret_key: str, expires_minutes: int = 30) -> str:
    """Static method to create JWT token"""
    expires_delta = timedelta(minutes=expires_minutes)
    expire = datetime.utcnow() + expires_delta

    to_encode = data.copy()
    to_encode.update({"exp": expire})

    return jwt.encode(to_encode, secret_key, algorithm="HS256")
