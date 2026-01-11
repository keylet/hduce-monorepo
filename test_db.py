from hduce_shared.config import settings

print("=== CONFIGURACIÓN DE BASE DE DATOS ===")
print(f"Host: {settings.database.postgres_host}")
print(f"Port: {settings.database.postgres_port}")
print(f"User: {settings.database.postgres_user}")
print(f"Password: {settings.database.postgres_password}")

# Construir cadena de conexión manualmente
connection_string = f"postgresql://{settings.database.postgres_user}:{settings.database.postgres_password}@{settings.database.postgres_host}:{settings.database.postgres_port}/auth_db"
print(f"\nCadena de conexión: {connection_string}")

# Intentar importar database.py corregido
try:
    from database import get_auth_engine
    print("\n✅ database.py importado exitosamente")
    
    # Intentar crear engine
    try:
        engine = get_auth_engine()
        print("✅ Engine de base de datos creado exitosamente")
        
        # Intentar conectar
        with engine.connect() as conn:
            print("✅ Conexión a base de datos exitosa")
            print(f"Base de datos: auth_db")
            
    except Exception as e:
        print(f"❌ Error creando engine: {type(e).__name__}: {e}")
        
except Exception as e:
    print(f"❌ Error importando database: {type(e).__name__}: {e}")
