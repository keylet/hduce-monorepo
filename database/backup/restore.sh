#!/bin/bash
# Script para restaurar datos en AWS

echo 'Restaurando datos de HDUCE...'

databases=("auth_db" "user_db" "appointment_db" "notification_db")

for db in "\"; do
    echo "Restaurando \notification_db..."
    if [ -f "/opt/hduce/database/backup/\notification_db.sql" ]; then
        psql -U postgres -d \notification_db -f "/opt/hduce/database/backup/\notification_db.sql"
        echo " \notification_db restaurado"
    else
        echo "  Archivo \notification_db.sql no encontrado, usando esquema inicial"
    fi
done

echo ' Restauración completada'
