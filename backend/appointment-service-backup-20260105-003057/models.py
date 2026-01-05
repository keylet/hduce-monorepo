# backend/appointment-service/models.py - VERSIÓN CORREGIDA
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base

# Modelo de Especialidad
class Specialty(Base):
    __tablename__ = "specialties"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.now)

    doctors = relationship("Doctor", back_populates="specialty")

    def __repr__(self):
        return f"<Specialty {self.name}>"

# Modelo de Doctor - CORREGIDO para coincidir con base de datos REAL
class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(50), nullable=False)           # ← COINCIDE CON DB
    license_number = Column(String(50), nullable=False)    # ← COINCIDE CON DB
    specialty_id = Column(Integer, ForeignKey("specialties.id"), nullable=True)
    consultation_duration = Column(Integer, default=30)    # ← COINCIDE CON DB
    created_at = Column(DateTime, default=datetime.now)

    specialty = relationship("Specialty", back_populates="doctors")
    appointments = relationship("Appointment", back_populates="doctor")

    # Propiedad calculada para 'name' (porque no existe en DB)
    @property
    def name(self):
        # Usar user_id como nombre temporal
        return f"Doctor {self.user_id}"
    
    # Propiedad calculada para 'email'
    @property
    def email(self):
        return f"{self.user_id}@hospital.com"
    
    # Propiedad calculada para 'phone'
    @property
    def phone(self):
        return "555-XXXX"

    def __repr__(self):
        return f"<Doctor {self.user_id}>"

# Modelo de Cita
class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(String(100), nullable=False, index=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    appointment_date = Column(DateTime, nullable=False)
    reason = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    status = Column(String(20), default="scheduled", nullable=False)
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)

    doctor = relationship("Doctor", back_populates="appointments")

    def __repr__(self):
        return f"<Appointment {self.id} - {self.patient_id}>"
