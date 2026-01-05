import httpx
import logging
from typing import Optional

logger = logging.getLogger(__name__)

class AuthServiceClient:
    def __init__(self):
        self.base_url = "http://auth-service:8000"
        self.client = httpx.AsyncClient(timeout=30.0)
    
    async def validate_token(self, token: str) -> Optional[dict]:
        """Valida un token JWT con el auth-service"""
        try:
            headers = {"Authorization": f"Bearer {token}"}
            response = await self.client.get(
                f"{self.base_url}/validate-token",
                headers=headers
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"Token validation failed: {response.status_code}")
                return None
                
        except Exception as e:
            logger.error(f"Error calling auth-service: {e}")
            return None
    
    async def close(self):
        await self.client.aclose()

# Singleton instance
auth_client = AuthServiceClient()
