# backend/auth-service/database.py - VERSIÓN PARA FASTAPI
print("🔧 Configurando auth-service database con shared libraries...")

# IMPORTAR DESDE SHARED LIBRARIES
try:
    from hduce_shared.database import (
        Base,
        get_db_session,
        get_db_engine,
        create_all_tables,
        DatabaseManager,
        TimestampMixin
    )
    from hduce_shared.config import settings

    print(f"✅ Shared libraries importadas correctamente")
    print(f"📊 Servicio: auth, Base de datos: {settings.database.auth_db}")

    # Configurar constantes para este servicio
    SERVICE_NAME = "auth"

    # FUNCIÓN CORREGIDA PARA FASTAPI - generador que yield session
    def get_db():
        """FastAPI dependency - generador que retorna sesión"""
        db = DatabaseManager.get_session(SERVICE_NAME)
        try:
            yield db
        finally:
            db.close()

    # Alias para compatibilidad
    get_db_session_auth = DatabaseManager.get_session(SERVICE_NAME)

    # Crear tablas para este servicio
    def create_auth_tables():
        """Crear tablas del auth-service"""
        create_all_tables(SERVICE_NAME)
        print(f"✅ Tablas creadas para servicio: {SERVICE_NAME}")

    print(f"🎯 Auth-service configurado para FastAPI")

except ImportError as e:
    print(f"❌ ERROR CRÍTICO: No se pueden importar shared libraries: {e}")
    print("💥 El sistema NO funcionará sin shared libraries")
    raise

print("✅ Configuración de database completada")

# Exportar
__all__ = ["get_db", "get_db_session_auth", "create_auth_tables", "Base"]
