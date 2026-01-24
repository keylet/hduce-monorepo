import sys
sys.path.insert(0, r"C:\Users\raich\Desktop\hduce-monorepo\shared-libraries\hduce_shared")

# Buscar en routes/auth.py o similar
import os
for file in os.listdir("."):
    if file.endswith(".py") and ("route" in file.lower() or "auth" in file.lower()):
        print(f"\n=== Buscando en {file} ===")
        with open(file, "r") as f:
            content = f.read()
            if "create_access_token" in content or "JWTManager" in content:
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if "create_access_token" in line or "JWTManager" in line:
                        print(f"Línea {i+1}: {line.strip()}")
