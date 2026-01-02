from sqlalchemy import Column, Integer, String, DateTime, Text, Boolean, Enum
from sqlalchemy.sql import func
from database import Base
import enum

# Enumeracion para tipos de notificacion
class NotificationType(str, enum.Enum):
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"
    IN_APP = "in_app"

# Enumeracion para estados de notificacion
class NotificationStatus(str, enum.Enum):
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    DELIVERED = "delivered"
    READ = "read"

# Modelo principal de Notificacion
class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, nullable=False, index=True)  # UUID del usuario
    notification_type = Column(Enum(NotificationType), nullable=False)
    status = Column(Enum(NotificationStatus), default=NotificationStatus.PENDING)
    
    # Contenido
    subject = Column(String(255), nullable=True)
    message = Column(Text, nullable=False)
    
    # Metadata
    recipient_email = Column(String(255), nullable=True)
    recipient_phone = Column(String(20), nullable=True)
    
    # Referencia a citas (solo ID, sin foreign key)
    appointment_id = Column(Integer, nullable=True)
    
    # Tiempos
    scheduled_at = Column(DateTime(timezone=True), nullable=True)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Campos para reintentos
    retry_count = Column(Integer, default=0)
    max_retries = Column(Integer, default=3)
    last_error = Column(Text, nullable=True)
    
    def __repr__(self):
        return f"<Notification {self.id} - {self.notification_type} - {self.status}>"

# Modelo para logs de email
class EmailLog(Base):
    __tablename__ = "email_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    notification_id = Column(Integer)  # Solo referencia, sin foreign key
    
    # Datos del email
    sender = Column(String(255))
    recipients = Column(Text)
    subject = Column(String(255))
    body = Column(Text)
    
    # Resultado
    success = Column(Boolean, default=False)
    error_message = Column(Text, nullable=True)
    message_id = Column(String(255), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())

# Modelo para logs de SMS
class SMSLog(Base):
    __tablename__ = "sms_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    notification_id = Column(Integer)  # Solo referencia, sin foreign key
    
    # Datos del SMS
    phone_number = Column(String(20))
    message = Column(Text)
    
    # Resultado
    success = Column(Boolean, default=False)
    error_message = Column(Text, nullable=True)
    provider_message_id = Column(String(255), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
