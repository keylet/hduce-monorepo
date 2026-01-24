import sys
sys.path.insert(0, r"C:\Users\raich\Desktop\hduce-monorepo\shared-libraries\hduce_shared")

try:
    from auth.jwt_manager import JWTManager
    print("✅ JWTManager importado")
    
    # Ver métodos disponibles
    print("Métodos:", [m for m in dir(JWTManager) if not m.startswith('_')])
    
    # Crear instancia para ver config
    jwt_manager = JWTManager()
    print(f"\n🔧 Configuración JWTManager:")
    print(f"   SECRET_KEY: {'*' * len(jwt_manager.SECRET_KEY) if hasattr(jwt_manager, 'SECRET_KEY') else 'No encontrada'}")
    print(f"   ALGORITHM: {getattr(jwt_manager, 'ALGORITHM', 'No encontrado')}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
