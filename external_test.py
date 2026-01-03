import httpx
import asyncio
import json

async def test_external():
    print("?? Test EXTERNO desde PowerShell con Python")
    print("=" * 60)
    
    data = {
        "patient_id": "test-external-python",
        "doctor_id": 1,
        "appointment_date": "2026-01-15T10:00:00",
        "reason": "Test desde Python externo"
    }
    
    print(f"Datos: {json.dumps(data, indent=2)}")
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "http://localhost:8002/appointments",
                json=data
            )
            
            print(f"\nStatus: {response.status_code}")
            
            if response.status_code == 200:
                print(f"? Success: {json.dumps(response.json(), indent=2)}")
                return True
            else:
                print(f"? Error {response.status_code}:")
                print(f"Response: {response.text}")
                return False
                
    except Exception as e:
        print(f"? Exception: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = asyncio.run(test_external())
    print(f"\n{'?' if success else '?'} Test externo {'pas?' if success else 'fall?'}")
