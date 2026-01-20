from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import SessionLocal
from models import Notification
from schemas import NotificationSchema, NotificationCreate

router = APIRouter(prefix="/notifications", tags=["notifications"])

# Dependency para obtener sesión de BD
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/", response_model=List[NotificationSchema])
def get_notifications(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Obtener todas las notificaciones"""
    notifications = db.query(Notification).offset(skip).limit(limit).all()
    return notifications

@router.get("/{notification_id}", response_model=NotificationSchema)
def get_notification(notification_id: int, db: Session = Depends(get_db)):
    """Obtener una notificación específica"""
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    if notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notification

@router.get("/user/{user_id}", response_model=List[NotificationSchema])
def get_user_notifications(user_id: int, db: Session = Depends(get_db)):
    """Obtener notificaciones de un usuario específico"""
    notifications = db.query(Notification).filter(Notification.user_id == user_id).all()
    return notifications

@router.post("/", response_model=NotificationSchema)
def create_notification(notification: NotificationCreate, db: Session = Depends(get_db)):
    """Crear una notificación manualmente (para pruebas)"""
    db_notification = Notification(
        user_id=notification.user_id,
        user_email=notification.user_email,
        message=notification.message,
        notification_type=notification.notification_type,
        is_read=notification.is_read
    )
    db.add(db_notification)
    db.commit()
    db.refresh(db_notification)
    return db_notification

@router.put("/{notification_id}/read")
def mark_as_read(notification_id: int, db: Session = Depends(get_db)):
    """Marcar una notificación como leída"""
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    if notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    db.commit()
    return {"message": "Notification marked as read"}

@router.delete("/{notification_id}")
def delete_notification(notification_id: int, db: Session = Depends(get_db)):
    """Eliminar una notificación"""
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    if notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    db.delete(notification)
    db.commit()
    return {"message": "Notification deleted"}
