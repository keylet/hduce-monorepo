from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
import models
import schemas
from database import engine, get_db
from routes import appointment_router, doctor_router, specialty_router

# Crear tablas en la base de datos
models.Base.metadata.create_all(bind=engine)

# Crear aplicacion FastAPI
app = FastAPI(
    title="HDUCE Appointment Service",
    description="Microservicio para gestion de citas medicas",
    version="1.0.0",
    openapi_tags=[
        {"name": "Appointments", "description": "Operaciones con citas"},
        {"name": "Doctors", "description": "Gestion de doctores"},
        {"name": "Specialties", "description": "Especialidades medicas"},
    ],
    default_response_class=JSONResponse
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En produccion, especificar dominios
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir routers
app.include_router(appointment_router, prefix="/appointments", tags=["Appointments"])
app.include_router(doctor_router, prefix="/doctors", tags=["Doctors"])
app.include_router(specialty_router, prefix="/specialties", tags=["Specialties"])

@app.get("/")
async def root():
    return {
        "service": "Appointment Service",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "appointment-service"}

# Endpoint para verificar conexion a base de datos
@app.get("/db-check")
async def db_check(db: Session = Depends(get_db)):
    try:
        # Intentar una consulta simple
        db.execute("SELECT 1")
        return {"database": "connected"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Database connection error: {str(e)}"
        )

# Crear foreign keys después de iniciar
@app.on_event("startup")
async def startup_event():
    try:
        from foreign_keys import create_foreign_keys
        create_foreign_keys()
        print("Foreign keys creadas exitosamente")
    except Exception as e:
        print(f"Error creando foreign keys: {e}")

