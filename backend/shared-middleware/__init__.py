"""
Shared Middleware para microservicios HDuce
Contiene middleware común para todos los servicios
"""
from .encoding_middleware import add_encoding_middleware, UTF8JSONResponse, configure_json_encoding

__all__ = ["add_encoding_middleware", "UTF8JSONResponse", "configure_json_encoding"]
