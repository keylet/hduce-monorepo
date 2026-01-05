from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import create_tables
from routes import router
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Appointment Service",
    description="Microservicio para gestión de citas médicas HDUCE",
    version="4.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Evento de startup: crear tablas
@app.on_event("startup")
def on_startup():
    try:
        create_tables()
        logger.info("✅ Database tables verified/created")
    except Exception as e:
        logger.error(f"❌ Error creating database tables: {e}")

# IMPORTANTE: Incluir router con prefix
app.include_router(router, prefix="/appointments")

# Health check (fuera del prefix)
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "appointment",
        "version": "4.0.0"
    }

# Root endpoint (fuera del prefix)
@app.get("/")
async def root():
    return {
        "message": "HDUCE Appointment Service v4.0",
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "appointments": "/appointments",
            "doctors": "/appointments/doctors",
            "specialties": "/appointments/specialties",
            "db-check": "/appointments/db-check"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002, log_level="info")
