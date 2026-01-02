"""
User Service - Main Application
Alternative version with correct imports
"""
from fastapi import FastAPI
from src.protected_routes import router as protected_router

app = FastAPI(
    title="HDUCE User Service",
    description="User Management Service",
    version="1.0.0"
)

# Include protected routes
app.include_router(protected_router)

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "user-service",
        "status": "running",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health():
    """Health check"""
    return {"status": "healthy", "service": "user-service"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
