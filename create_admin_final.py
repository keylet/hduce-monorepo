# create_admin_final.py
# ✅ VERSIÓN FINAL - USA ESTRUCTURA CORRECTA

import sys
import os
sys.path.append('/app')

print("=" * 60)
print("CREANDO USUARIO ADMIN - ESTRUCTURA UNIFICADA")
print("=" * 60)

try:
    # 1. Primero, verificar que podemos importar todo
    print("\n1. Verificando imports...")
    
    from database import get_db
    print("   ✅ database.get_db importado")
    
    from models import User
    print("   ✅ models.User importado")
    
    from auth_utils import get_password_hash
    print("   ✅ auth_utils.get_password_hash importado")
    
    # 2. Usar get_db() correctamente (como lo hace FastAPI)
    print("\n2. Creando usuario admin...")
    
    # get_db() es un generador, necesitamos usar next() o iterarlo
    db_gen = get_db()
    db = next(db_gen)
    
    try:
        # Verificar si ya existe
        existing = db.query(User).filter(User.email == "admin@hduce.com").first()
        if existing:
            print(f"   ✅ Usuario admin ya existe: {existing.email}")
            print(f"      ID: {existing.id}, Rol: {existing.role}")
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
                is_superuser=True
            )
            db.add(admin)
            db.commit()
            db.refresh(admin)
            print(f"   ✅ Usuario admin CREADO: {admin.email}")
            print(f"      ID: {admin.id}, Rol: {admin.role}")
        
        # Mostrar todos los usuarios
        print("\n3. Listando todos los usuarios...")
        users = db.query(User).all()
        print(f"   📊 Total usuarios en auth_db: {len(users)}")
        
        for user in users:
            status = "✅ ACTIVO" if user.is_active else "❌ INACTIVO"
            superuser = "👑 SUPERUSER" if user.is_superuser else "👤 USER"
            print(f"      {status} {superuser}: {user.email} ({user.role})")
        
        print("\n" + "=" * 60)
        print("✅ PROCESO COMPLETADO EXITOSAMENTE")
        print("=" * 60)
        
    except Exception as e:
        print(f"   ❌ Error en transacción: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        # Cerrar el generador correctamente
        try:
            next(db_gen)  # Esto debería levantar StopIteration
        except StopIteration:
            pass
        
except ImportError as e:
    print(f"\n❌ ERROR DE IMPORTACIÓN: {e}")
    print("\nDebug info:")
    import traceback
    traceback.print_exc()
    
    # Mostrar sys.path
    print(f"\nSys.path:")
    for p in sys.path:
        print(f"  - {p}")
        
    # Verificar archivos
    print(f"\nArchivos en /app:")
    for f in os.listdir('/app'):
        if f.endswith('.py'):
            print(f"  - {f}")

except Exception as e:
    print(f"\n❌ ERROR INESPERADO: {e}")
    import traceback
    traceback.print_exc()
