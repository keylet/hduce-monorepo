# backend/notification-service/database.py
# ✅ ACTUALIZADO para usar shared-libraries
# Importar desde shared-libraries
from hduce_shared.database import (
    Base,                    # Base para modelos
    get_db_session,          # Dependency para FastAPI
    get_db_engine,           # Para crear engine específico
    create_all_tables,       # Para crear tablas
    TimestampMixin           # Mixin para created_at/updated_at
)

# Alias para mantener compatibilidad con código existente
get_db = get_db_session  # routes.py usa get_db, así que creamos un alias

# NOTA: Ya no necesitamos crear engine, SessionLocal o declarative_base
# Todo viene de shared-libraries
