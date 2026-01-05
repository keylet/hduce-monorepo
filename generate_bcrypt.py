import bcrypt

# Contraseñas que queremos usar
passwords = {
    "admin": "admin123",
    "doctor1": "doctor123", 
    "paciente1": "paciente123",
    "testuser": "test123",
    "emergency": "simplepass"
}

print("=== HASHES BCRYPT ===")
for user, pwd in passwords.items():
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(pwd.encode('utf-8'), salt)
    print(f"UPDATE users SET hashed_password = '{hashed.decode('utf-8')}' WHERE username = '{user}';")
