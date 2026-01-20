from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class NotificationBase(BaseModel):
    user_id: int
    user_email: str
    message: str
    notification_type: str = "appointment_created"
    is_read: bool = False

class NotificationCreate(NotificationBase):
    pass

class NotificationSchema(NotificationBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True
