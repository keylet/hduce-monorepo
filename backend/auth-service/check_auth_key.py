import sys
sys.path.insert(0, r"C:\Users\raich\Desktop\hduce-monorepo\shared-libraries\hduce_shared")

from config.settings import settings
print(f"Clave JWT en settings: {settings.jwt.jwt_secret_key}")
print(f"Algoritmo: {settings.jwt.jwt_algorithm}")

# Verificar .env actual
import os
from dotenv import load_dotenv
load_dotenv()
print(f"\nClave en .env SECRET_KEY: {os.getenv('SECRET_KEY')}")
print(f"Clave en .env JWT_SECRET_KEY: {os.getenv('JWT_SECRET_KEY')}")
