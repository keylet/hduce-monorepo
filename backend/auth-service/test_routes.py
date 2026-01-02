import sys
from main import app

print("=== TODAS LAS RUTAS REGISTRADAS EN FASTAPI ===")
print(f"Total de rutas: {len(app.routes)}")
print("-" * 60)

for route in app.routes:
    if hasattr(route, "methods"):
        methods = ", ".join(sorted(route.methods))
        print(f"{methods:15} {route.path}")
    else:
        print(f"{'--':15} {route.path}")

print("-" * 60)
print("\nRutas que contienen '/api/auth':")
for route in app.routes:
    if hasattr(route, "path") and "/api/auth" in route.path:
        methods = ", ".join(sorted(route.methods)) if hasattr(route, "methods") else "--"
        print(f"{methods:15} {route.path}")
