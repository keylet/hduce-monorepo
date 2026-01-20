#!/bin/bash
set -e

echo '=== CREANDO BASES DE DATOS HDUCE ==='

# Crear bases de datos
psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
    CREATE DATABASE auth_db;
    CREATE DATABASE user_db;
    CREATE DATABASE appointment_db;
    CREATE DATABASE notification_db;
EOSQL

echo '=== BASES DE DATOS CREADAS ==='

# Ahora inicializar datos en cada base de datos
echo '=== INICIALIZANDO DATOS EN auth_db ==='
psql -U postgres -d auth_db <<-EOSQL
    -- Crear tabla users si no existe (debería ser creada por auth-service)
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR NOT NULL UNIQUE,
        username VARCHAR NOT NULL UNIQUE,
        full_name VARCHAR NOT NULL,
        hashed_password VARCHAR NOT NULL,
        role VARCHAR NOT NULL,
        is_active BOOLEAN,
        is_superuser BOOLEAN,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
    );
    
    -- Insertar usuario de prueba
    INSERT INTO users (email, username, full_name, hashed_password, role, is_active, is_superuser, created_at, updated_at) 
    VALUES (
        'testuser@example.com', 
        'testuser', 
        'Usuario de Prueba',
        '\\\',
        'patient',
        true,
        false,
        NOW(),
        NOW()
    ) ON CONFLICT (username) DO NOTHING;
EOSQL

echo '=== INICIALIZANDO DATOS EN appointment_db ==='
psql -U postgres -d appointment_db <<-EOSQL
    -- Insertar especialidades
    INSERT INTO specialties (name, description, created_at) VALUES
    ('Cardiología', 'Especialidad en enfermedades del corazón', NOW()),
    ('Pediatría', 'Especialidad en cuidado infantil', NOW()),
    ('Dermatología', 'Especialidad en enfermedades de la piel', NOW()),
    ('Neurología', 'Especialidad en enfermedades del sistema nervioso', NOW()),
    ('Ortopedia', 'Especialidad en sistema musculoesquelético', NOW())
    ON CONFLICT (name) DO NOTHING;
    
    -- Insertar doctores (usando IDs de especialidades recién insertadas)
    INSERT INTO doctors (user_id, license_number, name, email, phone, specialty_id, consultation_duration, created_at) 
    SELECT 
        'doc_001',
        'MED-12345', 
        'Dr. Juan Pérez', 
        'juan.perez@hospital.com', 
        '+1-555-0101', 
        id, 
        30, 
        NOW()
    FROM specialties WHERE name = 'Cardiología'
    ON CONFLICT (license_number) DO NOTHING;
    
    INSERT INTO doctors (user_id, license_number, name, email, phone, specialty_id, consultation_duration, created_at) 
    SELECT 
        'doc_002',
        'MED-67890', 
        'Dra. María López', 
        'maria.lopez@hospital.com', 
        '+1-555-0102', 
        id, 
        45, 
        NOW()
    FROM specialties WHERE name = 'Pediatría'
    ON CONFLICT (license_number) DO NOTHING;
    
    INSERT INTO doctors (user_id, license_number, name, email, phone, specialty_id, consultation_duration, created_at) 
    SELECT 
        'doc_003',
        'MED-54321', 
        'Dr. Carlos Gómez', 
        'carlos.gomez@hospital.com', 
        '+1-555-0103', 
        id, 
        30, 
        NOW()
    FROM specialties WHERE name = 'Dermatología'
    ON CONFLICT (license_number) DO NOTHING;
EOSQL

echo '=== DATOS INICIALES CREADOS ==='
