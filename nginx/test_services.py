import requests
import json

print("=== VERIFICACIÓN DE SERVICIOS ===")

# 1. Verificar Auth Service
try:
    response = requests.get("http://localhost:8000/health", timeout=2)
    print(f"✅ Auth Service (8000): {response.status_code}")
except:
    print("❌ Auth Service NO responde")

# 2. Verificar User Service
try:
    response = requests.get("http://localhost:8001/health", timeout=2)
    print(f"✅ User Service (8001): {response.status_code}")
except:
    print("❌ User Service NO responde")

# 3. Obtener token
try:
    login_data = {"email": "admin@hduce.com", "password": "admin123"}
    response = requests.post("http://localhost:8000/auth/login", json=login_data)
    token = response.json().get("access_token")
    print(f"✅ Token obtenido: {token[:50]}...")
    
    # 4. Probar con token
    headers = {"Authorization": f"Bearer {token}"}
    test_data = {"user_id": 100, "first_name": "Test", "last_name": "User"}
    response = requests.post("http://localhost:8001/patients/", json=test_data, headers=headers)
    print(f"✅ User Service con token: {response.status_code}")
    if response.status_code != 200:
        print(f"   Error: {response.text}")
except Exception as e:
    print(f"❌ Error en pruebas: {e}")
