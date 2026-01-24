from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy import func

from database import get_db
import models
import schemas

# Router sin prefix
router = APIRouter()

# ==================== HEALTH CHECKS - DEBEN IR PRIMERO ====================

@router.get("/health")
async def health_check():
    """Health check simple"""
    return {"status": "healthy", "service": "notification"}

@router.get("/health/detailed")
async def detailed_health_check(db: Session = Depends(get_db)):
    """Health check detallado"""
    db_status = "healthy"
    db_error = None
    
    try:
        db.execute("SELECT 1")
        table_count = db.query(models.Notification).count()
    except Exception as e:
        db_status = "unhealthy"
        db_error = str(e)
        table_count = 0
    
    return {
        "service": "notification-service",
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "database": {
            "status": db_status,
            "error": db_error,
            "notifications_count": table_count
        }
    }

# ==================== RUTAS DE NOTIFICACIONES ====================

@router.get("/", response_model=List[schemas.Notification])
async def list_notifications(
    skip: int = 0,
    limit: int = 100,
    user_id: Optional[str] = None,
    status: Optional[str] = None,
    notification_type: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Listar notificaciones con filtros"""
    query = db.query(models.Notification)

    if user_id:
        query = query.filter(models.Notification.user_id == user_id)
    if status:
        query = query.filter(models.Notification.status == status)
    if notification_type:
        query = query.filter(models.Notification.notification_type == notification_type)

    return query.order_by(models.Notification.created_at.desc()).offset(skip).limit(limit).all()

# ==================== RUTAS CON PARÁMETROS - DEBEN IR DESPUÉS ====================

@router.get("/{notification_id}", response_model=schemas.Notification)
async def get_notification(
    notification_id: int,
    db: Session = Depends(get_db)
):
    """Obtener una notificación específica"""
    notification = db.query(models.Notification).filter(models.Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notification

# ==================== RESTANTE DEL CÓDIGO (mantener igual) ====================

@router.post("/email")
async def send_email_notification(
    user_id: str,
    subject: str = "Notification from HDUCE",
    message: str = "",
    recipient_email: str = "",
    db: Session = Depends(get_db)
):
    """Enviar notificación por email"""
    if not recipient_email:
        raise HTTPException(status_code=400, detail="Recipient email is required")

    notification = models.Notification(
        user_id=user_id,
        notification_type="email",
        subject=subject,
        message=message,
        recipient_email=recipient_email,
        status="pending",
        created_at=datetime.now()
    )

    db.add(notification)
    db.commit()
    db.refresh(notification)

    print(f"[SIMULATION] Email sent to: {recipient_email}")

    return {
        "message": "Email notification created successfully",
        "notification_id": notification.id,
        "recipient": recipient_email,
        "status": "pending"
    }

@router.post("/sms")
async def send_sms_notification(
    user_id: str,
    message: str = "",
    recipient_phone: str = "",
    db: Session = Depends(get_db)
):
    """Enviar notificación por SMS"""
    if not recipient_phone:
        raise HTTPException(status_code=400, detail="Recipient phone is required")

    notification = models.Notification(
        user_id=user_id,
        notification_type="sms",
        message=message,
        recipient_phone=recipient_phone,
        status="pending",
        created_at=datetime.now()
    )

    db.add(notification)
    db.commit()
    db.refresh(notification)

    print(f"[SIMULATION] SMS sent to: {recipient_phone}")

    return {
        "message": "SMS notification created successfully",
        "notification_id": notification.id,
        "recipient": recipient_phone,
        "status": "pending"
    }

# [Mantener el resto del código original...]
