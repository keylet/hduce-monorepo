import psycopg2
import bcrypt

# Configuración de conexión
conn = psycopg2.connect(
    host="postgres",
    database="auth_db",
    user="postgres",
    password="postgres"
)
cursor = conn.cursor()

# Generar hash bcrypt válido
password = "TestPass123!"
hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
hash_str = hashed.decode('utf-8')

print(f"Hash generado: {hash_str}")
print(f"Longitud: {len(hash_str)}")

# Limpiar tabla
cursor.execute("DELETE FROM users WHERE email = 'test@hduce.com';")

# Insertar con hash correcto
insert_sql = """
INSERT INTO users (
    email, username, hashed_password, full_name, 
    is_active, is_verified, is_superuser,
    created_at, updated_at
) VALUES (%s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
"""
cursor.execute(insert_sql, (
    'test@hduce.com',
    'testuser',
    hash_str,
    'Test User',
    True,
    True,
    False
))

conn.commit()

# Verificar
cursor.execute("""
    SELECT email, LENGTH(hashed_password), LEFT(hashed_password, 10) 
    FROM users WHERE email = 'test@hduce.com'
""")
result = cursor.fetchone()
print(f"\n✅ Usuario insertado:")
print(f"Email: {result[0]}")
print(f"Longitud hash: {result[1]}")
print(f"Primeros 10 chars: {result[2]}")

cursor.close()
conn.close()
