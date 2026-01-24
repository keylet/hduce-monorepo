-- ===============================================
-- INIT.SQL CORREGIDO - CREA USUARIO Y DATABASE
-- ===============================================

-- 1. PRIMERO CREAR EL USUARIO (si no existe)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hduce_user') THEN
        CREATE USER hduce_user WITH PASSWORD 'hduce_pass';
        RAISE NOTICE 'Usuario hduce_user creado';
    ELSE
        RAISE NOTICE 'Usuario hduce_user ya existe';
    END IF;
END $$;

-- 2. OTORGAR PRIVILEGIOS
GRANT ALL PRIVILEGES ON DATABASE hduce_db TO hduce_user;
ALTER USER hduce_user WITH SUPERUSER;  -- Para desarrollo

-- 3. EXTENSIÓN UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 4. TABLA PARA USER SERVICE (compatible con tu código)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    role VARCHAR(50) DEFAULT 'patient',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. TABLA PARA AUTH SERVICE
CREATE TABLE IF NOT EXISTS auth_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. TABLA PARA APPOINTMENT SERVICE
CREATE TABLE IF NOT EXISTS appointments (
    id SERIAL PRIMARY KEY,
    patient_id UUID REFERENCES users(id),
    doctor_id UUID REFERENCES users(id),
    appointment_date TIMESTAMP NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    status VARCHAR(50) DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. INSERTAR DATOS DE PRUEBA
-- Usuario admin para auth
INSERT INTO auth_users (username, email, password_hash) 
VALUES ('admin', 'admin@hduce.com', 'admin123')  -- ¡En producción usar bcrypt!
ON CONFLICT (username) DO NOTHING;

-- Usuario admin para user service
INSERT INTO users (username, email, full_name, role) 
VALUES ('admin', 'admin@hduce.com', 'Administrator', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Usuario doctor
INSERT INTO users (username, email, full_name, role) 
VALUES ('doctor1', 'doctor1@hduce.com', 'Dr. Juan Pérez', 'doctor')
ON CONFLICT (username) DO NOTHING;

-- Usuario paciente
INSERT INTO users (username, email, full_name, role) 
VALUES ('patient1', 'patient1@hduce.com', 'María González', 'patient')
ON CONFLICT (username) DO NOTHING;

-- 8. CITA DE PRUEBA
INSERT INTO appointments (patient_id, doctor_id, appointment_date, status)
SELECT 
    (SELECT id FROM users WHERE username = 'patient1'),
    (SELECT id FROM users WHERE username = 'doctor1'),
    CURRENT_TIMESTAMP + INTERVAL '2 days',
    'scheduled'
WHERE NOT EXISTS (SELECT 1 FROM appointments LIMIT 1);

-- 9. MENSAJE DE ÉXITO
DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'BASE DE DATOS INICIALIZADA CORRECTAMENTE';
    RAISE NOTICE 'Usuario: hduce_user';
    RAISE NOTICE 'Contraseña: hduce_pass';
    RAISE NOTICE 'Database: hduce_db';
    RAISE NOTICE '=========================================';
END $$;
