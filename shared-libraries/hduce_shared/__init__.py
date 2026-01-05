"""
HDUCE Shared Libraries
"""

__version__ = "1.0.0"

# Importar solo lo que existe
from .auth import JWTManager, LoginRequest, LoginResponse, RegisterRequest, TokenValidationResponse
from .config import Settings, settings
from .database import Base, get_db_session, get_db_engine, create_all_tables, DatabaseManager, TimestampMixin, SoftDeleteMixin

# No hay módulo .models, así que no lo importamos
# users puede no estar completamente implementado
try:
    from .users import UserInDB
except ImportError:
    pass
