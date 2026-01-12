"""
JWT Manager configurable para todos los servicios
Versión corregida - evita importación circular
"""
from jose import jwt, JWTError
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
from pydantic import BaseModel

class TokenData(BaseModel):
    sub: str
    user_id: int
    exp: datetime

class JWTManager:
    """JWT Manager configurable - usa configuración externa"""
    
    # Variables de clase que deben ser configuradas por cada servicio
    SECRET_KEY = None
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    
    @classmethod
    def configure(cls, secret_key: str, algorithm: str = "HS256", access_token_expire_minutes: int = 30):
        """Configurar JWTManager con valores específicos"""
        cls.SECRET_KEY = secret_key
        cls.ALGORITHM = algorithm
        cls.ACCESS_TOKEN_EXPIRE_MINUTES = access_token_expire_minutes
    
    @classmethod
    def create_access_token(cls, data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
        """Crear token JWT usando configuración establecida"""
        if cls.SECRET_KEY is None:
            raise ValueError("JWTManager must be configured before use. Call JWTManager.configure()")
        
        to_encode = data.copy()
        
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=cls.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({
            "exp": expire,
            "iat": datetime.utcnow(),
            "iss": "hduce-auth-service",
            "type": "access_token"
        })
        
        encoded_jwt = jwt.encode(to_encode, cls.SECRET_KEY, algorithm=cls.ALGORITHM)
        return encoded_jwt

    @classmethod
    def verify_token(cls, token: str) -> Optional[Dict[str, Any]]:
        """Verificar y decodificar token JWT"""
        if cls.SECRET_KEY is None:
            return None
            
        try:
            payload = jwt.decode(
                token, 
                cls.SECRET_KEY, 
                algorithms=[cls.ALGORITHM],
                options={"verify_exp": True}
            )
            
            # Verificar tipo de token
            if payload.get("type") != "access_token":
                return None
                
            return payload
            
        except jwt.ExpiredSignatureError:
            return None
        except JWTError:
            return None
        except Exception:
            return None

class TokenValidationResponse(BaseModel):
    valid: bool
    payload: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
