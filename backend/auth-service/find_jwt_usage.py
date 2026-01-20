with open("main.py", "r") as f:
    lines = f.readlines()

print("=== BUSCANDO USO DE JWTManager ===")

# Buscar después del import
found_import = False
for i, line in enumerate(lines):
    if "from hduce_shared.auth import JWTManager" in line:
        found_import = True
        print(f"✅ Import encontrado en línea {i+1}")
        continue
    
    if found_import and ("JWTManager" in line or "jwt_manager" in line):
        print(f"\n📌 Posible uso en línea {i+1}:")
        start = max(0, i-2)
        end = min(len(lines), i+3)
        for j in range(start, end):
            prefix = ">>> " if j == i else "    "
            print(f"{prefix}{j+1:3}: {lines[j].rstrip()}")
        
    # Buscar también create_access_token o similar
    if "create_access_token" in line or "access_token" in line:
        print(f"\n🔑 Generando token en línea {i+1}:")
        start = max(0, i-2)
        end = min(len(lines), i+3)
        for j in range(start, end):
            prefix = ">>> " if j == i else "    "
            print(f"{prefix}{j+1:3}: {lines[j].rstrip()}")
