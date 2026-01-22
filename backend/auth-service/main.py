import sys
import os

# Configurar path para imports
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)
sys.path.insert(0, '/app')  # Para shared-libraries

from fastapi import FastAPI
from fastapi.responses import JSONResponse
import json
from fastapi.responses import JSONResponse
import json
from fastapi.responses import JSONResponse
import json
from fastapi.middleware.cors import CORSMiddleware
import logging

# IMPORTAR DE SHARED-LIBRARIES (MANTENER)
from hduce_shared.auth import JWTManager
from hduce_shared.config import settings

# Importar rutas locales
from routes import router

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    docs_url="/auth/docs",
    redoc_url="/auth/redoc",
    openapi_url="/auth/openapi.json",

    title="HDUCE Auth Service",
    description="Authentication service with real JWT and PostgreSQL",
    version="3.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir rutas
app.include_router(router, prefix="/auth")

@app.on_event("startup")
async def startup_event():
    """Inicializar base de datos al iniciar"""
    try:
        from database import create_auth_tables
        create_auth_tables()
        logger.info("✅ Database tables created")
    except Exception as e:
        logger.error(f"❌ Database error: {e}")

@app.get("/")
async def root():
    return {
        "service": "auth-service",
        "version": "3.0.0",
        "status": "running",
        "using_shared_libraries": True
    }

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "auth"}




