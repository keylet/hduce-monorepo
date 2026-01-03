import httpx
import asyncio
import json

async def test():
    print("?? Test INTERNO desde el contenedor")
    print("-" * 40)
    
    # Exactamente el mismo JSON que falla desde PowerShell
    data = {
        "patient_id": "final-integration-test", 
        "doctor_id": 1, 
        "appointment_date": "2026-01-25T09:00:00", 
        "reason": "Test definitivo de integraci?n", 
        "notes": "Verificando Appointment ? Notification"
    }
    
    print(f"JSON que vamos a enviar: {json.dumps(data, indent=2)}")
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "http://localhost:8002/appointments",
                json=data
            )
            
            print(f"\nStatus: {response.status_code}")
            print(f"Response: {response.text}")
            
            if response.status_code == 200:
                print("? ?XITO desde dentro del contenedor")
            else:
                print(f"? Error {response.status_code} desde dentro del contenedor")
                
    except Exception as e:
        print(f"? Exception: {e}")

asyncio.run(test())
