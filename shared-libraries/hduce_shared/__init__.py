"""
HDUCE Shared Libraries
Common utilities for all microservices
"""

import logging
import sys

def setup_logging(level="INFO"):
    """Simple logging setup"""
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        stream=sys.stdout
    )
    return logging.getLogger(__name__)

from .database import init_db, check_db_connection

# Importar desde config (usar settings en lugar de get_settings)
from .config import settings, Settings

# Crear alias get_settings para compatibilidad
get_settings = lambda: settings

# Importar lo demás si existe
try:
    from .auth import JWTManager, get_current_user
    HAS_AUTH = True
except ImportError:
    HAS_AUTH = False
    JWTManager = None
    get_current_user = None

try:
    from .rabbitmq import RabbitMQPublisher, RabbitMQConsumer
    HAS_RABBITMQ = True
except ImportError:
    HAS_RABBITMQ = False
    RabbitMQPublisher = None
    RabbitMQConsumer = None

try:
    from .models import UserResponse, AppointmentResponse
    HAS_MODELS = True
except ImportError:
    HAS_MODELS = False
    UserResponse = None
    AppointmentResponse = None

__all__ = [
    "setup_logging",
    "init_db",
    "check_db_connection",
    "get_settings",
    "settings",
    "Settings",
    "JWTManager",
    "get_current_user",
    "RabbitMQPublisher",
    "RabbitMQConsumer",
    "UserResponse",
    "AppointmentResponse",
    "HAS_AUTH",
    "HAS_RABBITMQ",
    "HAS_MODELS",
]
