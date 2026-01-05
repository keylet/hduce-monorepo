from fastapi import Request
from fastapi.responses import JSONResponse
import json

class UTF8Middleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, request: Request, call_next):
        # Procesar la solicitud
        response = await call_next(request)
        
        # Asegurar que la respuesta use UTF-8
        if isinstance(response, JSONResponse):
            response.charset = "utf-8"
        
        return response
