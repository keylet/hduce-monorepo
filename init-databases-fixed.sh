#!/bin/bash
set -e

# Usar variables con valores por defecto si no están definidas
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}

echo "Inicializando bases de datos..."
echo "Usuario PostgreSQL: $POSTGRES_USER"

# Función para crear usuario y base de datos
create_db() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    
    echo "  Creando base de datos '$db_name' para usuario '$db_user'..."
    
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE USER $db_user WITH PASSWORD '$db_password';
        CREATE DATABASE $db_name;
        GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;
EOSQL
}

# Crear bases de datos para cada microservicio
create_db "user_db" "hduce_user" "hduce_password"
create_db "auth_db" "hduce_auth" "hduce_password"
create_db "appointment_db" "hduce_appointment" "hduce_password"
create_db "notification_db" "hduce_notification" "hduce_password"

echo "✅ Bases de datos inicializadas exitosamente"
