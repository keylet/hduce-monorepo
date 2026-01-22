"""
Webhook endpoints for appointment service - N8N integration
"""
import httpx
from fastapi import APIRouter, HTTPException, BackgroundTasks
from typing import Dict, Any
import logging
from datetime import datetime

logger = logging.getLogger(__name__)
router = APIRouter()

# N8N Webhook URL - ¡ACTUALIZA ESTA URL!
N8N_WEBHOOK_URL = "http://n8n:5678/webhook/test/appointment-created"

# Test the connection to N8N
async def test_n8n_connection() -> bool:
    """Test if N8N webhook is reachable"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            test_payload = {
                "event": "connection_test",
                "timestamp": datetime.now().isoformat(),
                "service": "appointment"
            }
            response = await client.post(
                N8N_WEBHOOK_URL,
                json=test_payload,
                headers={"Content-Type": "application/json"}
            )
            return response.status_code in [200, 201, 202]
    except Exception as e:
        logger.error(f"N8N connection test failed: {e}")
        return False

# Send appointment event to N8N
async def send_to_n8n(event_type: str, appointment_data: Dict[str, Any]):
    """Send appointment event to N8N webhook"""
    try:
        payload = {
            "event": event_type,
            "data": appointment_data,
            "timestamp": datetime.now().isoformat(),
            "service": "appointment-service"
        }
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                N8N_WEBHOOK_URL,
                json=payload,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code in [200, 201, 202]:
                logger.info(f"N8N webhook sent successfully: {event_type}")
            else:
                logger.warning(f"N8N webhook returned {response.status_code}: {response.text}")
                
    except Exception as e:
        logger.error(f"Failed to send to N8N: {e}")

# Health check endpoint
@router.get("/health")
async def webhook_health():
    """Health check for webhooks"""
    n8n_connected = await test_n8n_connection()
    
    return {
        "status": "healthy",
        "service": "appointment-webhooks",
        "n8n_integrated": n8n_connected,
        "n8n_url": N8N_WEBHOOK_URL,
        "timestamp": datetime.now().isoformat()
    }

# Webhook endpoint for appointment created
@router.post("/appointment-created")
async def appointment_created_webhook(
    background_tasks: BackgroundTasks,
    appointment_data: Dict[str, Any]
):
    """Receive appointment created events and forward to N8N"""
    
    logger.info(f"Appointment created webhook received: {appointment_data.get('id')}")
    
    # Forward to N8N in background
    background_tasks.add_task(
        send_to_n8n,
        "appointment.created",
        appointment_data
    )
    
    return {
        "status": "queued",
        "message": "Appointment event forwarded to N8N",
        "appointment_id": appointment_data.get('id')
    }

# Webhook endpoint for appointment updated
@router.post("/appointment-updated")
async def appointment_updated_webhook(
    background_tasks: BackgroundTasks,
    appointment_data: Dict[str, Any]
):
    """Receive appointment updated events and forward to N8N"""
    
    logger.info(f"Appointment updated webhook received: {appointment_data.get('id')}")
    
    # Forward to N8N in background
    background_tasks.add_task(
        send_to_n8n,
        "appointment.updated",
        appointment_data
    )
    
    return {
        "status": "queued",
        "message": "Appointment update forwarded to N8N",
        "appointment_id": appointment_data.get('id')
    }

