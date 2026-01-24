from fastapi import FastAPI
from .routes import router
from .database import engine, Base
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_app():
    app = FastAPI(title="Appointment Service", version="1.0.0")
    
    # Incluir rutas
    app.include_router(router, prefix="/api")
    
    @app.on_event("startup")
    async def startup_event():
        logger.info("🚀 Appointment Service starting up...")
        
    @app.on_event("shutdown")
    async def shutdown_event():
        logger.info("🛑 Appointment Service shutting down...")
    
    return app
