from fastapi import FastAPI
import uvicorn
from datetime import datetime
import threading
import time

from database import engine, get_db
import models
import schemas
from routes import router as notification_router

# ========== CONSUMER SIMPLIFICADO PERO FUNCIONAL ==========
def start_simple_consumer():
    """Consumer simple que SÍ se ejecuta"""
    print("\n" + "=" * 60)
    print("🚀 INICIANDO CONSUMER SIMPLE DE RABBITMQ")
    print("=" * 60)
    
    def consumer_loop():
        import pika
        import json
        
        print("Consumer loop iniciado...")
        
        while True:
            try:
                print("Conectando a RabbitMQ...")
                connection = pika.BlockingConnection(
                    pika.ConnectionParameters(
                        host='rabbitmq',
                        port=5672,
                        credentials=pika.PlainCredentials('admin', 'admin123')
                    )
                )
                channel = connection.channel()
                
                # Exchange
                channel.exchange_declare(
                    exchange='appointment_events',
                    exchange_type='direct',
                    durable=True
                )
                
                # Queue
                channel.queue_declare(queue='notification_queue', durable=True)
                
                # Binding
                channel.queue_bind(
                    exchange='appointment_events',
                    queue='notification_queue',
                    routing_key='created'
                )
                
                print("✅ Consumer configurado. Esperando mensajes...")
                
                # Callback simple
                def simple_callback(ch, method, properties, body):
                    print("\n" + "🎉" * 20)
                    print("🎉 ¡MENSAJE RECIBIDO DE RABBITMQ!")
                    print(f"Body: {body.decode('utf-8')[:100]}...")
                    print("🎉" * 20)
                    
                    # Intentar guardar en DB
                    try:
                        message = json.loads(body.decode('utf-8'))
                        data = message.get('data', {})
                        
                        from database import SessionLocal
                        db = SessionLocal()
                        
                        # Usar 'APPOINTMENT_CREATED' que ya existe en el ENUM
                        notification = models.Notification(
                            user_id=data.get('patient_id', 'test'),
                            notification_type='APPOINTMENT_CREATED',
                            status='pending',
                            subject='Cita creada via RabbitMQ',
                            message=f"Evento: {message.get('event_type', 'unknown')} - Cita: {data.get('appointment_id', 'N/A')}",
                            created_at=datetime.now()
                        )
                        
                        db.add(notification)
                        db.commit()
                        print(f"✅ Guardado en DB: ID {notification.id}")
                        db.close()
                        
                    except Exception as e:
                        print(f"⚠️  Error guardando en DB: {e}")
                        import traceback
                        traceback.print_exc()
                
                channel.basic_consume(
                    queue='notification_queue',
                    on_message_callback=simple_callback,
                    auto_ack=True
                )
                
                # Esto es BLOQUEANTE - importante
                print("🚀 Iniciando consumo BLOQUEANTE...")
                channel.start_consuming()
                
            except Exception as e:
                print(f"❌ Error: {e}")
                import traceback
                traceback.print_exc()
                print("🔄 Reintentando en 5 segundos...")
                time.sleep(5)
    
    # Iniciar en thread separado
    thread = threading.Thread(target=consumer_loop, daemon=True)
    thread.start()
    print("✅ Thread del consumer iniciado")

# ========== INICIAR EL CONSUMER INMEDIATAMENTE ==========
print("\n" + "🚀" * 25)
print("🚀 NOTIFICATION SERVICE - INICIANDO")
print("🚀" * 25)

# Iniciar consumer inmediatamente
start_simple_consumer()

# Crear tablas de BD si no existen
try:
    models.Base.metadata.create_all(bind=engine)
    print("✅ Tablas de BD verificadas")
except Exception as e:
    print(f"⚠️  Error creando tablas: {e}")

# Crear app FastAPI
app = FastAPI(
    title="HDUCE Notification Service",
    description="Servicio de notificaciones con RabbitMQ integrado",
    version="3.0.0"
)

# CORS
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rutas
app.include_router(notification_router, prefix="/api/v1", tags=["notifications"])

# Health check
@app.get("/health")
async def health():
    return {"status": "healthy", "service": "notification", "timestamp": datetime.now().isoformat()}

@app.get("/")
async def root():
    return {
        "message": "Notification Service with RabbitMQ Integration",
        "version": "3.0.0",
        "status": "running",
        "rabbitmq": "active"
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8003, log_level="info")
