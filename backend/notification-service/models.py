# backend/notification-service/models.py
# ✅ ACTUALIZADO para usar shared-libraries
from sqlalchemy import Column, Integer, String, Text, DateTime, Enum
from sqlalchemy.sql import func
import enum

# Importar Base desde shared-libraries (reemplaza declarative_base)
from hduce_shared.database import Base, TimestampMixin

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

# Modelo principal de Notificacion - Usa TimestampMixin
class Notification(Base, TimestampMixin):
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

    # Tiempos (TimestampMixin ya proporciona created_at y updated_at)
    # ¡No necesitamos definirlos manualmente!
    scheduled_at = Column(DateTime(timezone=True), nullable=True)
    sent_at = Column(DateTime(timezone=True), nullable=True)

    # Campos para reintentos
    retry_count = Column(Integer, default=0)
    max_retries = Column(Integer, default=3)
    last_error = Column(Text, nullable=True)

    def __repr__(self):
        return f"<Notification(id={self.id}, type={self.notification_type}, status={self.status})>"
