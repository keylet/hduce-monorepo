import logging
from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from hduce_shared.config import settings

logger = logging.getLogger(__name__)

# Crear engine para auth_db
def get_auth_engine():
    db = settings.database
    password = 'postgres'
    connection_string = f"postgresql://{db.postgres_user}:{password}@{db.postgres_host}:{db.postgres_port}/{db.auth_db}"
    return create_engine(connection_string, pool_pre_ping=True)

# Base para modelos
Base = declarative_base()

# Modelo de Usuario
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    role = Column(String(50), default='user')
    phone = Column(String(20))
    address = Column(Text)
    city = Column(String(100))
    country = Column(String(100))
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    last_login = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'username': self.username,
            'full_name': self.full_name,
            'role': self.role,
            'phone': self.phone,
            'city': self.city,
            'country': self.country,
            'is_active': self.is_active,
            'is_verified': self.is_verified
        }

# Crear tablas
def create_tables():
    engine = get_auth_engine()
    Base.metadata.create_all(bind=engine)
    logger.info("✅ Tablas de auth-service creadas/verificadas")

# Obtener sesión de base de datos
def get_db():
    engine = get_auth_engine()
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
