import os
import uvicorn
from dotenv import load_dotenv

# Cargar variables
load_dotenv()

print("="*60)
print("🚀 INICIANDO USER SERVICE - DEBUG COMPLETO")
print("="*60)
print(f"📁 Directorio actual: {os.getcwd()}")
print(f"🔑 SECRET_KEY: {os.getenv('SECRET_KEY')}")
print(f"🔐 SECRET_KEY length: {len(os.getenv('SECRET_KEY', ''))}")
print(f"📝 JWT_ALGORITHM: {os.getenv('JWT_ALGORITHM', 'HS256')}")

# Importar la app para verificar que todo carga
try:
    from main import app
    print("✅ App importada correctamente")
    
    # Verificar rutas disponibles
    print("📋 Rutas disponibles:")
    for route in app.routes:
        print(f"  {route.methods} {route.path}")
except Exception as e:
    print(f"❌ Error importando app: {e}")
    import traceback
    traceback.print_exc()

print("="*60)
print("🌐 Iniciando servidor en puerto 8001...")
print("="*60)

# Iniciar servidor
uvicorn.run(
    'main:app',
    host='0.0.0.0',
    port=8001,
    reload=True,
    log_level='debug'
)
