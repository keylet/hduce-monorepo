
# ==================== EVENTOS DE APLICACIÓN ====================

@app.on_event("startup")
async def startup_event():
    """Inicializar base de datos y consumer al iniciar"""
    try:
        # Crear tablas si no existen
        engine = get_db_engine(
            host=settings.postgres_host,
            port=settings.postgres_port,
            database=settings.notification_db,  # ¡Importante: notification_db!
            username=settings.postgres_user,
            password=settings.postgres_password
        )
        create_all_tables(engine)
        logger.info("✅ Database tables verified/created for notification-service")
        
        # Iniciar consumer de RabbitMQ en un hilo separado
        start_simple_consumer()
        
    except Exception as e:
        logger.error(f"❌ Startup initialization failed: {e}")

# ==================== ENDPOINTS BÁSICOS ====================

@app.get("/")
async def read_root():
    """Root endpoint"""
    return {
        "service": "notification-service",
        "version": "2.0.0",
        "status": "running",
        "shared_libs": "enabled",
        "database": settings.notification_db,
        "port": 8003,
        "rabbitmq": f"{RABBITMQ_HOST}:{RABBITMQ_PORT}",
        "simulation": {
            "email": EMAIL_SIMULATION,
            "sms": SMS_SIMULATION
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "notification", "shared_libs": True}
