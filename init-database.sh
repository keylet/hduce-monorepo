#!/bin/bash
set -e

echo "=== INICIALIZANDO BASE DE DATOS HDUCE ==="

# Esperar a que PostgreSQL esté listo
until pg_isready -h postgres -U postgres; do
    echo "Esperando a PostgreSQL..."
    sleep 2
done

echo "PostgreSQL está listo"

# Crear base de datos si no existe
psql -h postgres -U postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'appointment_db'" | grep -q 1 || \
psql -h postgres -U postgres -c "CREATE DATABASE appointment_db;"

echo "Base de datos appointment_db verificada/creada"

# Conectar a appointment_db y crear tablas
psql -h postgres -U postgres -d appointment_db <<-EOSQL
    -- Crear tabla specialties si no existe
    CREATE TABLE IF NOT EXISTS specialties (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Crear tabla doctors si no existe
    CREATE TABLE IF NOT EXISTS doctors (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100),
        phone VARCHAR(20),
        specialty_id INTEGER REFERENCES specialties(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Crear tabla appointments si no existe
    CREATE TABLE IF NOT EXISTS appointments (
        id SERIAL PRIMARY KEY,
        patient_id VARCHAR(100) NOT NULL,
        doctor_id INTEGER NOT NULL REFERENCES doctors(id),
        appointment_date TIMESTAMP NOT NULL,
        reason TEXT,
        notes TEXT,
        status VARCHAR(20) DEFAULT 'scheduled',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Insertar datos de prueba
    INSERT INTO specialties (id, name, description) 
    VALUES 
    (1, 'Cardiología', 'Especialidad en enfermedades del corazón'),
    (2, 'Dermatología', 'Especialidad en enfermedades de la piel'),
    (3, 'Pediatría', 'Especialidad en salud infantil')
    ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description;

    INSERT INTO doctors (id, name, email, phone, specialty_id) 
    VALUES 
    (1, 'Dr. Juan Pérez', 'juan.perez@hospital.com', '555-0101', 1),
    (2, 'Dra. María García', 'maria.garcia@hospital.com', '555-0102', 2),
    (3, 'Dr. Carlos López', 'carlos.lopez@hospital.com', '555-0103', 3)
    ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    specialty_id = EXCLUDED.specialty_id;

    SELECT '=== DATOS DE PRUEBA INSERTADOS ===' as mensaje;
    SELECT 'Especialidades:' as tipo, COUNT(*) as cantidad FROM specialties
    UNION ALL
    SELECT 'Doctores:', COUNT(*) FROM doctors
    UNION ALL
    SELECT 'Citas:', COUNT(*) FROM appointments;
EOSQL

echo "=== BASE DE DATOS INICIALIZADA EXITOSAMENTE ==="
