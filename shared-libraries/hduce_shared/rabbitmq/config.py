"""
Configuration module for RabbitMQ in HDuce shared library
Compatible with Pydantic v2.4+
"""
from typing import Optional
import os

try:
    # Try pydantic-settings first (for Pydantic v2.4+)
    from pydantic_settings import BaseSettings, SettingsConfigDict
    from pydantic import Field
    PYDANTIC_V2_4 = True
except ImportError:
    # Fallback to older Pydantic
    try:
        from pydantic import BaseSettings, Field
        PYDANTIC_V2_4 = False
    except ImportError:
        raise ImportError("Neither pydantic nor pydantic-settings are installed")

class RabbitMQConfig(BaseSettings):
    """RabbitMQ configuration settings"""

    host: str = Field(default="rabbitmq", description="RabbitMQ host")
    port: int = Field(default=5672, description="RabbitMQ port")
    username: str = Field(default="guest", description="RabbitMQ username")
    password: str = Field(default="guest", description="RabbitMQ password")
    virtual_host: str = Field(default="/", description="RabbitMQ virtual host")
    
    # Campos para appointment events (compatibles con RabbitMQPublisher)
    appointment_exchange: str = Field(default="appointments", description="Appointment exchange name")
    appointment_queue: str = Field(default="appointment_notifications", description="Appointment queue name")
    appointment_routing_key: str = Field(default="notification.created", description="Appointment routing key")
    
    # Campos genéricos (para backward compatibility)
    exchange: str = Field(default="appointments", description="Default exchange name")
    queue: str = Field(default="appointment_notifications", description="Default queue name")
    routing_key: str = Field(default="notification.created", description="Default routing key")
    
    heartbeat: int = Field(default=600, description="Heartbeat timeout in seconds")
    blocked_connection_timeout: int = Field(default=300, description="Blocked connection timeout")

    if PYDANTIC_V2_4:
        # For Pydantic v2.4+ with pydantic-settings
        model_config = SettingsConfigDict(
            env_prefix="RABBITMQ_",
            case_sensitive=False,
            env_file=".env",
            extra="ignore"
        )
    else:
        # For older Pydantic
        class Config:
            env_prefix = "RABBITMQ_"
            case_sensitive = False

    @classmethod
    def from_env(cls) -> 'RabbitMQConfig':
        """Create configuration from environment variables"""
        return cls()

# Convenience constant for default configuration
DEFAULT_CONFIG = RabbitMQConfig()
