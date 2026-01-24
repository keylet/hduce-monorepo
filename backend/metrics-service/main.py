from fastapi import FastAPI, HTTPException
from prometheus_client import Counter, Histogram, Gauge, generate_latest, REGISTRY
from prometheus_client.core import CollectorRegistry
import time
import uvicorn
from contextlib import asynccontextmanager
from fastapi.responses import Response

# Crear un registro de métricas personalizado para evitar duplicados
metrics_registry = CollectorRegistry()

# Definir métricas usando el registro personalizado
http_requests_total = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
    registry=metrics_registry
)

http_request_duration_seconds = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"],
    registry=metrics_registry
)

http_requests_in_progress = Gauge(
    "http_requests_in_progress",
    "Current HTTP requests in progress",
    ["method", "endpoint"],
    registry=metrics_registry
)

system_memory_usage = Gauge(
    "system_memory_usage_bytes",
    "System memory usage in bytes",
    registry=metrics_registry
)

system_cpu_usage = Gauge(
    "system_cpu_usage_percent",
    "System CPU usage percentage",
    registry=metrics_registry
)

app_start_time = Gauge(
    "app_start_time_seconds",
    "Application start time in seconds since epoch",
    registry=metrics_registry
)

# Establecer tiempo de inicio
app_start_time.set(time.time())

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown events."""
    # Startup
    print("🚀 Metrics Service starting up...")
    yield
    # Shutdown
    print("🛑 Metrics Service shutting down...")

app = FastAPI(
    title="HDuce Metrics Service",
    description="Metrics collection and monitoring service",
    version="1.0.0",
    lifespan=lifespan
)

@app.middleware("http")
async def metrics_middleware(request, call_next):
    """Middleware para recolectar métricas."""
    method = request.method
    endpoint = request.url.path
    
    # Incrementar métrica de requests en progreso
    http_requests_in_progress.labels(method=method, endpoint=endpoint).inc()
    
    start_time = time.time()
    try:
        response = await call_next(request)
        duration = time.time() - start_time
        
        # Registrar métricas
        http_requests_total.labels(
            method=method, 
            endpoint=endpoint, 
            status=response.status_code
        ).inc()
        
        http_request_duration_seconds.labels(
            method=method, 
            endpoint=endpoint
        ).observe(duration)
        
        return response
    except Exception as e:
        duration = time.time() - start_time
        http_requests_total.labels(
            method=method, 
            endpoint=endpoint, 
            status=500
        ).inc()
        
        http_request_duration_seconds.labels(
            method=method, 
            endpoint=endpoint
        ).observe(duration)
        
        raise e
    finally:
        # Decrementar métrica de requests en progreso
        http_requests_in_progress.labels(method=method, endpoint=endpoint).dec()

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "metrics", "timestamp": time.time()}

@app.get("/metrics")
async def get_metrics():
    """Endpoint para exponer métricas Prometheus."""
    try:
        metrics_data = generate_latest(metrics_registry)
        return Response(
            content=metrics_data,
            media_type="text/plain; version=0.0.4; charset=utf-8"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/system-metrics")
async def get_system_metrics():
    """Endpoint para obtener métricas del sistema."""
    import psutil
    
    # Actualizar métricas del sistema
    system_memory_usage.set(psutil.virtual_memory().used)
    system_cpu_usage.set(psutil.cpu_percent(interval=0.1))
    
    return {
        "memory_usage_bytes": psutil.virtual_memory().used,
        "memory_percent": psutil.virtual_memory().percent,
        "cpu_percent": psutil.cpu_percent(interval=0.1),
        "disk_usage_percent": psutil.disk_usage("/").percent,
        "uptime_seconds": time.time() - app_start_time._value.get()
    }

if __name__ == "__main__":
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8005,
        log_level="info"
    )
