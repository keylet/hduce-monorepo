from fastapi import FastAPI, HTTPException
from routes import router as auth_router  # <-- Cambiado a routes (NO routes_fixed)
from datetime import datetime, timedelta
import jwt
from jwt.exceptions import PyJWTError as JWTError

app = FastAPI(title="Auth Service", version="1.0.0")

# ¡¡¡ESTO ES LO MÁS IMPORTANTE!!! 
app.include_router(auth_router, prefix="/api/auth")

# Simple config
SECRET_KEY = "dev-secret-key-change-in-production"
ALGORITHM = "HS256"

# Simple in-memory database
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
    
    # Create JWT token
    token_data = {
        "sub": username,
        "email": user["email"],
        "exp": datetime.utcnow() + timedelta(hours=24)
    }
    
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    
    return {"access_token": token, "token_type": "bearer"}

@app.get("/verify/{token}")
def verify_token_endpoint(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return {"valid": True, "user": payload.get("sub"), "expires": payload.get("exp")}
    except JWTError:
        raise HTTPException(status_code=400, detail="Invalid token")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8007)  # <-- Puerto NUEVO 8006

# === ENDPOINT DE PRUEBA SIMPLE ===
from pydantic import BaseModel

class TestData(BaseModel):
    username: str
    email: str
    password: str

@app.post("/test-json")
def test_json(data: TestData):
    return {
        "status": "success",
        "received": {
            "username": data.username,
            "email": data.email,
            "password": data.password
        },
        "message": "JSON recibido correctamente"
    }

@app.post("/test-raw")
def test_raw(body: dict):
    return {
        "status": "success", 
        "raw_body": body,
        "message": "Raw body recibido"
    }

# ====== ENDPOINTS DE PRUEBA ======
from pydantic import BaseModel

class TestUser(BaseModel):
    username: str
    email: str
    password: str

@app.post("/test-json")
def test_json_endpoint(user: TestUser):
    return {
        "status": "success",
        "message": "✅ JSON recibido correctamente",
        "data": {
            "username": user.username,
            "email": user.email,
            "password": user.password
        }
    }

@app.post("/test-raw")
def test_raw_endpoint(body: dict):
    return {
        "status": "success",
        "message": "✅ Raw body recibido",
        "raw_data": body
    }

@app.post("/test-simple")
def test_simple_endpoint(username: str, email: str, password: str):
    return {
        "status": "success",
        "message": "✅ Parámetros simples recibidos",
        "data": {"username": username, "email": email, "password": password}
    }




