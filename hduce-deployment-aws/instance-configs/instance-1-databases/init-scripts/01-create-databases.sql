-- 01-create-databases.sql
-- Crear las 4 bases de datos para HDuce

CREATE DATABASE auth_db;
CREATE DATABASE user_db;
CREATE DATABASE appointment_db;
CREATE DATABASE notification_db;

-- Conceder todos los privilegios al usuario postgres
GRANT ALL PRIVILEGES ON DATABASE auth_db TO postgres;
GRANT ALL PRIVILEGES ON DATABASE user_db TO postgres;
GRANT ALL PRIVILEGES ON DATABASE appointment_db TO postgres;
GRANT ALL PRIVILEGES ON DATABASE notification_db TO postgres;

-- Comentarios
COMMENT ON DATABASE auth_db IS 'Database for authentication service';
COMMENT ON DATABASE user_db IS 'Database for user profiles service';
COMMENT ON DATABASE appointment_db IS 'Database for medical appointments (37 appointments)';
COMMENT ON DATABASE notification_db IS 'Database for notifications (11 notifications)';
