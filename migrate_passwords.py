import bcrypt
import psycopg2
from psycopg2.extras import RealDictCursor
import logging
import sys

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def hash_password(password: str) -> str:
    """Hash password using bcrypt"""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def migrate_auth_db():
    """Migrar contraseñas en auth_db"""
    try:
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="auth_db",
            user="postgres",
            password="postgres123"
        )
        
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Obtener usuarios
        cursor.execute("SELECT id, username, hashed_password FROM users")
        users = cursor.fetchall()
        
        logger.info(f"Usuarios encontrados: {len(users)}")
        
        updated = 0
        for user in users:
            current_pass = user['hashed_password']
            
            # Si ya es bcrypt, saltar
            if current_pass.startswith('$2b$'):
                logger.debug(f"✓ {user['username']} ya tiene bcrypt")
                continue
            
            # Hashear
            hashed = hash_password(current_pass)
            
            # Actualizar
            cursor.execute(
                "UPDATE users SET hashed_password = %s WHERE id = %s",
                (hashed, user['id'])
            )
            
            logger.info(f"✓ {user['username']}: {current_pass} -> {hashed[:30]}...")
            updated += 1
        
        conn.commit()
        logger.info(f"✅ Migración completada: {updated}/{len(users)} usuarios actualizados")
        
        # Verificar
        cursor.execute("SELECT username, LEFT(hashed_password, 30) as hash_prefix FROM users")
        for row in cursor.fetchall():
            if row['hash_prefix'].startswith('$2b$'):
                logger.info(f"  ✅ {row['username']}: BCrypt OK")
            else:
                logger.error(f"  ❌ {row['username']}: NO ES BCRYPT!")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        return False

def fix_initialize_script():
    """Corregir el script de inicialización"""
    try:
        with open('initialize-test-data.ps1', 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Buscar dónde se crean usuarios
        # Necesito ver más del script para corregirlo
        print("\n=== ANÁLISIS DE initialize-test-data.ps1 ===")
        print("El script necesita crear usuarios usando /register endpoint")
        print("NO debe insertar contraseñas directamente en la BD")
        
        return True
    except Exception as e:
        logger.error(f"Error analizando script: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("MIGRACIÓN DEFINITIVA DE CONTRASEÑAS HDUCE")
    print("=" * 60)
    
    print("\n1. Verificando conexión a BD...")
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            database="auth_db",
            user="postgres",
            password="postgres123"
        )
        conn.close()
        print("   ✅ Conexión exitosa")
    except Exception as e:
        print(f"   ❌ Error de conexión: {e}")
        sys.exit(1)
    
    print("\n2. Migrando contraseñas a BCrypt...")
    if migrate_auth_db():
        print("   ✅ Migración BCrypt completada")
    else:
        print("   ❌ Migración falló")
        sys.exit(1)
    
    print("\n3. Recomendaciones para scripts de inicialización:")
    print("   a) Modificar initialize-test-data.ps1 para usar:")
    print("      POST http://localhost:8000/register")
    print("   b) Eliminar inserciones directas a BD")
    print("   c) Usar bcrypt para nuevas contraseñas")
    
    print("\n" + "=" * 60)
    print("MIGRACIÓN COMPLETADA - PASOS SIGUIENTES:")
    print("1. Reiniciar auth-service: docker-compose restart auth-service")
    print("2. Probar login: curl -X POST http://localhost:8000/login")
    print("3. Corregir otros servicios para usar tokens JWT")
    print("=" * 60)