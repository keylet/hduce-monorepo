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

# Incluir rutas si están disponibles
if HAS_ROUTES:
    app.include_router(routes.router)

# ==================== SOLUCIÓN DEFINITIVA ====================
def crear_engine_notification():
    """Solución definitiva - crea engine directamente"""
    from sqlalchemy import create_engine

    db = settings.database
    # Usar contraseña EXPLÍCITA para evitar problemas
    password = 'postgres'  # Contraseña fija y conocida
    connection_string = f"postgresql://{db.postgres_user}:{password}@{db.postgres_host}:{db.postgres_port}/{db.notification_db}"
    print(f"Conectando a PostgreSQL: {db.postgres_host}:{db.postgres_port}/{db.notification_db}")
    return create_engine(connection_string, pool_pre_ping=True)
# =============================================================

# Variable global para mantener referencia al consumer
rabbitmq_consumer = None

@app.on_event("startup")
async def startup_event():
    """Inicializar base de datos y RabbitMQ consumer al iniciar"""
    global rabbitmq_consumer
    
    # 1. Inicializar base de datos
    try:
        # USAR SOLUCIÓN DEFINITIVA
        engine = crear_engine_notification()
        if HAS_DATABASE_MODULE:
            create_all_tables(engine)
            logger.info("SUCCESS: Database tables verified/created")
        else:
            # Probar conexión
            with engine.connect() as conn:
                conn.execute("SELECT 1")
            logger.info("SUCCESS: Conexión a DB establecida")
    except Exception as e:
        logger.error(f"ERROR: Database initialization failed: {e}")
        import traceback
        logger.error(traceback.format_exc())

    # 2. Inicializar RabbitMQ Consumer - ¡ESTA ES LA PARTE QUE FALTA!
    try:
        logger.info("INFO: Inicializando RabbitMQ consumer...")
        from rabbitmq_consumer import start_rabbitmq_consumer
        rabbitmq_consumer = start_rabbitmq_consumer()
        
        if rabbitmq_consumer:
            logger.info("SUCCESS: RabbitMQ consumer initialized successfully")
            logger.info(f"Consumer type: {type(rabbitmq_consumer)}")
        else:
            logger.warning("WARNING: RabbitMQ consumer could not be initialized")
            
    except ImportError as e:
        logger.warning(f"WARNING: Could not import rabbitmq_consumer: {e}")
        logger.info("INFO: Running without RabbitMQ (standalone mode)")
    except Exception as e:
        logger.error(f"ERROR initializing RabbitMQ consumer: {e}")
        logger.info("INFO: Running without RabbitMQ (standalone mode)")

@app.on_event("shutdown")
async def shutdown_event():
    """Limpiar recursos al apagar"""
    global rabbitmq_consumer
    if rabbitmq_consumer:
        # Si el consumer tiene método close, llamarlo
        if hasattr(rabbitmq_consumer, 'close'):
            rabbitmq_consumer.close()
            logger.info("INFO: RabbitMQ consumer closed")

@app.get("/")
async def root():
    """Root endpoint"""
    global rabbitmq_consumer
    return {
        "service": "notification-service",
        "version": "2.0.0",
        "status": "running",
        "shared_libs": HAS_DATABASE_MODULE,
        "database": settings.database.notification_db if hasattr(settings.database, 'notification_db') else "N/A",
        "port": 8003,
        "rabbitmq_consumer": "active" if rabbitmq_consumer else "inactive"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    global rabbitmq_consumer
    return {
        "status": "healthy",
        "service": "notification",
        "shared_libs": HAS_DATABASE_MODULE,
        "rabbitmq_consumer": "active" if rabbitmq_consumer else "inactive"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)
