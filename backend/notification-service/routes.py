from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models import Notification
from schemas import NotificationSchema

# SEGUIR EL MISMO PATRÓN QUE APPOINTMENT-SERVICE
# prefix="/notifications" aquí + prefix="/api" en main.py = /api/notifications/
router = APIRouter(prefix="/notifications", tags=["notifications"])

# Ruta: será /api/notifications/
@router.get("/", response_model=List[NotificationSchema])
def get_notifications(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all notifications"""
    notifications = db.query(Notification).order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
    return notifications

# Ruta: será /api/notifications/{notification_id}
@router.get("/{notification_id}", response_model=NotificationSchema)
def get_notification(notification_id: int, db: Session = Depends(get_db)):
    """Get specific notification by ID"""
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    return notification

# Ruta: será /api/notifications/user/{user_id}
@router.get("/user/{user_id}", response_model=List[NotificationSchema])
def get_user_notifications(user_id: int, db: Session = Depends(get_db)):
    """Get notifications for a specific user"""
    notifications = db.query(Notification).filter(Notification.user_id == user_id).all()
    return notifications

# Ruta: será /api/notifications/
@router.post("/", response_model=NotificationSchema)
def create_notification(
    user_id: int,
    user_email: str,
    message: str,
    notification_type: str = "manual",
    db: Session = Depends(get_db)
):
    """Create a new notification"""
    notification = Notification(
        user_id=user_id,
        user_email=user_email,
        message=message,
        notification_type=notification_type,
        title=f"Notification for user {user_id}"
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    return notification

# Ruta: será /api/notifications/{notification_id}/read
@router.put("/{notification_id}/read")
def mark_as_read(notification_id: int, db: Session = Depends(get_db)):
    """Mark notification as read"""
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    from datetime import datetime
    notification.read_at = datetime.utcnow()
    
    db.commit()
    return {"message": "Notification marked as read", "notification_id": notification_id}

# Ruta: será /api/notifications/{notification_id}
@router.delete("/{notification_id}")
def delete_notification(notification_id: int, db: Session = Depends(get_db)):
    """Delete a notification"""
    notification = db.query(Notification).filter(Notification.id == notification_id).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    db.delete(notification)
    db.commit()
    return {"message": "Notification deleted", "notification_id": notification_id}
