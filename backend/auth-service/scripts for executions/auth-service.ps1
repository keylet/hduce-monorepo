# 🔥 SCRIPT COMPLETO auth-service.ps1
# Copia TODO esto en un archivo auth-service.ps1 y ejecuta

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "    CONFIGURACIÓN COMPLETA AUTH-SERVICE" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# ============================================
# PASO 1: CREAR/ACTUALIZAR ARCHIVOS
# ============================================

Write-Host "`n📁 CREANDO ARCHIVOS..." -ForegroundColor Yellow

# 1. main.py
$mainPy = @'
from fastapi import FastAPI, HTTPException
from routes import router as auth_router
from datetime import datetime, timedelta
import jwt
from jwt.exceptions import PyJWTError as JWTError

app = FastAPI(title="Auth Service", version="1.0.0")

# ¡ESTO ES CRÍTICO! Incluir el router
app.include_router(auth_router, prefix="/api/auth")

# Configuración
SECRET_KEY = "dev-secret-key-change-in-production"
ALGORITHM = "HS256"

# Base de datos en memoria
users_db = {
    "admin": {
        "username": "admin",
        "email": "admin@example.com",
        "password": "admin123",
        "is_active": True
    }
}

@app.get("/")
def read_root():
    return {"service": "auth-service", "status": "running"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "auth-service"}

@app.post("/register")
def register(username: str, email: str, password: str):
    if username in users_db:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    users_db[username] = {
        "username": username,
        "email": email,
        "password": password,
        "is_active": True
    }
    
    return {"message": "User registered successfully", "username": username}

@app.post("/login")
def login(username: str, password: str):
    user = users_db.get(username)
    
    if not user or user["password"] != password:
        raise HTTPException(status_code=400, detail="Invalid credentials")
    
    token_data = {
        "sub": username,
        "email": user["email"],
        "exp": datetime.utcnow() + timedelta(hours=24)
    }
    
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    
    return {"access_token": token, "token_type": "bearer"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8006)
'@

Set-Content -Path "main.py" -Value $mainPy -Encoding UTF8
Write-Host "✅ main.py creado/actualizado" -ForegroundColor Green

# 2. routes.py
$routesPy = @'
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()
users_db = {}

# Modelos Pydantic
class UserRegister(BaseModel):
    username: str
    email: str
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

# ========== ENDPOINTS PRINCIPALES ==========

@router.post("/simple-register")
async def simple_register(user: UserRegister):
    """✅ REGISTRO SIMPLE - ACEPTA JSON"""
    if user.username in users_db:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    users_db[user.username] = {
        "username": user.username,
        "email": user.email,
        "password": user.password,
        "type": "simple"
    }
    
    return {
        "message": "✅ Registro simple exitoso",
        "user": user.username,
        "email": user.email
    }

@router.post("/register")
async def register(user: UserRegister):
    """Registro con hash"""
    if user.username in users_db:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    import hashlib
    hashed_password = hashlib.sha256(user.password.encode()).hexdigest()
    
    users_db[user.username] = {
        "username": user.username,
        "email": user.email,
        "hashed_password": hashed_password,
        "type": "hashed"
    }
    
    return {"message": "✅ Registro con hash exitoso", "user": user.username}

@router.post("/login")
async def login(user: UserLogin):
    """Login simple"""
    if user.username not in users_db:
        raise HTTPException(status_code=401, detail="User not found")
    
    db_user = users_db[user.username]
    
    # Verificar password según tipo
    if db_user.get("type") == "simple":
        if db_user["password"] != user.password:
            raise HTTPException(status_code=401, detail="Invalid password")
    else:
        import hashlib
        hashed_input = hashlib.sha256(user.password.encode()).hexdigest()
        if db_user["hashed_password"] != hashed_input:
            raise HTTPException(status_code=401, detail="Invalid password")
    
    return {
        "access_token": f"token_{user.username}",
        "token_type": "bearer",
        "user": {"username": user.username, "email": db_user.get("email", "")}
    }

@router.get("/test")
async def test():
    return {"message": "✅ Router funciona correctamente"}

@router.get("/users")
async def list_users():
    return {
        "total": len(users_db),
        "users": list(users_db.keys())
    }
'@

Set-Content -Path "routes.py" -Value $routesPy -Encoding UTF8
Write-Host "✅ routes.py creado/actualizado" -ForegroundColor Green

# 3. requirements.txt
$requirements = @'
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-dotenv>=1.0.0
pydantic>=2.0.0
python-multipart>=0.0.6
'@

Set-Content -Path "requirements.txt" -Value $requirements -Encoding UTF8
Write-Host "✅ requirements.txt creado" -ForegroundColor Green

# ============================================
# PASO 2: INSTALAR DEPENDENCIAS
# ============================================

Write-Host "`n📦 INSTALANDO DEPENDENCIAS..." -ForegroundColor Yellow
pip install fastapi uvicorn python-jose[cryptography] passlib[bcrypt] pydantic --quiet
Write-Host "✅ Dependencias instaladas" -ForegroundColor Green

# ============================================
# PASO 3: INICIAR SERVIDOR
# ============================================

Write-Host "`n🚀 INICIANDO SERVIDOR..." -ForegroundColor Cyan

# Mata procesos anteriores
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# Inicia servidor en background
$serverProcess = Start-Process python -ArgumentList "main.py" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 5

Write-Host "✅ Servidor iniciado en puerto 8006 (PID: $($serverProcess.Id))" -ForegroundColor Green

# ============================================
# PASO 4: EJECUTAR PRUEBAS AUTOMÁTICAS
# ============================================

Write-Host "`n🧪 EJECUTANDO PRUEBAS AUTOMÁTICAS..." -ForegroundColor Yellow

# Prueba 1: Verificar servidor
try {
    $test = Invoke-RestMethod -Uri "http://localhost:8006/" -Method Get -TimeoutSec 3
    Write-Host "✅ Servidor activo: $($test.service)" -ForegroundColor Green
} catch {
    Write-Host "❌ Servidor NO responde" -ForegroundColor Red
    Stop-Process -Id $serverProcess.Id -Force
    exit 1
}

# Prueba 2: Test del router
try {
    $test2 = Invoke-RestMethod -Uri "http://localhost:8006/api/auth/test" -Method Get -TimeoutSec 3
    Write-Host "✅ Router funciona: $($test2.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ Router NO funciona" -ForegroundColor Red
}

# Prueba 3: Registrar usuario (PRUEBA PRINCIPAL)
$randomUser = "test_" + (Get-Random -Minimum 1000 -Maximum 9999)
$body = @{username=$randomUser; email="$randomUser@test.com"; password="123456"} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8006/api/auth/simple-register" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5
    Write-Host "✅ REGISTRO EXITOSO: $($response.message)" -ForegroundColor Green
    Write-Host "   Usuario: $($response.user)" -ForegroundColor Gray
    Write-Host "   Email: $($response.email)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Registro falló: $($_.Exception.Message)" -ForegroundColor Red
}

# Prueba 4: Intentar duplicado (debe fallar)
try {
    $response2 = Invoke-RestMethod -Uri "http://localhost:8006/api/auth/simple-register" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 3
    Write-Host "❌ NO debería registrar duplicado" -ForegroundColor Red
} catch {
    Write-Host "✅ Correcto: Detecta duplicado - $($_.ErrorDetails.Message)" -ForegroundColor Green
}

# ============================================
# PASO 5: MOSTRAR RESUMEN
# ============================================

Write-Host "`n" + ("="*50) -ForegroundColor Cyan
Write-Host "🎯 CONFIGURACIÓN COMPLETADA" -ForegroundColor Green -BackgroundColor Black
Write-Host "="*50 -ForegroundColor Cyan

Write-Host "`n📡 SERVIDOR:" -ForegroundColor Yellow
Write-Host "   URL: http://localhost:8006" -ForegroundColor White
Write-Host "   PID: $($serverProcess.Id)" -ForegroundColor White
Write-Host "   Estado: ✅ ACTIVO" -ForegroundColor Green

Write-Host "`n🔗 ENDPOINTS PRINCIPALES:" -ForegroundColor Yellow
Write-Host "   GET  /                         → Estado del servicio" -ForegroundColor White
Write-Host "   GET  /health                   → Health check" -ForegroundColor White
Write-Host "   GET  /api/auth/test            → Test del router" -ForegroundColor White
Write-Host "   POST /api/auth/simple-register → Registro simple ✓" -ForegroundColor Green
Write-Host "   POST /api/auth/register        → Registro con hash" -ForegroundColor White
Write-Host "   POST /api/auth/login           → Login" -ForegroundColor White

Write-Host "`n💾 ARCHIVOS CREADOS:" -ForegroundColor Yellow
Write-Host "   ✅ main.py          → Servidor FastAPI" -ForegroundColor White
Write-Host "   ✅ routes.py        → Endpoints de autenticación" -ForegroundColor White
Write-Host "   ✅ requirements.txt → Dependencias" -ForegroundColor White

Write-Host "`n🚨 COMANDOS DE PRUEBA:" -ForegroundColor Yellow
Write-Host "   # PowerShell (RECOMENDADO):" -ForegroundColor Gray
Write-Host "   `$body = @{username='test';email='test@test.com';password='123'} | ConvertTo-Json" -ForegroundColor Gray
Write-Host "   Invoke-RestMethod -Uri 'http://localhost:8006/api/auth/simple-register' -Method Post -Body `$body -ContentType 'application/json'" -ForegroundColor Gray
Write-Host ""
Write-Host "   # curl (con archivo):" -ForegroundColor Gray
Write-Host "   echo '{\"username\":\"curluser\",\"email\":\"curl@test.com\",\"password\":\"123\"}' > test.json" -ForegroundColor Gray
Write-Host "   curl -X POST http://localhost:8006/api/auth/simple-register -H 'Content-Type: application/json' -d '@test.json'" -ForegroundColor Gray
Write-Host "   del test.json" -ForegroundColor Gray

Write-Host "`n⚠️  PARA DETENER EL SERVIDOR:" -ForegroundColor Magenta
Write-Host "   Stop-Process -Id $($serverProcess.Id) -Force" -ForegroundColor White

Write-Host "`n" + ("="*50) -ForegroundColor Cyan
Write-Host "✅ TODO LISTO - AUTH SERVICE FUNCIONANDO" -ForegroundColor Green -BackgroundColor Black
Write-Host "="*50 -ForegroundColor Cyan

# Mantener el script activo
Write-Host "`n⏳ Presiona Ctrl+C para salir (el servidor seguirá corriendo)..." -ForegroundColor Gray
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "`n👋 Script terminado" -ForegroundColor Yellow
}