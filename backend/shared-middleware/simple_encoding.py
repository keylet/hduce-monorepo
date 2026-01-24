"""
Middleware SIMPLE para forzar UTF-8 en respuestas JSON
"""
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import json

class SimpleUTF8Response(JSONResponse):
    def render(self, content: any) -> bytes:
        return json.dumps(
            content,
            ensure_ascii=False,
            allow_nan=False,
            indent=None,
            separators=(",", ":"),
        ).encode("utf-8")

def setup_utf8_encoding(app: FastAPI):
    """Configuración simple para UTF-8"""
    # Forzar JSONResponse personalizado
    app.default_response_class = SimpleUTF8Response
    
    # Middleware para headers
    from fastapi.middleware.cors import CORSMiddleware
    from starlette.middleware.base import BaseHTTPMiddleware
    
    class UTF8Middleware(BaseHTTPMiddleware):
        async def dispatch(self, request, call_next):
            response = await call_next(request)
            if hasattr(response, 'headers'):
                content_type = response.headers.get('content-type', '')
                if 'application/json' in content_type:
                    response.headers['content-type'] = 'application/json; charset=utf-8'
            return response
    
    app.add_middleware(UTF8Middleware)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    print("✅ Middleware UTF-8 simple configurado")
    return app
