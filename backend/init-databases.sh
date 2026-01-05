#!/bin/sh

set -e

echo "=== Creating HDUCE Databases ==="

# Lista de bases de datos a crear
DATABASES="auth_db user_db appointment_db notification_db medical_db"

for db in $DATABASES; do
    echo "Creating database: $db"
    psql -U postgres -c "CREATE DATABASE $db;" || echo "Database $db already exists or error"
done

echo "=== All databases created successfully ==="
