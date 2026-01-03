import sys
import traceback
from fastapi import FastAPI
from fastapi.testclient import TestClient

# Intentar importar la app
try:
    from main import app
    print("✅ App importada correctamente")
    
    client = TestClient(app)
    
    # Probar health
    print("\n🧪 Probando health endpoint...")
    resp = client.get("/health")
    print(f"   Health: {resp.status_code} - {resp.json()}")
    
    # Probar crear cita
    print("\n🧪 Probando crear cita...")
    data = {
        "patient_id": "5a626523-b37a-42d3-bb12-a78d8be54083",
        "doctor_id": 1,
        "appointment_date": "2026-01-15T10:00:00",
        "reason": "Debug interno"
    }
    
    resp = client.post("/appointments", json=data)
    print(f"   Status: {resp.status_code}")
    print(f"   Response: {resp.text}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    traceback.print_exc()
