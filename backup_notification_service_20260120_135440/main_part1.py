# backend/notification-service/main.py
# ✅ ACTUALIZADO para usar shared-libraries
from fastapi import FastAPI
import uvicorn
from datetime import datetime
import threading
import time
import logging

# Importar desde shared libraries
from hduce_shared.config import settings
from hduce_shared.database import get_db_engine, create_all_tables

# Importar módulos locales - USAR IMPORTS ABSOLUTOS
import routes
import models
import schemas
from database import get_db

# Importar configuración específica de notificaciones
from config import (
    RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_USER, RABBITMQ_PASSWORD,
    EMAIL_SIMULATION, SMS_SIMULATION
)

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Crear aplicación FastAPI
app = FastAPI(
    title="HDUCE Notification Service",
    description="Microservicio para gestión de notificaciones usando shared-libraries",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Incluir rutas
app.include_router(routes.router)
