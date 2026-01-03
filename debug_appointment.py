import json
import requests
from datetime import datetime

print("🔍 DEBUG DETALLADO DE APPOINTMENT SERVICE")
print("=" * 50)

# 1. Probar health endpoint
print("\n1. Probando health endpoint...")
try:
    health = requests.get("http://localhost:8002/health", timeout=5)
    print(f"   Health check: {health.status_code} - {health.json()}")
except Exception as e:
    print(f"   ❌ Error health: {e}")

# 2. Probar crear cita
print("\n2. Probando creación de cita...")
data = {
    "patient_id": "5a626523-b37a-42d3-bb12-a78d8be54083",
    "doctor_id": 1,
    "appointment_date": "2026-01-15T10:00:00",
    "reason": "Debug test"
}

print(f"   Datos: {json.dumps(data, indent=4)}")

try:
    response = requests.post(
        "http://localhost:8002/appointments",
        json=data,
        timeout=10
    )
    
    print(f"   Status Code: {response.status_code}")
    print(f"   Headers: {dict(response.headers)}")
    
    if response.status_code == 200:
        print(f"   ✅ Response: {json.dumps(response.json(), indent=4)}")
    else:
        print(f"   ❌ Error Response: {response.text}")
        
except requests.exceptions.RequestException as e:
    print(f"   ❌ Request Exception: {e}")
    if hasattr(e, 'response') and e.response is not None:
        print(f"   Response text: {e.response.text}")
except Exception as e:
    print(f"   ❌ General Exception: {e}")

# 3. Probar otros endpoints
print("\n3. Probando otros endpoints...")
endpoints = ["/doctors", "/specialties"]
for endpoint in endpoints:
    try:
        resp = requests.get(f"http://localhost:8002{endpoint}", timeout=5)
        print(f"   {endpoint}: {resp.status_code} - {len(resp.json())} items")
    except Exception as e:
        print(f"   {endpoint}: ❌ {e}")

print("\n" + "=" * 50)
print("🔍 DEBUG COMPLETADO")
