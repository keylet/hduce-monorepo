-- ===============================================
-- HDUCE DATABASE INITIALIZATION SCRIPT
-- Version: 1.0.0
-- Created: January 2026
-- ===============================================

-- 1. CREAR EXTENSIÓN UUID (si no existe)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. FUNCIÓN PARA ACTUALIZAR TIMESTAMP
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. CREAR ESQUEMA PARA AUTH SERVICE
\i ./database/schemas/auth_schema.sql

-- 4. CREAR ESQUEMA PARA USER SERVICE
\i ./database/schemas/user_schema.sql

-- 5. CREAR ESQUEMA PARA APPOINTMENT SERVICE
\i ./database/schemas/appointment_schema.sql

-- 6. CREAR ESQUEMA PARA MEDICAL RECORD SERVICE
\i ./database/schemas/medical_schema.sql

-- 7. MENSAJE DE ÉXITO
DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'HDUCE DATABASES INITIALIZED SUCCESSFULLY';
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'Available tables:';
    RAISE NOTICE '- auth_users (Authentication Service)';
    RAISE NOTICE '- users (User Service)';
    RAISE NOTICE '- appointments (Appointment Service)';
    RAISE NOTICE '- medical_records (Medical Service)';
    RAISE NOTICE '=========================================';
END $$;
