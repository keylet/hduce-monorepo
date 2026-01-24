with open("main.py", "r") as f:
    lines = f.readlines()

print("=== BUSCANDO JWTManager EN AUTH SERVICE ===")

# Mostrar líneas alrededor de imports y uso de JWTManager
for i, line in enumerate(lines):
    if "JWTManager" in line or "jwt_manager" in line.lower():
        print(f"\nLínea {i+1}:")
        # Mostrar contexto
        start = max(0, i-2)
        end = min(len(lines), i+3)
        for j in range(start, end):
            prefix = ">>> " if j == i else "    "
            print(f"{prefix}{j+1:3}: {lines[j].rstrip()}")
