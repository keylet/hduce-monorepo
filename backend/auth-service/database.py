# backend/auth-service/database.py
# ✅ VERSIÓN FINAL CORREGIDA - COMPATIBLE CON FASTAPI

print("🔧 Configurando auth-service database con shared libraries...")

# IMPORTAR DESDE SHARED LIBRARIES
try:
    from hduce_shared.database import (
        Base,
        DatabaseManager,
        create_all_tables,
        get_db_session
    )
    from hduce_shared.config import settings
    from contextlib import contextmanager

    print(f"✅ Shared libraries importadas correctamente")
    print(f"📊 Servicio: auth, Base de datos: {settings.database.auth_db}")

    # Configurar constantes para este servicio
    SERVICE_NAME = "auth"

    # ==============================================
    # FUNCIÓN GET_DB CORREGIDA PARA FASTAPI
    # ==============================================
    def get_db():
        """
        FastAPI dependency para auth-service
        CORREGIDA: Retorna una sesión de SQLAlchemy, no un contexto
        """
        # Obtener el contexto manager de shared libraries
        context_manager = DatabaseManager.get_session(SERVICE_NAME)
        
        # Entrar al contexto para obtener la sesión
        db = context_manager.__enter__()
        
        try:
            yield db
        finally:
            # Salir del contexto
            context_manager.__exit__(None, None, None)

    # Versión alternativa usando get_db_session directamente
    @contextmanager
    def get_db_context():
        """Context manager alternativo"""
        with DatabaseManager.get_session(SERVICE_NAME) as db:
            yield db

    # Alias para compatibilidad
    get_db_session_auth = lambda: DatabaseManager.get_session(SERVICE_NAME)

    # Crear tablas para este servicio
    def create_auth_tables():
        """Crear tablas del auth-service"""
        try:
            create_all_tables(SERVICE_NAME)
            print(f"✅ Tablas creadas para servicio: {SERVICE_NAME}")
        except Exception as e:
            print(f"❌ Error creando tablas: {e}")
            raise

    print(f"🎯 Auth-service configurado para usar shared libraries (FastAPI compatible)")

except ImportError as e:
    print(f"❌ ERROR CRÍTICO: No se pueden importar shared libraries: {e}")
    print("💥 El sistema NO funcionará sin shared libraries")
    raise

print("✅ Configuración de database completada")

# Exportar
__all__ = ["get_db", "get_db_session_auth", "create_auth_tables", "Base"]
