# test_minimal.py - Servicio mínimo para prueba
from fastapi import FastAPI, Depends, HTTPException
from fastapi.security import HTTPBearer
from jose import jwt
import uvicorn
from dotenv import load_dotenv
import os

# Cargar .env
load_dotenv()

app = FastAPI()
security = HTTPBearer()

# Configuración
SECRET_KEY = os.getenv("SECRET_KEY", "default_secret_key_para_desarrollo")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

print(f"=== CONFIGURACIÓN ===")
print(f"SECRET_KEY: {'*' * len(SECRET_KEY)}")
print(f"ALGORITHM: {ALGORITHM}")

async def simple_validate(credentials = Depends(security)):
    token = credentials.credentials
    print(f"Validando token: {token[:50]}...")
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        print(f"✅ Token válido para: {payload.get('sub')}")
        return payload
    except Exception as e:
        print(f"❌ Error validando token: {e}")
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/test-create")
async def test_create(data: dict, user = Depends(simple_validate)):
    return {"success": True, "data": data, "user": user}

@app.get("/test-protected")
async def test_protected(user = Depends(simple_validate)):
    return {"message": "Access granted", "user": user}

@app.get("/health")
async def health():
    return {"status": "ok"}

if __name__ == "__main__":
    print("=== INICIANDO SERVIDOR DE PRUEBA EN PUERTO 8002 ===")
    uvicorn.run(app, host="0.0.0.0", port=8002, reload=True)
