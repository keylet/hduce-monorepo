# -*- coding: utf-8 -*-

"""
User Service - Main application file
"""

import logging
import sys
import os

# Configurar path para shared-libraries
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)
sys.path.insert(0, "/app")  # Para shared-libraries en Docker

# IMPORTAR DE SHARED-LIBRARIES
from hduce_shared.config import settings

import os

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Cargar variables de entorno PRIMERO
load_dotenv()

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Importar rutas (DESPUES de cargar .env)
try:
    from routes import router as user_router
    from database import get_db, init_db, engine
    logger.info("Imports de user-service cargados correctamente")
except ImportError as e:
    logger.error(f"Error importando modulos de user-service: {e}")
    raise

# Crear aplicacion
app = FastAPI(
    title="User Service API",
    version="1.0.0",
    description="Microservicio para gestion de usuarios"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir rutas
app.include_router(user_router, tags=["users"])

# Endpoint de salud
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "user-service",
        "database": "connected via shared-libraries",
        "using_shared_libraries": True
    }

@app.get("/")
async def root():
    return {
        "message": "User Service API",
        "version": "1.0.0",
        "using_shared_libraries": True,
        "endpoints": [
            "/api/v1/users/health",
            "/api/v1/users/",
            "/api/v1/users/me",
            "/api/v1/users/{user_id}"
        ]
    }

# Inicializar base de datos al iniciar
@app.on_event("startup")
async def startup_event():
    logger.info("Iniciando User Service...")
    
    try:
        logger.info("Inicializando base de datos...")
        init_db()
        logger.info("Base de datos inicializada correctamente")
    except Exception as e:
        logger.error(f"Error inicializando base de datos: {e}")
    
    logger.info("User Service listo y funcionando en puerto 8001")

if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", "8001"))
    host = os.getenv("HOST", "0.0.0.0")
    
    logger.info(f"Iniciando servidor en {host}:{port}")
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info"
    )


