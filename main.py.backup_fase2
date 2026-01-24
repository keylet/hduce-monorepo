from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from contextlib import asynccontextmanager
import uvicorn
import os
from typing import List
from datetime import datetime

from database import engine, get_db
import models
import schemas
from routes import router as notification_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Starting Notification Service...")
    
    # Solo crear tablas si no existen
    try:
        from sqlalchemy import text
        from database import SessionLocal
        
        # Verificar si la tabla notifications existe
        db = SessionLocal()
        db.execute(text("SELECT 1 FROM notifications LIMIT 1"))
        print("Table 'notifications' exists")
        db.close()
    except Exception:
        print("Table 'notifications' does not exist, creating...")
        models.Base.metadata.create_all(bind=engine)
        print("Database tables created")
    
    # Verificar conexion a base de datos
    from sqlalchemy import text
    from database import SessionLocal
    
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
        print("Database connection successful")
    except Exception as e:
        print(f"Database connection failed: {e}")
    
    yield
    
    # Shutdown
    print("Shutting down Notification Service...")

# Crear aplicacion FastAPI
app = FastAPI(
    title="HDUCE Notification Service",
    description="Microservicio para manejo de notificaciones (email, SMS, push)",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8000", "http://localhost:8001", "http://localhost:8002"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware para hosts confiables
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["localhost", "127.0.0.1", "notification-service", "0.0.0.0"]
)

# Incluir rutas
app.include_router(notification_router, prefix="/api/v1", tags=["notifications"])

# Health check endpoint
@app.get("/health", response_model=schemas.HealthCheck, tags=["health"])
async def health_check():
    from sqlalchemy import text
    from database import SessionLocal
    
    db_status = "healthy"
    try:
        db = SessionLocal()
        db.execute(text("SELECT 1"))
        db.close()
    except Exception:
        db_status = "unhealthy"
    
    return schemas.HealthCheck(
        status="healthy",
        service="notification-service",
        database=db_status,
        timestamp=datetime.now()
    )

@app.get("/", tags=["root"])
async def root():
    return {
        "message": "HDUCE Notification Service",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "send_email": "/api/v1/notifications/email",
            "send_sms": "/api/v1/notifications/sms",
            "list_notifications": "/api/v1/notifications"
        }
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8003,
        reload=True,
        log_level="info"
    )
