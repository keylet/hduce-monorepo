from fastapi import FastAPI, Request
import uvicorn
import json

app = FastAPI()

@app.post("/debug-appointments")
async def debug_endpoint(request: Request):
    """Endpoint de debug para ver QU? est? llegando"""
    
    # Obtener body raw
    body_bytes = await request.body()
    body_str = body_bytes.decode('utf-8', errors='replace')
    
    # Headers
    headers = dict(request.headers)
    
    print("\n?? DEBUG - Lo que llega al servidor:")
    print("=" * 60)
    print(f"Content-Type: {headers.get('content-type', 'NO HEADER')}")
    print(f"Content-Length: {headers.get('content-length', 'NO HEADER')}")
    print(f"Body (raw): {repr(body_str)}")
    print(f"Body length: {len(body_str)} bytes")
    print(f"First 100 chars: {body_str[:100]}")
    
    # Intentar parsear JSON
    try:
        parsed = json.loads(body_str)
        print(f"? JSON v?lido: {json.dumps(parsed, indent=2)}")
        
        # Forward al endpoint real
        import httpx
        async with httpx.AsyncClient() as client:
            real_response = await client.post(
                "http://localhost:8002/appointments",
                json=parsed,
                headers={"Content-Type": "application/json"}
            )
            
            return {
                "debug": {
                    "received": parsed,
                    "headers_received": headers,
                    "body_raw_preview": body_str[:200]
                },
                "real_response": {
                    "status_code": real_response.status_code,
                    "body": real_response.json() if real_response.status_code == 200 else real_response.text
                }
            }
            
    except json.JSONDecodeError as e:
        print(f"? JSON inv?lido: {e}")
        print(f"Body completo: {body_str}")
        return {"error": "Invalid JSON", "details": str(e), "body_received": body_str}
        
    except Exception as e:
        print(f"? Error general: {e}")
        return {"error": str(e)}

if __name__ == "__main__":
    print("?? Debug server starting on port 8004...")
    uvicorn.run(app, host="0.0.0.0", port=8004)
