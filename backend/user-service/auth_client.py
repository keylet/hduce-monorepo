"""
Authentication client usando JWTManager de shared libraries - VERSION CORREGIDA
"""
from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Dict, Any

try:
    # Importar de shared libraries (instalado via pip)
    from hduce_shared.auth.jwt_manager import JWTManager
    from hduce_shared.config.settings import settings

    # Crear instancia con configuraci?n centralizada
    jwt_manager = JWTManager(
        secret_key=settings.jwt.jwt_secret_key,
        algorithm=settings.jwt.jwt_algorithm
    )

    print(f"? User-service JWTManager configurado correctamente")

except ImportError as e:
    print(f"? ERROR: No se pueden importar shared libraries: {e}")
    raise

security = HTTPBearer()

async def validate_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """
    Valida token JWT usando JWTManager.verify_token() de shared libraries
    """
    token = credentials.credentials

    print(f"?? Validando token: {token[:30]}...")

    try:
        # Usar verify_token de JWTManager
        validation_result = jwt_manager.verify_token(token)

        if not validation_result.is_valid:
            print(f"? Token inv?lido seg?n JWTManager")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inv?lido o expirado"
            )

        print(f"? Token v?lido para: {validation_result.email}")

        # Tambi?n decodificar para obtener payload completo
        payload = jwt_manager.decode_token(token)
        if payload:
            return payload
        else:
            # Si no se puede decodificar, usar info de validation_result
            return {
                "sub": validation_result.user_id,
                "email": validation_result.email,
                "username": validation_result.username,
                "exp": validation_result.expires_at
            }

    except Exception as e:
        print(f"? Error en validaci?n: {type(e).__name__}: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inv?lido o expirado"
        )
