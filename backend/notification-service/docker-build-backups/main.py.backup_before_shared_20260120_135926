import uvicorn
from fastapi import FastAPI
from contextlib import asynccontextmanager
import threading
import logging
from independent_consumer import start_consumer
from routes import router as notifications_router

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Variable para controlar el hilo del consumer
consumer_thread = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Inicio: iniciar consumer en un hilo separado
    global consumer_thread
    
    logger.info("🚀 Iniciando Notification Service...")
    
    # Iniciar consumer en un hilo separado
    consumer_thread = threading.Thread(
        target=start_consumer,
        name="RabbitMQ-Consumer",
        daemon=True  # Daemon thread para que se cierre con la app
    )
    consumer_thread.start()
    
    logger.info("✅ Consumer iniciado en hilo separado")
    
    yield  # La app está ejecutándose
    
    # Cierre: limpiar recursos
    logger.info("👋 Cerrando Notification Service...")
    # El consumer se cerrará automáticamente cuando termine el hilo

# Crear aplicación FastAPI
app = FastAPI(
    title="Notification Service",
    description="Servicio de notificaciones con RabbitMQ Consumer",
    version="1.0.0",
    lifespan=lifespan
)

# Incluir rutas
app.include_router(notifications_router)

@app.get("/")
async def root():
    return {"message": "Notification Service is running"}

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "notification",
        "consumer_alive": consumer_thread.is_alive() if consumer_thread else False
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8003,
        reload=True
    )
