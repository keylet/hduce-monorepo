from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import traceback

from database import get_db
from models import User
from schemas import UserCreate, UserResponse
from auth_client import validate_token

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "user-service"}

@router.post("/", response_model=UserResponse)
async def create_user(
    user: UserCreate,
    db: Session = Depends(get_db),
    token_data: dict = Depends(validate_token)
):
    """Create a new user"""
    try:
        # Verificar si el usuario ya existe
        db_user = db.query(User).filter(User.email == user.email).first()
        if db_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

        # Crear nuevo usuario
        db_user = User(
            name=user.name,
            email=user.email,
            age=user.age
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    except Exception as e:
        db.rollback()
        print(f"Error creating user: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating user: {str(e)}"
        )

@router.get("/", response_model=List[UserResponse])
async def get_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    token_data: dict = Depends(validate_token)
):
    """Get all users"""
    users = db.query(User).offset(skip).limit(limit).all()
    return users

# ENDPOINT /me - VERSIÓN CORREGIDA
@router.get("/me", response_model=UserResponse)
async def get_current_user(
    token_data: dict = Depends(validate_token),
    db: Session = Depends(get_db)
):
    """Get current user information from JWT token"""
    try:
        # Obtener email del token
        user_email = token_data.get("email")
        if not user_email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: no email found"
            )

        # Buscar usuario por email
        user = db.query(User).filter(User.email == user_email).first()
        
        if not user:
            print(f"Usuario {user_email} no encontrado en user_db. Creando nuevo...")
            # Extraer nombre del email (parte antes del @)
            username = user_email.split('@')[0] if '@' in user_email else "Usuario"
            
            # Crear nuevo usuario
            user = User(
                name=username,
                email=user_email,
                age=None  # Age es opcional y nullable=True
            )
            
            db.add(user)
            try:
                db.commit()
                db.refresh(user)
                print(f"Usuario creado exitosamente: {user_email}")
            except Exception as commit_error:
                db.rollback()
                print(f"Error al crear usuario: {traceback.format_exc()}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Error creating user in database: {str(commit_error)}"
                )
        
        return user

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in /me endpoint: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting user: {str(e)}"
        )

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    db: Session = Depends(get_db),
    token_data: dict = Depends(validate_token)
):
    """Get user by ID"""
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user
