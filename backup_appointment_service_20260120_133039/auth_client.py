import requests
import logging
from typing import Dict, Any
from fastapi import HTTPException, status, Header, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

logger = logging.getLogger(__name__)
AUTH_SERVICE_URL = "http://auth-service:8000"

# Usar HTTPBearer para extraer automáticamente el token
security = HTTPBearer()

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """
    Verifica un token JWT con el auth-service usando HTTPBearer.
    FastAPI automáticamente extrae el token del header Authorization: Bearer <token>
    
    Args:
        credentials: HTTPAuthorizationCredentials con el token (provisto por HTTPBearer)
    
    Returns:
        Dict con los claims del token si es válido
    
    Raises:
        HTTPException: Si el token es inválido o hay error de conexión
    """
    jwt_token = credentials.credentials
    logger.info(f"Token extraído por HTTPBearer (primeros 30 chars): {jwt_token[:30]}...")
    
    if not jwt_token:
        logger.error("No se proporcionó token de autenticación")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticación requerido",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    try:
        # Llamar al auth-service para validar el token (POST request)
        logger.info(f"Verificando token con auth-service: {AUTH_SERVICE_URL}/auth/verify-token")
        
        # El auth-service espera POST con JSON body
        response = requests.post(
            f"{AUTH_SERVICE_URL}/auth/verify-token",
            json={"token": jwt_token},
            timeout=10
        )
        
        logger.info(f"Auth-service response status: {response.status_code}")
        
        if response.status_code == 200:
            # Token válido
            token_data = response.json()
            
            # Verificar que auth-service dice que es válido
            if token_data.get("valid") == False:
                logger.warning(f"Auth-service reportó token inválido: {token_data.get('message')}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Token inválido: {token_data.get('message')}",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            
            logger.info(f"✅ Token válido para usuario: {token_data.get('email')}")
            logger.debug(f"Datos completos del usuario: {token_data}")
            
            # Asegurar que tenemos los campos necesarios
            if not token_data.get("user_id"):
                # Intentar extraer user_id de diferentes campos
                token_data["user_id"] = token_data.get("sub") or token_data.get("user_id") or "1"
                logger.info(f"User_id derivado como: {token_data['user_id']}")
            
            return token_data
            
        elif response.status_code == 401:
            # Token inválido o expirado
            logger.error(f"Token inválido o expirado: {response.text}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido o expirado",
                headers={"WWW-Authenticate": "Bearer"},
            )
        else:
            # Error del servidor de autenticación
            logger.error(f"Error del auth-service: {response.status_code} - {response.text}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Servicio de autenticación no disponible"
            )

    except requests.exceptions.ConnectionError as e:
        logger.error(f"No se puede conectar con auth-service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="No se puede conectar con el servicio de autenticación"
        )
    except requests.exceptions.Timeout as e:
        logger.error(f"Timeout al conectar con auth-service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Timeout al conectar con el servicio de autenticación"
        )
    except requests.exceptions.RequestException as e:
        logger.error(f"Error de conexión con auth-service: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Error de conexión con el servicio de autenticación"
        )
    except Exception as e:
        logger.error(f"Error inesperado en verify_token: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal authentication error"
        )

# Función de compatibilidad para el código existente (si se necesita)
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Alias para verify_token para compatibilidad con código existente"""
    return await verify_token(credentials)
