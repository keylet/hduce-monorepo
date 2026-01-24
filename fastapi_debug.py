from fastapi.testclient import TestClient
from main import app
import json

client = TestClient(app)

print("?? DEBUG DE VALIDACI?N DE FASTAPI")
print("=" * 60)

# Test 1: Health check
print("\n1. Health check:")
resp = client.get("/health")
print(f"   Status: {resp.status_code}")
print(f"   Body: {resp.json()}")

# Test 2: Validar datos con Pydantic
print("\n2. Validando datos con Pydantic:")
from datetime import datetime
import schemas

test_data = {
    "patient_id": "test-patient-123",
    "doctor_id": 1,
    "appointment_date": "2026-01-15T10:00:00",
    "reason": "Test validation"
}

print(f"   Datos: {json.dumps(test_data, indent=4)}")

try:
    # Intentar crear el objeto Pydantic
    appointment_create = schemas.AppointmentCreate(**test_data)
    print(f"   ? Pydantic validation PASSED")
    print(f"   Objeto creado: {appointment_create}")
    
    # Ver tipos
    print(f"   Tipos:")
    print(f"     patient_id: {type(appointment_create.patient_id)}")
    print(f"     doctor_id: {type(appointment_create.doctor_id)}")
    print(f"     appointment_date: {type(appointment_create.appointment_date)}")
    
except Exception as e:
    print(f"   ? Pydantic validation FAILED: {e}")
    import traceback
    traceback.print_exc()

# Test 3: Probar endpoint
print("\n3. Probando endpoint /appointments:")
try:
    resp = client.post("/appointments", json=test_data)
    print(f"   Status: {resp.status_code}")
    
    if resp.status_code == 200:
        print(f"   ? Success: {json.dumps(resp.json(), indent=4)}")
    else:
        print(f"   ? Error {resp.status_code}:")
        print(f"   Response: {resp.text}")
        
        # Verificar si hay error de Pydantic
        if "detail" in resp.json():
            print(f"   Detail: {resp.json()['detail']}")
            
except Exception as e:
    print(f"   ? Exception: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 60)
