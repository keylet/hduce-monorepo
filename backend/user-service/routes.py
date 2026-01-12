# backend/user-service/routes.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date

# Importar locales
from database import get_db, Patient
from schemas import PatientCreate, PatientResponse
from auth_client import validate_token  # ← Cambiado: usar auth_client en lugar de auth_dependency

router = APIRouter()

# ==================== ENDPOINTS DE PACIENTES ====================

@router.post("/patients/", response_model=PatientResponse, status_code=status.HTTP_201_CREATED)
async def create_patient(
    patient: PatientCreate,
    db: Session = Depends(get_db),
    token_data: dict = Depends(validate_token)  # ← Usar validate_token de auth_client
):
    """Crear perfil de paciente"""
    # Verificar si ya existe un perfil para este user_id
    existing_patient = db.query(Patient).filter(Patient.user_id == patient.user_id).first()
    if existing_patient:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe un perfil de paciente para este usuario"
        )

    # Crear nuevo paciente
    db_patient = Patient(**patient.dict())
    db.add(db_patient)
    db.commit()
    db.refresh(db_patient)

    return db_patient

@router.get("/patients/{patient_id}", response_model=PatientResponse)
async def get_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    token_data: dict = Depends(validate_token)
):
    """Obtener perfil de paciente por ID"""
    patient = db.query(Patient).filter(Patient.patient_id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Paciente no encontrado")

    return patient

@router.get("/patients/user/{user_id}", response_model=PatientResponse)
async def get_patient_by_user_id(
    user_id: int,
    db: Session = Depends(get_db),
    token_data: dict = Depends(validate_token)
):
    """Obtener perfil de paciente por user_id"""
    patient = db.query(Patient).filter(Patient.user_id == user_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Paciente no encontrado")

    return patient

@router.get("/me/patient", response_model=PatientResponse)
async def get_my_patient_profile(
    db: Session = Depends(get_db),
    token_data: dict = Depends(validate_token)
):
    """Obtener perfil de paciente del usuario actual"""
    user_id = token_data.get("user_id")  # ← Cambiado: usar "user_id" en lugar de "sub"
    if not user_id:
        raise HTTPException(status_code=401, detail="Token inválido")

    patient = db.query(Patient).filter(Patient.user_id == user_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Perfil de paciente no encontrado")

    return patient

# ==================== HEALTH (ya existe en main) ====================

