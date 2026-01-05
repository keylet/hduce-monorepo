from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from typing import List
from datetime import datetime
from pydantic import BaseModel
from contextlib import asynccontextmanager

# Configuración de base de datos
DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/appointment_db"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Modelos simplificados
class Doctor(Base):
    __tablename__ = "doctors"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100))
    email = Column(String(100))
    phone = Column(String(20))
    
class Appointment(Base):
    __tablename__ = "appointments"
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(String(100))
    doctor_id = Column(Integer, ForeignKey("doctors.id"))
    appointment_date = Column(DateTime)
    reason = Column(String(500))
    notes = Column(String(500))
    status = Column(String(20), default="scheduled")

# Schemas Pydantic
class DoctorBase(BaseModel):
    id: int
    name: str
    email: str
    phone: str
    
    class Config:
        from_attributes = True

# Crear tablas
Base.metadata.create_all(bind=engine)

# Dependencia de base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Lifespan manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("✅ Appointment Service Starting...")
    yield
    # Shutdown
    print("❌ Appointment Service Shutting down...")

# Crear la app
app = FastAPI(
    title="Appointment Service MINIMAL",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# RUTAS - ORDEN CRÍTICO

# 1. RUTAS ESPECÍFICAS PRIMERO
@app.get("/appointments/doctors", response_model=List[DoctorBase])
def get_doctors(db: Session = Depends(get_db)):
    """Obtener todos los doctores"""
    return db.query(Doctor).all()

# 2. RUTA RAÍZ (sin parámetros)
@app.get("/appointments", response_model=List[dict])
def get_appointments(db: Session = Depends(get_db)):
    """Obtener todas las citas"""
    return db.query(Appointment).all()

# 3. RUTA CON PARÁMETRO - AL FINAL
@app.get("/appointments/{item_id}")
def get_appointment(item_id: int, db: Session = Depends(get_db)):
    """Obtener una cita específica"""
    appointment = db.query(Appointment).filter(Appointment.id == item_id).first()
    if not appointment:
        return {"error": "Appointment not found"}
    return appointment

# Health check
@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "appointment-minimal"}

@app.get("/")
def root():
    return {
        "message": "Appointment Service MINIMAL",
        "endpoints": {
            "doctors": "/appointments/doctors",
            "appointments": "/appointments",
            "health": "/health"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
