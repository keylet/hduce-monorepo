# backend/notification-service/routes.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta  # <-- IMPORTANTE: agregar timedelta
from sqlalchemy import func

from database import get_db
import models
import schemas

# ✅ CORREGIDO: Router sin prefix, las rutas están en raíz
router = APIRouter()

# ==================== NOTIFICACIONES BÁSICAS ====================

@router.get("/", response_model=List[schemas.Notification])  # <-- CAMBIADO de "/notifications" a "/"
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

@router.get("/{notification_id}", response_model=schemas.Notification)  # <-- CAMBIADO
async def get_notification(
    notification_id: int,
    db: Session = Depends(get_db)
):
    """Obtener una notificación específica"""
    notification = db.query(models.Notification).filter(models.Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notification

# ==================== ENVÍO DE EMAIL ====================

@router.post("/email")  # <-- CAMBIADO de "/notifications/email" a "/email"
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

# ==================== ENVÍO DE SMS ====================

@router.post("/sms")  # <-- CAMBIADO
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

# ==================== ENVÍO CON JSON BODY ====================

@router.post("/send")  # <-- CAMBIADO
async def send_notification_json(
    user_id: str,
    notification_type: str,
    message: str,
    subject: Optional[str] = None,
    recipient_email: Optional[str] = None,
    recipient_phone: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Enviar notificación usando JSON body"""
    
    if notification_type == "email" and not recipient_email:
        raise HTTPException(status_code=400, detail="Email requires recipient_email")
    
    if notification_type == "sms" and not recipient_phone:
        raise HTTPException(status_code=400, detail="SMS requires recipient_phone")
    
    if notification_type not in ["email", "sms"]:
        raise HTTPException(status_code=400, detail="notification_type must be 'email' or 'sms'")
    
    notification = models.Notification(
        user_id=user_id,
        notification_type=notification_type,
        subject=subject,
        message=message,
        recipient_email=recipient_email,
        recipient_phone=recipient_phone,
        status="pending",
        created_at=datetime.now()
    )
    
    db.add(notification)
    db.commit()
    db.refresh(notification)
    
    recipient = recipient_email if notification_type == "email" else recipient_phone
    print(f"[SIMULATION] {notification_type.upper()} sent to: {recipient}")
    
    return {
        "message": f"{notification_type.upper()} notification created successfully",
        "notification_id": notification.id,
        "type": notification_type,
        "recipient": recipient,
        "status": "pending"
    }

# ==================== RECORDATORIOS AUTOMÁTICOS ====================

@router.post("/appointment/reminder")  # <-- CAMBIADO
async def send_appointment_reminder(
    patient_id: str,
    doctor_name: str,
    appointment_date: str,
    patient_email: Optional[str] = None,
    patient_phone: Optional[str] = None,
    hours_before: int = 24,
    db: Session = Depends(get_db)
):
    """Enviar recordatorio automático de cita"""
    
    if not patient_email and not patient_phone:
        raise HTTPException(status_code=400, detail="At least one contact method (email or phone) is required")
    
    email_message = f"""
    Recordatorio de cita médica
    
    Tiene una cita programada en {hours_before} horas:
    
    Doctor: {doctor_name}
    Fecha y hora: {appointment_date}
    
    Por favor, llegue 15 minutos antes.
    
    Saludos,
    Hospital UCE - HDUCE
    """
    
    sms_message = f"Recordatorio: Cita con {doctor_name} en {hours_before}h ({appointment_date})"
    
    results = []
    
    # Enviar email si hay dirección
    if patient_email:
        email_notif = models.Notification(
            user_id=patient_id,
            notification_type="email",
            subject=f"Recordatorio de cita con {doctor_name}",
            message=email_message.strip(),
            recipient_email=patient_email,
            status="sent",
            sent_at=datetime.now(),
            created_at=datetime.now()
        )
        db.add(email_notif)
        db.flush()
        results.append({"type": "email", "id": email_notif.id})
        print(f"[SIMULATION] Appointment reminder email sent to {patient_email}")
    
    # Enviar SMS si hay teléfono
    if patient_phone:
        sms_notif = models.Notification(
            user_id=patient_id,
            notification_type="sms",
            message=sms_message,
            recipient_phone=patient_phone,
            status="sent",
            sent_at=datetime.now(),
            created_at=datetime.now()
        )
        db.add(sms_notif)
        db.flush()
        results.append({"type": "sms", "id": sms_notif.id})
        print(f"[SIMULATION] Appointment reminder SMS sent to {patient_phone}")
    
    db.commit()
    
    return {
        "message": f"Appointment reminders sent successfully",
        "total_notifications": len(results),
        "notifications": results,
        "patient_id": patient_id,
        "doctor": doctor_name,
        "appointment_date": appointment_date
    }

# ==================== ESTADÍSTICAS ====================

@router.get("/stats")  # <-- CAMBIADO
async def get_notification_stats(db: Session = Depends(get_db)):
    """Obtener estadísticas detalladas"""
    
    # Totales
    total = db.query(models.Notification).count()
    total_email = db.query(models.Notification).filter(models.Notification.notification_type == "email").count()
    total_sms = db.query(models.Notification).filter(models.Notification.notification_type == "sms").count()
    
    # Por estado
    pending = db.query(models.Notification).filter(models.Notification.status == "pending").count()
    sent = db.query(models.Notification).filter(models.Notification.status == "sent").count()
    failed = db.query(models.Notification).filter(models.Notification.status == "failed").count()
    
    # Últimas 24 horas
    last_24h = datetime.now() - timedelta(hours=24)  # <-- CORREGIDO: usar timedelta
    recent = db.query(models.Notification).filter(models.Notification.created_at >= last_24h).count()
    
    return {
        "summary": {
            "total_notifications": total,
            "email_notifications": total_email,
            "sms_notifications": total_sms,
            "recent_24h": recent
        },
        "status": {
            "pending": pending,
            "sent": sent,
            "failed": failed
        },
        "success_rate": round((sent / total * 100), 2) if total > 0 else 0
    }

@router.get("/stats/simple")  # <-- CAMBIADO
async def get_simple_stats(db: Session = Depends(get_db)):
    """Estadísticas simples"""
    total = db.query(models.Notification).count()
    emails = db.query(models.Notification).filter(models.Notification.notification_type == "email").count()
    sms_count = db.query(models.Notification).filter(models.Notification.notification_type == "sms").count()
    
    return {
        "total_notifications": total,
        "email_notifications": emails,
        "sms_notifications": sms_count,
        "pending": db.query(models.Notification).filter(models.Notification.status == "pending").count(),
        "sent": db.query(models.Notification).filter(models.Notification.status == "sent").count()
    }

# ==================== UTILIDAD ====================

@router.post("/test")  # <-- CAMBIADO
async def create_test_notification(db: Session = Depends(get_db)):
    """Crear notificación de prueba"""
    notification = models.Notification(
        user_id="test-user-" + datetime.now().strftime("%H%M%S"),
        notification_type="email",
        subject="Test Notification - " + datetime.now().strftime("%H:%M:%S"),
        message="This is an automated test notification",
        recipient_email="test@example.com",
        status="sent",
        sent_at=datetime.now(),
        created_at=datetime.now()
    )
    
    db.add(notification)
    db.commit()
    db.refresh(notification)
    
    return {
        "message": "Test notification created",
        "notification_id": notification.id,
        "created_at": notification.created_at.isoformat()
    }

@router.get("/health/detailed")  # <-- CAMBIADO
async def detailed_health_check(db: Session = Depends(get_db)):
    """Health check detallado"""
    from sqlalchemy import text
    
    db_status = "healthy"
    db_error = None
    
    try:
        db.execute(text("SELECT 1"))
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
        },
        "endpoints_available": [
            "GET /",
            "POST /email",
            "POST /sms",
            "POST /send",
            "POST /appointment/reminder",
            "GET /stats"
        ]
    }