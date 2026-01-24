import httpx
print("Quick debug con httpx...")
data = {
    "patient_id": "test-123",
    "doctor_id": 1,
    "appointment_date": "2026-01-15T10:00:00",
    "reason": "Quick debug"
}
try:
    async with httpx.AsyncClient() as client:
        resp = await client.post("http://localhost:8002/appointments", json=data, timeout=30)
        print(f"Status: {resp.status_code}")
        print(f"Response: {resp.text}")
except Exception as e:
    print(f"Error: {e}")
