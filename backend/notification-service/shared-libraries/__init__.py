"""HDUCE Shared Libraries Package - Version Unificada"""
# Exportar desde hduce_shared (implementación centralizada)
from hduce_shared.auth import JWTManager, TokenValidationResponse
from hduce_shared.auth.jwt_manager import decode_token, create_token

__version__ = "0.1.0"
__all__ = [
    "JWTManager", 
    "TokenValidationResponse", 
    "decode_token", 
    "create_token"
]
