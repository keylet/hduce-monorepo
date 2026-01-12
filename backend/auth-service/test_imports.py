from fastapi import FastAPI, APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import sys
import os

# Test de imports
print("=== TEST DE IMPORTS EN CONTENEDOR ===")

modules = ["database", "auth_utils", "hduce_shared.auth", "hduce_shared.config"]

for module in modules:
    try:
        if module == "database":
            from database import get_db, User
            print(f"✅ {module}: get_db={get_db}, User={User}")
        elif module == "auth_utils":
            import auth_utils
            print(f"✅ {module}: verify_password={auth_utils.verify_password}")
        else:
            __import__(module.replace(".", "_"))
            print(f"✅ {module}")
    except Exception as e:
        print(f"❌ {module}: {type(e).__name__}: {e}")

print("=== TEST COMPLETADO ===")
