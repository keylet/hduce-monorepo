-- ===============================================
-- USER SERVICE SCHEMA
-- ===============================================

-- TABLA PARA USER SERVICE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    age INTEGER,
    phone VARCHAR(20),
    address TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    role VARCHAR(50) DEFAULT 'patient',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABLA PARA HISTORIAL DE USUARIOS (AUDITORÍA)
CREATE TABLE IF NOT EXISTS user_history (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    details JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ÍNDICES
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_user_history_user_id ON user_history(user_id);

-- INSERTAR DATOS DE PRUEBA
INSERT INTO users (username, email, full_name, role) 
VALUES 
    ('admin', 'admin@hduce.com', 'Administrator', 'admin'),
    ('doctor1', 'doctor1@hduce.com', 'Dr. Juan Pérez', 'doctor'),
    ('doctor2', 'doctor2@hduce.com', 'Dra. María López', 'doctor'),
    ('patient1', 'patient1@hduce.com', 'María González', 'patient'),
    ('patient2', 'patient2@hduce.com', 'Carlos Rodríguez', 'patient')
ON CONFLICT (username) DO NOTHING;

-- TRIGGER PARA updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- TRIGGER PARA AUDITORÍA DE USUARIOS
CREATE OR REPLACE FUNCTION log_user_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_history (user_id, action, details, changed_by)
    VALUES (
        NEW.id,
        TG_OP,  -- INSERT, UPDATE, DELETE
        jsonb_build_object(
            'old', OLD,
            'new', NEW
        ),
        current_user
    );
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS log_user_changes_trigger ON users;
CREATE TRIGGER log_user_changes_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION log_user_changes();
