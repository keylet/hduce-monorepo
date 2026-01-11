import sys
import os
sys.path.append("backend/auth-service")

try:
    import routes
    print("✅ routes.py se importa sin errores")
    print(f"Router: {routes.router}")
    
    # Verificar endpoints del router
    for route in routes.router.routes:
        print(f"  - {route.path} [{', '.join(route.methods)}]")
        
except Exception as e:
    print(f"❌ Error importando routes.py: {e}")
    import traceback
    traceback.print_exc()
