"""
Appointment Service - Using Shared Libraries with corrected imports
"""
from fastapi import FastAPI
from contextlib import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 Appointment Service starting up...")
    
    # Import inside lifespan to avoid circular imports
    from hduce_shared.database import Base
    from database import get_engine, create_tables
    
    # Get engine and create tables
    engine = get_engine()
    Base.metadata.create_all(bind=engine)
    logger.info("✅ Database tables created/verified")
    
    yield
    
    # Shutdown
    logger.info("🛑 Appointment Service shutting down...")

app = FastAPI(
    title="Appointment Service",
    description="Medical appointments management microservice",
    version="2.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import and include routes
from routes import router as appointments_router
app.include_router(
    appointments_router,
    prefix="/api",
    tags=["appointments"]
)

@app.get("/health")
async def health_check():
    """Health endpoint"""
    return {
        "status": "healthy",
        "service": "appointment-service",
        "version": "2.0.0",
        "using_shared_libraries": True,
        "database": "appointment_db"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8002,
        reload=True,
        log_level="info"
    )


