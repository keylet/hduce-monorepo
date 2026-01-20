from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date

# Importar locales
from database import get_db, Patient
from schemas import PatientCreate, PatientResponse
from auth_client import validate_token  # ← Cambiado: usar auth_client en lugar de auth_dependency

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "user", "shared_libs": True}

@router.post("/patients/", response_model=PatientResponse)
async def create_patient(
    patient: PatientCreate,
    db: Session = Depends(get_db),
    token_payload: dict = Depends(validate_token)
):
    """Create a new patient"""
    # Verificar que user_id en token coincida (si es necesario)
    db_patient = Patient(**patient.dict())
    db.add(db_patient)
    db.commit()
    db.refresh(db_patient)
    return db_patient

@router.get("/patients/{patient_id}", response_model=PatientResponse)
async def get_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    token_payload: dict = Depends(validate_token)
):
    """Get patient by ID"""
    db_patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not db_patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return db_patient

@router.get("/patients/user/{user_id}", response_model=PatientResponse)
async def get_patient_by_user_id(
    user_id: int,
    db: Session = Depends(get_db),
    token_payload: dict = Depends(validate_token)
):
    """Get patient by user_id"""
    db_patient = db.query(Patient).filter(Patient.user_id == user_id).first()
    if not db_patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return db_patient

@router.get("/me/patient", response_model=PatientResponse)
async def get_my_patient(
    db: Session = Depends(get_db),
    token_payload: dict = Depends(validate_token)
):
    """Get current user's patient profile"""
    # Aquí necesitas obtener el user_id del token
    user_email = token_payload.get("sub")
    # Esto es un ejemplo - necesitarías ajustar según tu modelo
    raise HTTPException(
        status_code=501, 
        detail="Endpoint en desarrollo - necesita integración con user service"
    )
