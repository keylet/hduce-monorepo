from pydantic_settings import BaseSettings
from typing import Optional
import os

class Settings(BaseSettings):
    # Application
    app_name: str = "HDUCE Notification Service"
    environment: str = os.getenv("ENVIRONMENT", "development")
    
    # Database
    database_url: str = os.getenv("DATABASE_URL", "postgresql://hduce_user:hduce_pass@localhost:5432/hduce_db")
    
    # Redis
    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379")
    
    # JWT
    jwt_secret: str = os.getenv("JWT_SECRET", "your_jwt_secret_key_here_change_in_production")
    jwt_algorithm: str = "HS256"
    
    # Email Configuration
    smtp_host: str = os.getenv("SMTP_HOST", "smtp.gmail.com")
    smtp_port: int = int(os.getenv("SMTP_PORT", "587"))
    smtp_user: str = os.getenv("SMTP_USER", "")
    smtp_pass: str = os.getenv("SMTP_PASS", "")
    
    # Simulation flags (for development)
    email_simulation: bool = os.getenv("EMAIL_SIMULATION", "true").lower() == "true"
    sms_simulation: bool = os.getenv("SMS_SIMULATION", "true").lower() == "true"
    
    # Twilio (for SMS - optional)
    twilio_account_sid: Optional[str] = os.getenv("TWILIO_ACCOUNT_SID")
    twilio_auth_token: Optional[str] = os.getenv("TWILIO_AUTH_TOKEN")
    twilio_phone_number: Optional[str] = os.getenv("TWILIO_PHONE_NUMBER")
    
    class Config:
        env_file = ".env"

# Instancia global de configuración
settings = Settings()
