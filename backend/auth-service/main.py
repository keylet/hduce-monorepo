# backend/auth-service/main.py
from fastapi import FastAPI, HTTPException
from routes import router as auth_router
from datetime import datetime, timedelta
from jose import jwt
from jose.exceptions import JWTError
from pydantic import BaseModel

app = FastAPI(
    title="HDUCE Auth Service",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

app.include_router(auth_router, prefix="/auth")

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

class User(BaseModel):
    username: str
    password: str

@app.post("/login")
async def login(user: User):
    db_user = users_db.get(user.username)
    if not db_user or db_user["password"] != user.password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Create token
    token_data = {
        "sub": user.username,
        "email": db_user["email"],
        "exp": datetime.utcnow() + timedelta(hours=24)
    }
    token = jwt.encode(token_data, SECRET_KEY, algorithm=ALGORITHM)
    
    return {"access_token": token, "token_type": "bearer"}

@app.get("/verify")
async def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return {"valid": True, "username": payload.get("sub")}
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "auth-service"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
