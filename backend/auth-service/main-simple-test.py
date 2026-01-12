import sys
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configurar path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

logger.info("=== STARTING AUTH-SERVICE SIMPLE VERSION ===")

app = FastAPI(
    title="HDUCE Auth Service - SIMPLE TEST",
    description="Testing file copy to container",
    version="test-1.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Importar rutas SIMPLES
try:
    import routes_simple_test as routes
    app.include_router(routes.router)
    logger.info("✅ SIMPLE ROUTES LOADED SUCCESSFULLY")
except Exception as e:
    logger.error(f"❌ Failed to load simple routes: {e}")
    import traceback
    traceback.print_exc()

@app.on_event("startup")
async def startup_event():
    logger.info("🚀 Simple auth-service started")

@app.get("/")
async def root():
    return {
        "service": "auth-service",
        "version": "simple-test",
        "status": "running",
        "message": "Testing file copy"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "mode": "simple-test"}
