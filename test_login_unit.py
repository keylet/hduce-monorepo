import sys
import os
sys.path.append("shared-libraries")
sys.path.append("backend/auth-service")

# Mock de dependencias
from unittest.mock import Mock, MagicMock
import pytest

# Importar el router
from routes import router

# Crear app de prueba
from fastapi import FastAPI
from fastapi.testclient import TestClient

app = FastAPI()
app.include_router(router)

client = TestClient(app)

def test_login_endpoint():
    """Test del endpoint login"""
    print("=== TESTING LOGIN ENDPOINT ===")
    
    # Mock de la base de datos
    from database import User
    
    # Crear mock user
    mock_user = Mock(spec=User)
    mock_user.id = 1
    mock_user.username = "test_user"
    mock_user.email = "test@hduce.com"
    mock_user.hashed_password = "$2b$12$V2hRpEgXaZdF0joUNmSl1.dPjXegQqXM7xn/1GMrYKAn5SE67hbEK"  # hash de "test123"
    mock_user.role = "patient"
    
    # Mock de auth_utils
    import auth_utils
    original_verify = auth_utils.verify_password
    auth_utils.verify_password = Mock(return_value=True)
    
    try:
        # Probar endpoint
        response = client.post("/auth/login", data={"username": "test_user", "password": "test123"})
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error en test: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
    finally:
        auth_utils.verify_password = original_verify

if __name__ == "__main__":
    test_login_endpoint()
