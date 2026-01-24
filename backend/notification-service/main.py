"""
Notification Service - 100% usando Shared Libraries
SOLO UN consumer: desde independent_consumer.py
"""
import uvicorn
import sys
import os
import logging
import threading
from fastapi import FastAPI
from contextlib import asynccontextmanager

# Añadir path para shared libraries
sys.path.insert(0, '/app')

# Importar módulos locales
from independent_consumer import start_consumer
from routes import router as notifications_router

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Variable para controlar el hilo del consumer
consumer_thread = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global consumer_thread

    logger.info("🚀 Iniciando Notification Service con SHARED LIBRARIES...")

    # Crear tablas si no existen
    try:
        from database import create_tables
        if create_tables():
            logger.info("✅ Tablas verificadas/creadas en notification_db")
        else:
            logger.warning("⚠️ No se pudieron crear las tablas")
    except Exception as e:
        logger.error(f"Error creando tablas: {e}")

    # Iniciar consumer en un hilo separado SOLO SI NO HAY YA UNO
    if consumer_thread is None or not consumer_thread.is_alive():
        consumer_thread = threading.Thread(
            target=start_consumer,
            name="RabbitMQ-Consumer",
            daemon=True
        )
        consumer_thread.start()
        logger.info("✅ Consumer iniciado en hilo separado")
    else:
        logger.info("✅ Consumer ya está ejecutándose")

    yield  # La app está ejecutándose

    # Cierre: limpiar recursos
    logger.info("👋 Cerrando Notification Service...")

# Crear aplicación FastAPI
app = FastAPI(
    title="Notification Service",
    description="Servicio de notificaciones con RabbitMQ Consumer",
    version="1.0.0",
    lifespan=lifespan
)

# Incluir rutas (usando el mismo patrón que appointment-service)
# main.py prefix="/api" + routes.py prefix="/notifications" = /api/notifications/
app.include_router(notifications_router, prefix="/api")

@app.get("/")
async def root():
    return {"message": "Notification Service is running with SHARED LIBRARIES"}

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "notification",
        "shared_libraries": "yes",
        "database": "postgresql",
        "consumer_alive": consumer_thread.is_alive() if consumer_thread else False
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8003,
        reload=True
    )
