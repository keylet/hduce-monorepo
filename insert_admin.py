import sys
sys.path.append('/app')
from database import SessionLocal
import bcrypt

print("Insertando usuario admin con hash bcrypt correcto...")

# Hash conocido que sabemos que funciona
HASH_CORRECTO = "$2b$12$OW63hRps/Dg2JejZSPR0XuhIuXSwJfEuTjE8Gs4SZ9/oi.XJcJNFK"

print(f"Hash a insertar: {HASH_CORRECTO[:30]}...")
print(f"Longitud: {len(HASH_CORRECTO)}")

# Conectar a PostgreSQL
db = SessionLocal()
try:
    # Eliminar si existe
    from sqlalchemy import text
    db.execute(text("DELETE FROM users WHERE email = 'admin@hduce.com'"))
    db.commit()
    print("✅ Usuario anterior eliminado")
    
    # Insertar nuevo con hash correcto
    insert_sql = text("""
        INSERT INTO users (email, username, full_name, hashed_password, role, is_active, is_superuser)
        VALUES (:email, :username, :full_name, :hashed_password, :role, :is_active, :is_superuser)
    """)
    
    db.execute(insert_sql, {
        'email': 'admin@hduce.com',
        'username': 'admin',
        'full_name': 'Administrador',
        'hashed_password': HASH_CORRECTO,
        'role': 'admin',
        'is_active': True,
        'is_superuser': True
    })
    db.commit()
    print("✅ Usuario admin insertado con hash bcrypt correcto")
    
    # Verificar
    result = db.execute(text("SELECT email, LENGTH(hashed_password) as len, SUBSTRING(hashed_password FROM 1 FOR 7) as prefix FROM users WHERE email = 'admin@hduce.com'"))
    user = result.fetchone()
    print(f"✅ Verificado: {user.email}, longitud: {user.len}, prefijo: {user.prefix}")
    
    # Probar verificación de contraseña
    print("\n🔍 Probando verificación de contraseña...")
    result = db.execute(text("SELECT hashed_password FROM users WHERE email = 'admin@hduce.com'"))
    stored_hash = result.scalar()
    
    password = "admin123"
    is_valid = bcrypt.checkpw(password.encode('utf-8'), stored_hash.encode('utf-8'))
    print(f"✅ Contraseña 'admin123' válida: {is_valid}")
    
finally:
    db.close()
