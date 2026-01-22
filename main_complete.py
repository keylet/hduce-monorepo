"""
Appointment Service - COMPLETE WORKING VERSION
"""
import os
import sys
import logging
from fastapi import FastAPI, APIRouter, BackgroundTasks
import httpx
from datetime import datetime
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add shared libraries path
sys.path.append('/app/shared-libraries')

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan manager"""
    logger.info("🚀 Starting Appointment Service (Complete Version)...")
    yield
    logger.info("🛑 Shutting down...")

# Create app
app = FastAPI(title="Appointment Service", version="1.0.0", lifespan=lifespan)

# ========== WEBHOOKS ROUTES ==========
webhooks_router = APIRouter(prefix="/api/webhooks", tags=["webhooks"])

async def send_to_n8n(event_type: str, data: dict):
    """Send event to N8N"""
    try:
        url = "http://n8n:5678/webhook-test/appointment-created"
        
        payload = {
            "event": event_type,
            "data": data,
            "timestamp": datetime.now().isoformat(),
            "service": "appointment"
        }
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                url,
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            logger.info(f"N8N [{event_type}]: {response.status_code}")
            return response.status_code == 200
    except Exception as e:
        logger.error(f"N8N Error: {e}")
        return False

@webhooks_router.get("/health")
async def webhooks_health():
    """Health check for webhooks"""
    test_result = await send_to_n8n("health_check", {"test": True})
    
    return {
        "status": "healthy",
        "webhooks": "active",
        "n8n_connected": test_result,
        "timestamp": datetime.now().isoformat()
    }

@webhooks_router.post("/appointment-created")
async def appointment_created(data: dict, background_tasks: BackgroundTasks):
    """Handle appointment created"""
    logger.info(f"Appointment created webhook: {data.get('id', 'unknown')}")
    
    # Send to N8N in background
    background_tasks.add_task(send_to_n8n, "appointment.created", data)
    
    return {
        "status": "success",
        "message": "Event queued for N8N",
        "appointment_id": data.get('id'),
        "timestamp": datetime.now().isoformat()
    }

@webhooks_router.post("/appointment-updated")
async def appointment_updated(data: dict, background_tasks: BackgroundTasks):
    """Handle appointment updated"""
    logger.info(f"Appointment updated webhook: {data.get('id', 'unknown')}")
    
    # Send to N8N in background
    background_tasks.add_task(send_to_n8n, "appointment.updated", data)
    
    return {
        "status": "success",
        "message": "Update queued for N8N",
        "appointment_id": data.get('id'),
        "timestamp": datetime.now().isoformat()
    }

# ========== BASIC ROUTES ==========
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "Appointment Service",
        "status": "running",
        "endpoints": {
            "/health": "Service health",
            "/api/webhooks/health": "Webhooks health",
            "/api/webhooks/appointment-created": "Create appointment webhook",
            "/api/webhooks/appointment-updated": "Update appointment webhook"
        }
    }

@app.get("/health")
async def health():
    """Health check"""
    return {"status": "healthy", "service": "appointment"}

# Include routers
app.include_router(webhooks_router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
