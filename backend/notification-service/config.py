# backend/notification-service/config.py
# ✅ Configuración específica para notificaciones (complementa shared-libraries)
import os
from typing import Optional

# NOTA: La configuración de base de datos, Redis, JWT viene de shared-libraries
# Esto es solo para configuración específica de notificaciones

# Email Configuration (específico para notificaciones)
SMTP_HOST: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER: str = os.getenv("SMTP_USER", "")
SMTP_PASS: str = os.getenv("SMTP_PASS", "")

# Simulation flags (for development - específico para notificaciones)
EMAIL_SIMULATION: bool = os.getenv("EMAIL_SIMULATION", "true").lower() == "true"
SMS_SIMULATION: bool = os.getenv("SMS_SIMULATION", "true").lower() == "true"

# Twilio (for SMS - optional - específico para notificaciones)
TWILIO_ACCOUNT_SID: Optional[str] = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN: Optional[str] = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER: Optional[str] = os.getenv("TWILIO_PHONE_NUMBER")

# RabbitMQ Configuration (puede venir de shared-libraries, pero lo mantenemos aquí por claridad)
RABBITMQ_HOST: str = os.getenv("RABBITMQ_HOST", "rabbitmq")
RABBITMQ_PORT: int = int(os.getenv("RABBITMQ_PORT", "5672"))
RABBITMQ_USER: str = os.getenv("RABBITMQ_USER", "admin")
RABBITMQ_PASSWORD: str = os.getenv("RABBITMQ_PASSWORD", "admin123")
