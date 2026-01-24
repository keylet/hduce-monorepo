import sys
sys.path.append("shared-libraries")
sys.path.append("backend/auth-service")

print("=== TEST DIRECTO DEL LOGIN ===")

# 1. Verificar imports
try:
    from hduce_shared.config import settings
    from hduce_shared.auth import JWTManager
    print("✅ imports de shared-libraries OK")
except Exception as e:
    print(f"❌ Error en imports shared: {e}")
    sys.exit(1)

# 2. Configurar JWT
try:
    JWTManager.configure(
        secret_key=settings.jwt.jwt_secret_key,
        algorithm=settings.jwt.jwt_algorithm,
        access_token_expire_minutes=settings.jwt.jwt_access_token_expire_minutes
    )
    print("✅ JWTManager configurado")
except Exception as e:
    print(f"❌ Error configurando JWT: {e}")
    sys.exit(1)

# 3. Probar crear token
try:
    token = JWTManager.create_access_token({"sub": "test", "user_id": 1, "role": "patient"})
    print(f"✅ Token creado: {token[:50]}...")
except Exception as e:
    print(f"❌ Error creando token: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# 4. Probar conexión a DB
try:
    from database import get_auth_engine, User
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy import or_
    
    engine = get_auth_engine()
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    # Buscar usuario
    user = db.query(User).filter(or_(User.username == "test_user", User.email == "test_user")).first()
    print(f"✅ Conexión DB OK. Usuario encontrado: {user}")
    
    if user:
        print(f"  ID: {user.id}")
        print(f"  Username: {user.username}")
        print(f"  Email: {user.email}")
        print(f"  Hash: {user.hashed_password[:30]}...")
        
        # Probar verify_password
        import auth_utils
        is_valid = auth_utils.verify_password("test123", user.hashed_password)
        print(f"  Password válido: {is_valid}")
    
    db.close()
except Exception as e:
    print(f"❌ Error con DB: {e}")
    import traceback
    traceback.print_exc()
