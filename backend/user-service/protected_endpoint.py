rom auth_client import auth_client

@app.get("/protected-profile")
async def get_protected_profile(authorization: str = Header(None)):
    """Endpoint protegido que valida token con auth-service"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing authorization header")
    
    token = authorization.split(" ")[1]
    
    # Llamar al auth-service para validar token
    user_data = await auth_client.validate_token(token)
    
    if not user_data:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    # Simular obtención de perfil de usuario
    return {
        "message": "Protected user profile",
        "user_id": user_data.get("user_id"),
        "email": user_data.get("email"),
        "profile": {
            "name": "John Doe",
            "role": "user",
            "created_at": "2024-01-01"
        }
    }

@app.on_event("shutdown")
async def shutdown_event():
    """Cerrar cliente HTTP al apagar"""
    await auth_client.close()

