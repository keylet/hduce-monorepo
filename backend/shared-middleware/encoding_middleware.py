"""
Middleware global para configurar encoding UTF-8 en todas las respuestas JSON
Solución para caracteres especiales (á, é, í, ó, ú, ñ) en respuestas JSON
"""
from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import json

class UTF8JSONResponse(JSONResponse):
    """Response personalizada para forzar UTF-8 en JSON"""
    def render(self, content: any) -> bytes:
        return json.dumps(
            content,
            ensure_ascii=False,
            allow_nan=False,
            indent=None,
            separators=(",", ":"),
        ).encode("utf-8")

def add_encoding_middleware(app: FastAPI):
    """
    Configurar middleware para UTF-8 en todas las respuestas
    """
    # 1. Usar JSONResponse personalizado
    app.default_response_class = UTF8JSONResponse
    
    # 2. Middleware para forzar charset en headers
    @app.middleware("http")
    async def add_charset_header(request: Request, call_next):
        response = await call_next(request)
        content_type = response.headers.get("content-type", "")
        if "application/json" in content_type and "charset=utf-8" not in content_type:
            response.headers["content-type"] = "application/json; charset=utf-8"
        return response
    
    # 3. CORS middleware con configuración amplia
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["Content-Type", "charset"]
    )
    
    return app

# Función de utilidad para configurar JSON en rutas
def configure_json_encoding():
    """Configuración para usar JSON con UTF-8"""
    return {
        "response_class": UTF8JSONResponse,
        "include_in_schema": True
    }
