#!/bin/bash

set -e
set -u

# Crear usuario hduce_user si no existe (para compatibilidad)
echo "Creating user hduce_user if not exists..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hduce_user') THEN
            CREATE USER hduce_user WITH PASSWORD 'hduce_pass';
        END IF;
    END
    \$\$;
    GRANT ALL PRIVILEGES ON DATABASE postgres TO hduce_user;
EOSQL

function create_user_and_database() {
    local database=$1
    echo "Creating database $database"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
        CREATE DATABASE $database;
        GRANT ALL PRIVILEGES ON DATABASE $database TO postgres;
        GRANT ALL PRIVILEGES ON DATABASE $database TO hduce_user;
EOSQL
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Creating multiple databases: $POSTGRES_MULTIPLE_DATABASES"
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        create_user_and_database $db
    done
    echo "Multiple databases created successfully"
fi
