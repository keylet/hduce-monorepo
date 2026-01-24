from pydantic_settings import BaseSettings
from typing import Optional

class DatabaseSettings(BaseSettings):
    postgres_host: str = "postgres"
    postgres_port: int = 5432
    postgres_user: str = "postgres"
    postgres_password: str = "postgres"
    
    # Bases de datos específicas
    auth_db: str = "auth_db"
    user_db: str = "user_db"
    appointment_db: str = "appointment_db"
    notification_db: str = "notification_db"
    medical_db: str = "medical_db"
    
    class Config:
        extra = "ignore"
        extra = "ignore"
        env_prefix = "POSTGRES_"

class RedisSettings(BaseSettings):
    redis_host: str = "redis"
    redis_port: int = 6379
    redis_url: str = "redis://redis:6379"
    
    class Config:
        extra = "ignore"
        extra = "ignore"
        env_prefix = "REDIS_"

class RabbitMQSettings(BaseSettings):
    rabbitmq_host: str = "rabbitmq"
    rabbitmq_port: int = 5672
    rabbitmq_user: str = "guest"
    rabbitmq_password: str = "guest"
    rabbitmq_vhost: str = "/"
    
    class Config:
        extra = "ignore"
        extra = "ignore"
        env_prefix = "RABBITMQ_"

class JWTSettings(BaseSettings):
    jwt_secret_key: str = "your-super-secret-jwt-key-change-this-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    
    class Config:
        extra = "ignore"
        extra = "ignore"
        env_prefix = "JWT_"

class ServicesSettings(BaseSettings):
    auth_service_url: str = "http://auth-service:8000"
    user_service_url: str = "http://user-service:8001"
    appointment_service_url: str = "http://appointment-service:8002"
    notification_service_url: str = "http://notification-service:8003"
    
    class Config:
        extra = "ignore"
        extra = "ignore"
        env_prefix = ""  # Sin prefijo, usa nombres exactos

class Settings(BaseSettings):
    database: DatabaseSettings = DatabaseSettings()
    redis: RedisSettings = RedisSettings()
    rabbitmq: RabbitMQSettings = RabbitMQConfig()
    jwt: JWTSettings = JWTSettings()
    services: ServicesSettings = ServicesSettings()
    
    class Config:
        extra = "ignore"
        extra = "ignore"
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()

