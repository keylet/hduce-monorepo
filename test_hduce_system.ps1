import sys
sys.path.insert(0, 'shared-libraries')

try:
    from hduce_shared.database import DatabaseManager
    print("✅ DatabaseManager importado correctamente")
    
    # Verificar qué métodos tiene
    print("\nMétodos de DatabaseManager:")
    for method in dir(DatabaseManager):
        if not method.startswith('_'):
            print(f"  - {method}")
except Exception as e:
    print(f"❌ Error importando: {e}")
