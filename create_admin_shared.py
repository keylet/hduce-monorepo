# create_admin_shared.py
# ✅ USA SOLO SHARED LIBRARIES

import sys
print("=== CREANDO ADMIN CON SHARED LIBRARIES ===")

try:
    # 1. Importar de shared libraries
    from hduce_shared.config import settings
    from hduce_shared.database import DatabaseManager
    from hduce_shared.auth.jwt_manager import JWTManager
    
    print(f"✅ Shared libraries importadas")
    print(f"📊 Usando: {settings.database.auth_db}")
    
    # 2. Obtener sesión para auth service
    with DatabaseManager.get_session("auth") as db:
        # Importar modelos locales (User debe estar definido en models.py)
        from models import User
        from auth_utils import get_password_hash
        
        # Verificar si ya existe
        existing = db.query(User).filter(User.email == "admin@hduce.com").first()
        if existing:
            print(f"✅ Usuario admin ya existe: {existing.email}")
        else:
            # Crear usuario admin
            hashed = get_password_hash("admin123")
            admin = User(
                email="admin@hduce.com",
                username="admin",
                full_name="Administrator",
                hashed_password=hashed,
                role="admin",
                is_active=True,
                is_verified=True,
                is_superuser=True
            )
            db.add(admin)
            db.commit()
            print(f"✅ Usuario admin creado: admin@hduce.com")
        
        # Mostrar todos los usuarios
        users = db.query(User).all()
        print(f"\n📊 Total usuarios: {len(users)}")
        for user in users:
            print(f"  👤 {user.email} ({user.role})")
            
except ImportError as e:
    print(f"❌ ERROR importando: {e}")
    import traceback
    traceback.print_exc()
except Exception as e:
    print(f"❌ ERROR general: {e}")
    import traceback
    traceback.print_exc()

print("=== FIN DEL SCRIPT ===")
