import requests
import json
from datetime import date, time, datetime
import sys

def test_auth_service():
    """Probar el auth-service directamente"""
    print("🔍 Probando auth-service...")
    
    # Leer token del archivo
    try:
        with open("token.txt", "r") as f:
            token = f.read().strip()
        print(f"Token leído: {token[:30]}...")
    except Exception as e:
        print(f"❌ Error leyendo token.txt: {e}")
        return None
    
    # Probar verify-token endpoint
    try:
        response = requests.post(
            "http://localhost:8000/auth/verify-token",
            json={"token": token},  # Enviar como objeto JSON
            timeout=5
        )
        
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Token válido!")
            print(f"Datos del usuario:")
            print(f"  - user_id: {data.get('user_id')}")
            print(f"  - email: {data.get('email')}")
            print(f"  - name: {data.get('name')}")
            print(f"  - sub: {data.get('sub')}")
            print(f"  - Datos completos: {data}")
            return data
        else:
            print(f"❌ Error: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error conectando a auth-service: {e}")
        return None

def test_appointment_service(token_data):
    """Probar el appointment-service"""
    print("\n🔍 Probando appointment-service...")
    
    # Leer token
    try:
        with open("token.txt", "r") as f:
            token = f.read().strip()
    except Exception as e:
        print(f"❌ Error leyendo token.txt: {e}")
        return
    
    # Headers con el token
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # 1. Primero probar endpoint de health
    print("1. Probando health check...")
    try:
        health_response = requests.get("http://localhost:8002/api/health", timeout=5)
        print(f"   Health Status: {health_response.status_code}")
        if health_response.status_code == 200:
            print(f"   ✅ Health OK: {health_response.json()}")
        else:
            print(f"   ❌ Health check falló: {health_response.text}")
    except Exception as e:
        print(f"   ❌ Error en health check: {e}")
    
    # 2. Probar listar citas existentes
    print("\n2. Listando citas existentes...")
    try:
        list_response = requests.get(
            "http://localhost:8002/api/appointments/",
            headers=headers,
            timeout=5
        )
        print(f"   Status Code: {list_response.status_code}")
        if list_response.status_code == 200:
            appointments = list_response.json()
            print(f"   ✅ Hay {len(appointments)} citas existentes")
            if appointments:
                print(f"   Ejemplo de cita: ID={appointments[0].get('id')}, "
                      f"patient_id={appointments[0].get('patient_id')}")
        else:
            print(f"   ❌ Error: {list_response.text}")
    except Exception as e:
        print(f"   ❌ Error listando citas: {e}")
    
    # 3. Crear nueva cita
    print("\n3. Intentando crear nueva cita...")
    
    # Datos de prueba - usar fecha de mañana
    tomorrow = date.today()
    # Si quieres probar con fecha específica, descomenta la siguiente línea:
    # tomorrow = date(2024, 1, 21)
    
    test_appointment = {
        "doctor_id": 1,  # Asumiendo que existe doctor con ID 1
        "appointment_date": str(tomorrow),  # Formato: YYYY-MM-DD
        "appointment_time": "14:30:00",     # Formato: HH:MM:SS
        "reason": "Dolor de cabeza - prueba de diagnóstico",
        "status": "scheduled"
    }
    
    print(f"   Datos a enviar: {json.dumps(test_appointment, indent=4)}")
    print(f"   Usando token para usuario: {token_data.get('email') if token_data else 'Desconocido'}")
    
    try:
        create_response = requests.post(
            "http://localhost:8002/api/appointments/",
            headers=headers,
            json=test_appointment,
            timeout=10
        )
        
        print(f"\n   Status Code: {create_response.status_code}")
        print(f"   Response: {create_response.text}")
        
        if create_response.status_code == 201:
            appointment_data = create_response.json()
            print(f"\n   ✅ ¡Cita creada exitosamente!")
            print(f"   ID de cita: {appointment_data.get('id')}")
            print(f"   Patient ID: {appointment_data.get('patient_id')}")
            print(f"   Patient Email: {appointment_data.get('patient_email')}")
            print(f"   Fecha: {appointment_data.get('appointment_date')}")
            print(f"   Hora: {appointment_data.get('appointment_time')}")
            return True
        elif create_response.status_code == 422:
            print(f"\n   ❌ Error 422 - Validación falló")
            print(f"   Esto usualmente significa:")
            print(f"   - Campos faltantes en el request")
            print(f"   - Tipos de datos incorrectos")
            print(f"   - Formato de fecha/hora inválido")
            print(f"   Revise los logs del appointment-service")
        else:
            print(f"\n   ❌ Error {create_response.status_code}")
            
    except Exception as e:
        print(f"\n   ❌ Error creando cita: {e}")
        import traceback
        print(f"   Traceback: {traceback.format_exc()}")
    
    return False

def main():
    print("=" * 60)
    print("DIAGNÓSTICO HDuce - Error 422 Unprocessable Entity")
    print("=" * 60)
    
    # Paso 1: Probar auth-service
    token_data = test_auth_service()
    
    if token_data:
        # Paso 2: Probar appointment-service
        test_appointment_service(token_data)
    else:
        print("\n⚠️  No se pudo verificar el token. No se puede probar appointment-service.")
        print("   Posibles soluciones:")
        print("   1. Renovar el token con:")
        print('      $loginBody = @{email="testuser@example.com"; password="secret"} | ConvertTo-Json')
        print('      $loginResponse = Invoke-RestMethod -Uri "http://localhost:8000/auth/login" -Method POST -Body $loginBody -ContentType "application/json"')
        print('      $loginResponse.access_token | Out-File -FilePath "token.txt" -Force')
        print("   2. Verificar que auth-service esté corriendo: docker-compose logs auth-service")
    
    print("\n" + "=" * 60)
    print("DIAGNÓSTICO COMPLETADO")
    print("=" * 60)

if __name__ == "__main__":
    main()
