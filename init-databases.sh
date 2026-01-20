#!/bin/bash
set -e

echo "=== Inicializando bases de datos en PostgreSQL ==="

# Verificar y crear cada base de datos individualmente
create_database() {
    local dbname="$1"
    echo "Verificando/Creando base de datos: $dbname"
    
    # Verificar si la base de datos ya existe
    if psql -U "$POSTGRES_USER" -lqt | cut -d \| -f 1 | grep -qw "$dbname"; then
        echo "Base de datos $dbname ya existe"
    else
        echo "Creando base de datos: $dbname"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE $dbname;"
        echo "Base de datos $dbname creada exitosamente"
    fi
}

# Crear las 4 bases de datos principales
create_database "auth_db"
create_database "user_db"
create_database "appointment_db"
create_database "notification_db"

echo "=== Bases de datos creadas exitosamente ==="
echo "=== Configurando tablas y datos iniciales ==="

# Configurar user_db con tabla users - VERSIÓN CORREGIDA
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "user_db" <<-EOSQL
    -- Crear tabla users para user-service - ESQUEMA CORREGIDO
    -- Este esquema debe coincidir con models.py del user-service
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),                    -- ← CAMBIO: name en lugar de full_name
        email VARCHAR(255) UNIQUE NOT NULL,
        age INTEGER,                         -- ← NUEVO: campo age que necesita routes.py
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Índices para user_db
    CREATE INDEX IF NOT EXISTS idx_user_db_email ON users(email);
    
    -- NOTA: Mantenemos compatibilidad con columnas antiguas pero marcadas como deprecated
    -- Estas columnas se mantienen para no romper posibles dependencias:
    -- user_id, username, full_name, role, is_active
    
    -- Agregar columnas compatibilidad si no existen (para migración gradual)
    ALTER TABLE users ADD COLUMN IF NOT EXISTS user_id INTEGER;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(100);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name VARCHAR(255);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'patient';
    ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
    
    -- Crear índices para columnas de compatibilidad
    CREATE INDEX IF NOT EXISTS idx_user_db_user_id ON users(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_db_username ON users(username);
EOSQL

# Configurar user_db con tabla users
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "user_db" <<-EOSQL
    -- Crear tabla users para user-service
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        user_id INTEGER UNIQUE NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        username VARCHAR(100) UNIQUE NOT NULL,
        full_name VARCHAR(255),
        role VARCHAR(50) DEFAULT 'patient',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_user_db_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_user_db_user_id ON users(user_id);
EOSQL

# Configurar appointment_db
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "appointment_db" <<-EOSQL
    -- Crear tabla specialties
    CREATE TABLE IF NOT EXISTS specialties (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) UNIQUE NOT NULL,
        description TEXT
    );

    -- Crear tabla doctors
    CREATE TABLE IF NOT EXISTS doctors (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        specialty_id INTEGER REFERENCES specialties(id),
        email VARCHAR(255) UNIQUE,
        phone VARCHAR(50),
        is_active BOOLEAN DEFAULT true
    );

    -- Crear tabla appointments
    CREATE TABLE IF NOT EXISTS appointments (
        id SERIAL PRIMARY KEY,
        patient_id INTEGER NOT NULL,
        patient_email VARCHAR(255) NOT NULL,
        patient_name VARCHAR(255) NOT NULL,
        doctor_id INTEGER REFERENCES doctors(id),
        appointment_date DATE NOT NULL,
        appointment_time TIME NOT NULL,
        status VARCHAR(50) DEFAULT 'scheduled',
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Índices para appointment_db
    CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
    CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
    CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
    CREATE INDEX IF NOT EXISTS idx_doctors_specialty ON doctors(specialty_id);
EOSQL

# Configurar notification_db
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "notification_db" <<-EOSQL
    -- Crear tabla notifications
    CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        user_email VARCHAR(255) NOT NULL,
        notification_type VARCHAR(100) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        read_at TIMESTAMP
    );

    -- Índices para notification_db
    CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
    CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
    CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
EOSQL

# Insertar datos iniciales para appointment_db (especialidades y doctores)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "appointment_db" <<-EOSQL
    -- Insertar especialidades si no existen
    INSERT INTO specialties (name, description) VALUES
    ('Cardiología', 'Especialidad en enfermedades del corazón'),
    ('Dermatología', 'Especialidad en enfermedades de la piel'),
    ('Pediatría', 'Especialidad en cuidado de niños'),
    ('Neurología', 'Especialidad en enfermedades del sistema nervioso'),
    ('Ortopedia', 'Especialidad en huesos y articulaciones')
    ON CONFLICT (name) DO NOTHING;

    -- Insertar doctores si no existen
    INSERT INTO doctors (name, specialty_id, email, phone) VALUES
    ('Dr. Juan Pérez', 1, 'juan.perez@hospital.com', '+1234567890'),
    ('Dra. María López', 2, 'maria.lopez@hospital.com', '+1234567891'),
    ('Dr. Carlos García', 3, 'carlos.garcia@hospital.com', '+1234567892'),
    ('Dra. Ana Martínez', 4, 'ana.martinez@hospital.com', '+1234567893'),
    ('Dr. Luis Rodríguez', 5, 'luis.rodriguez@hospital.com', '+1234567894')
    ON CONFLICT (email) DO NOTHING;
EOSQL

echo "=== Configuración completada exitosamente ==="
echo "=== Bases de datos listas para usar ==="