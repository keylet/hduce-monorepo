#!/usr/bin/env python3
"""Appointment Service - HDuce Medical System"""

import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware

# Import shared libraries first
import sys
sys.path.append("/app/shared-libraries")

# IMPORTANTE: setup_logging ahora está en hduce_shared directamente
from hduce_shared import setup_logging
from hduce_shared.database import init_db, check_db_connection

import webhooks

# Configure logging
setup_logging()
logger = logging.getLogger(__name__)

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@postgres:5432/appointment_db")

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown events."""
    # Startup
    logger.info("🚀 Starting appointment-service...")

    try:
        # Initialize database
        logger.info("📦 Configurando appointment-service database con shared libraries...")
        db_manager = init_db()  # Esto ahora retorna DatabaseManager
        logger.info("✅ Appointment-service configured to use shared libraries")
        logger.info(f"🔧 Service: appointments, Database: appointment_db")

        # Verify database connection
        if check_db_connection("appointments"):
            logger.info("✅ Database connection verified")
        else:
            logger.error("❌ Database connection failed")
            raise Exception("Database connection failed")

        yield

    except Exception as e:
        logger.error(f"❌ Error durante startup: {e}")
        raise

    # Shutdown
    logger.info("🛑 Shutting down appointment-service...")

# Create FastAPI app
app = FastAPI(
    title="HDuce Appointment Service",
    description="Microservicio para gestión de doctores y citas médicas",
    version="2.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# UTF-8 Response Middleware
@app.middleware("http")
async def add_utf8_charset(request: Request, call_next):
    response = await call_next(request)
    content_type = response.headers.get("content-type", "")
    if "application/json" in content_type and "charset=utf-8" not in content_type:
        response.headers["content-type"] = "application/json; charset=utf-8"
    return response

# Import and include routes
from routes import router as appointments_router
app.include_router(
    appointments_router,
    prefix="/api",
    tags=["appointments"]
)
app.include_router(webhooks.router, prefix="/api/webhooks")

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





