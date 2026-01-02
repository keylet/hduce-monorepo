# shared-libraries/utils/src/jwt.py
import jwt
from datetime import datetime, timedelta
from typing import Optional, Dict

class JWTUtils:
    @staticmethod
    def decode_token(token: str, secret_key: str) -> Optional[Dict]:
        """Decode JWT token"""
        try:
            return jwt.decode(token, secret_key, algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None
    
    @staticmethod
    def create_token(data: Dict, secret_key: str, expires_minutes: int = 30) -> str:
        """Create JWT token"""
        expires_delta = timedelta(minutes=expires_minutes)
        expire = datetime.utcnow() + expires_delta
        
        to_encode = data.copy()
        to_encode.update({"exp": expire})
        
        return jwt.encode(to_encode, secret_key, algorithm="HS256")