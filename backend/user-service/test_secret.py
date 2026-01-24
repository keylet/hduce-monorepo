import jwt

token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbkBoZHVjZS5jb20iLCJleHAiOjE3Njg3MDQ2Mzh9.hyFPeMsJ7Mixb3nc9P0EQXITszyI86J6E5znODu2lWk"
secret = "default_secret_key_para_desarrollo"

print(f"Token: {token}")
print(f"Secret: {secret}")

try:
    decoded = jwt.decode(token, secret, algorithms=["HS256"])
    print(f"✅ Token válido!")
    print(f"   Payload: {decoded}")
    print(f"   Usuario: {decoded.get('sub')}")
    print(f"   Expira: {decoded.get('exp')}")
except jwt.ExpiredSignatureError:
    print("❌ Token expirado")
except jwt.InvalidTokenError as e:
    print(f"❌ Token inválido: {e}")
except Exception as e:
    print(f"❌ Error: {e}")
