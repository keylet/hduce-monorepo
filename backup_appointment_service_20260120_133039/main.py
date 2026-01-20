import uvicorn
from fastapi import FastAPI
from contextlib import asynccontextmanager
from routes import router as appointments_router
from database import engine, Base
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Inicio: crear tablas si no existen
    logger.info("🚀 Iniciando Appointment Service...")
    Base.metadata.create_all(bind=engine)
    logger.info("✅ Tablas de base de datos verificadas")
    
    yield  # La app está ejecutándose
    
    # Cierre: limpiar recursos
    logger.info("👋 Cerrando Appointment Service...")

# Crear aplicación FastAPI
app = FastAPI(
    title="Appointment Service",
    description="Servicio de gestión de citas médicas",
    version="1.0.0",
    lifespan=lifespan
)

# Incluir rutas
app.include_router(appointments_router)

@app.get("/")
async def root():
    return {"message": "Appointment Service is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "appointment"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8002,
        reload=True
    )
