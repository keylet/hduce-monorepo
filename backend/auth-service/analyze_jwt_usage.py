import sys
sys.path.insert(0, r"C:\Users\raich\Desktop\hduce-monorepo\shared-libraries\hduce_shared")

# Buscar en main.py cómo se usa JWTManager
with open("main.py", "r") as f:
    content = f.read()
    
# Encontrar donde se crea JWTManager
import re
matches = re.findall(r'JWTManager\([^)]*\)', content)
print("Instancias de JWTManager encontradas:")
for match in matches:
    print(f"  {match}")

# También verificar si hay configuración específica
if "secret_key" in content.lower():
    print("\n🔍 Buscando secret_key en código...")
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'secret' in line.lower() or 'key' in line.lower():
            print(f"  Línea {i+1}: {line.strip()}")
