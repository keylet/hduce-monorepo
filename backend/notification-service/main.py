from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

# Importar desde shared libraries
from hduce_shared.config import settings
try:
    from hduce_shared.database import create_all_tables
    HAS_DATABASE_MODULE = True
except ImportError:
    HAS_DATABASE_MODULE = False
    logging.warning("hduce_shared.database no disponible")

# Importar rutas locales
try:
    import routes
    HAS_ROUTES = True
except ImportError as e:
    HAS_ROUTES = False
    logging.warning(f"No se pudo importar routes: {e}")

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="HDUCE Notification Service",
    description="Notification microservice using shared-libraries",
    version="2.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir rutas si estÃ¡n disponibles
if HAS_ROUTES:
    app.include_router(routes.router)

# ==================== SOLUCIÃ“N DEFINITIVA ====================
def crear_engine_notification():
    """SoluciÃ³n definitiva - crea engine directamente"""
    from sqlalchemy import create_engine

    db = settings.database
    # Usar contraseÃ±a EXPLÃCITA para evitar problemas
    password = 'postgres'  # ContraseÃ±a fija y conocida
    connection_string = f"postgresql://{db.postgres_user}:{password}@{db.postgres_host}:{db.postgres_port}/{db.postgres_db}"
    print(f"Conectando a PostgreSQL: {db.postgres_host}:{db.postgres_port}/{db.postgres_db}")
    return create_engine(connection_string, pool_pre_ping=True)
# =============================================================

@app.on_event("startup")
async def startup_event():
    """Inicializar base de datos al iniciar"""
    try:
        # USAR SOLUCIÃ“N DEFINITIVA
        engine = crear_engine_notification()
        if HAS_DATABASE_MODULE:
            create_all_tables(engine)
            logger.info("? Database tables verified/created")
        else:
            # Probar conexiÃ³n
            with engine.connect() as conn:
                conn.execute("SELECT 1")
            logger.info("? ConexiÃ³n a DB establecida")
    except Exception as e:
        logger.error(f"? Database initialization failed: {e}")
        import traceback
        logger.error(traceback.format_exc())

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "notification-service",
        "version": "2.0.0",
        "status": "running",
        "shared_libs": HAS_DATABASE_MODULE,
        "database": settings.database.notification_db if hasattr(settings.database, 'notification_db') else "N/A",
        "port": 8003
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "notification", "shared_libs": HAS_DATABASE_MODULE}

# Importar y iniciar RabbitMQ consumer - VERSIÃ“N CORREGIDA
try:
    from independent_consumer import start_independent_consumer
    consumer = start_independent_consumer()
    if consumer:
        print("? Independent RabbitMQ consumer initialized successfully")
except ImportError as e:
    print(f"?? Could not import independent_consumer: {e}")
except Exception as e:
    print(f"?? Error initializing RabbitMQ consumer: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)



