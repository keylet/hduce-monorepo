"""
ULTRA SIMPLE Webhooks - Just make it work
"""
from fastapi import APIRouter, BackgroundTasks
import logging
from datetime import datetime
import asyncio

logger = logging.getLogger(__name__)
router = APIRouter()

async def call_n8n_simple(event_data: dict):
    """Call N8N in the simplest way possible"""
    import httpx
    try:
        url = "http://n8n:5678/webhook-test/appointment-created"
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            # Send request
            response = await client.post(
                url,
                json=event_data,
                headers={"Content-Type": "application/json"}
            )
            logger.info(f"N8N Simple: {response.status_code}")
    except Exception as e:
        logger.error(f"N8N Simple Error: {e}")

@router.get("/health")
async def health():
    """Simple health check"""
    return {
        "status": "healthy",
        "webhooks": "simple_mode",
        "timestamp": datetime.now().isoformat()
    }

@router.post("/appointment-created")
async def appointment_created(data: dict, background_tasks: BackgroundTasks):
    """Simple appointment created"""
    logger.info(f"Appointment created (simple): {data.get('id', 'unknown')}")
    
    event_data = {
        "event": "appointment.created",
        "data": data,
        "timestamp": datetime.now().isoformat()
    }
    
    # Send in background
    background_tasks.add_task(call_n8n_simple, event_data)
    
    return {"status": "queued", "id": data.get('id')}

@router.post("/appointment-updated")
async def appointment_updated(data: dict, background_tasks: BackgroundTasks):
    """Simple appointment updated"""
    logger.info(f"Appointment updated (simple): {data.get('id', 'unknown')}")
    
    event_data = {
        "event": "appointment.updated",
        "data": data,
        "timestamp": datetime.now().isoformat()
    }
    
    # Send in background
    background_tasks.add_task(call_n8n_simple, event_data)
    
    return {"status": "queued", "id": data.get('id')}
