import subprocess
import time
import sys
import os
sys.path.append(os.path.dirname(__file__))

from minimal_app import app
import uvicorn
import threading

def run_server():
    uvicorn.run(app, host="0.0.0.0", port=8002, log_level="info")

if __name__ == "__main__":
    print("Starting minimal FastAPI server...")
    thread = threading.Thread(target=run_server, daemon=True)
    thread.start()
    time.sleep(5)
    
    import requests
    try:
        print("\nTesting /appointments/doctors...")
        response = requests.get("http://localhost:8002/appointments/doctors", timeout=10)
        print(f"✅ Status: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\nTesting /health...")
    try:
        response = requests.get("http://localhost:8002/health", timeout=5)
        print(f"✅ Status: {response.status_code}")
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
