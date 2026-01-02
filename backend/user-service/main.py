# backend/user-service/main.py - VERSIÓN CORREGIDA
from fastapi import FastAPI, Depends, HTTPException, Body  # ✅ Body agregado
from src.protected_routes import router as protected_router
from sqlalchemy.orm import Session
import models, schemas
from database import engine, get_db, Base
from typing import List
import uuid

# Create tables in database
Base.metadata.create_all(bind=engine)

app = FastAPI(title="User Service", version="1.0.0")

# ✅ INCLUIR RUTAS PROTEGIDAS
app.include_router(protected_router)


@app.get("/")
def read_root():
    return {"service": "user-service", "status": "running", "database": "postgresql"}

@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    # Verify database connection
    try:
        db.execute("SELECT 1")
        db_status = "connected"
    except Exception:
        db_status = "disconnected"
    
    return {
        "status": "healthy", 
        "service": "user-service",
        "database": db_status
    }

@app.post("/users", response_model=schemas.UserResponse)
def create_user(user: schemas.UserCreate = Body(...), db: Session = Depends(get_db)):  # ✅ CORREGIDO
    # Check if email already exists
    existing_user = db.query(models.UserDB).filter(models.UserDB.email == user.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create new user
    db_user = models.UserDB(**user.dict())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

@app.get("/users", response_model=List[schemas.UserResponse])
def get_all_users(db: Session = Depends(get_db)):
    users = db.query(models.UserDB).all()
    return users

@app.get("/users/{user_id}", response_model=schemas.UserResponse)
def get_user(user_id: str, db: Session = Depends(get_db)):
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    
    user = db.query(models.UserDB).filter(models.UserDB.id == user_uuid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

@app.put("/users/{user_id}", response_model=schemas.UserResponse)
def update_user(user_id: str, user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    
    # Find user
    user = db.query(models.UserDB).filter(models.UserDB.id == user_uuid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if new email is taken by another user
    if user_data.email != user.email:
        existing = db.query(models.UserDB).filter(
            models.UserDB.email == user_data.email,
            models.UserDB.id != user_uuid
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already registered by another user")
    
    # Update user data
    for key, value in user_data.dict().items():
        setattr(user, key, value)
    
    db.commit()
    db.refresh(user)
    
    return user

@app.delete("/users/{user_id}")
def delete_user(user_id: str, db: Session = Depends(get_db)):
    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid user ID format")
    
    user = db.query(models.UserDB).filter(models.UserDB.id == user_uuid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    
    return {"message": "User deleted successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)


