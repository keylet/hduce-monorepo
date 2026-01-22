import sys
import os

# Añadir path para shared-libraries
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, '/app')  # Para Docker

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

# ? USAR BASE DESDE SHARED-LIBRARIES
from hduce_shared.database import Base
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Boolean, Date, Time
from sqlalchemy.orm import relationship
from datetime import datetime

from database import Base

class Specialty(Base):
    __tablename__ = "specialties"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)

    doctors = relationship("Doctor", back_populates="specialty")

class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), nullable=True)
    phone = Column(String(50), nullable=True)
    specialty_id = Column(Integer, ForeignKey("specialties.id"), nullable=True)
    is_active = Column(Boolean, default=True)

    # Relaciones
    specialty = relationship("Specialty", back_populates="doctors")
    appointments = relationship("Appointment", back_populates="doctor")

class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, nullable=False)
    patient_email = Column(String(255), nullable=False)
    patient_name = Column(String(255), nullable=False)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=True)
    appointment_date = Column(Date, nullable=False)
    appointment_time = Column(Time, nullable=False)
    status = Column(String(50), default="scheduled")
    reason = Column(Text, nullable=True)  # <-- CAMPO AÑADIDO
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)

    # Relación
    doctor = relationship("Doctor", back_populates="appointments")



