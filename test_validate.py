import httpx
import json

# Leer token si existe
try:
    with open("test_token.txt", "r") as f:
        token = f.read().strip()
    print(f"Token leído: {token[:50]}...")
except:
    print("❌ No hay token. Primero ejecuta test_login.py")
    exit()

# Validar token
try:
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    response = httpx.get(
        "http://localhost:8000/validate-token",
        headers=headers,
        timeout=10.0
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code == 200:
        print("\n✅ Token válido!")
        user_data = response.json()
        print(f"User ID: {user_data['user_id']}")
        print(f"Email: {user_data['email']}")
    else:
        print("\n❌ Token inválido")
        
except Exception as e:
    print(f"Error: {e}")
