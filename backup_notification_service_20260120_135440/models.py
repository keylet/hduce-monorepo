from sqlalchemy import Column, Integer, String, DateTime, Text, Boolean
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class Notification(Base):
    __tablename__ = "notifications"

    # ESTRUCTURA SEGÚN init-databases.sh (RAÍZ)
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)           # Integer según script
    user_email = Column(String(255), nullable=False)               # Existe según script
    notification_type = Column(String(100), nullable=False)        # String(100) según script
    title = Column(String(255), nullable=False)                    # Existe según script
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)                       # Boolean según script
    created_at = Column(DateTime, default=datetime.utcnow)
    read_at = Column(DateTime, nullable=True)                      # Existe según script

class EmailLog(Base):
    __tablename__ = "email_logs"

    id = Column(Integer, primary_key=True, index=True)
    notification_id = Column(Integer, nullable=False)
    sender = Column(String, nullable=False)
    recipients = Column(String, nullable=False)
    subject = Column(String, nullable=False)
    success = Column(Integer, default=0)
    error_message = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class SMSLog(Base):
    __tablename__ = "sms_logs"

    id = Column(Integer, primary_key=True, index=True)
    notification_id = Column(Integer, nullable=False)
    phone_number = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    success = Column(Integer, default=0)
    error_message = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
