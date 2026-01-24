#!/bin/bash
# seed-hduce-data.sh
# Script para sembrar datos iniciales en HDUCE (ejecutar dentro de contenedor)

echo "=== SEMBRANDO DATOS HDUCE ==="

# Ejecutar script Python
python /app/seed_data.py

# Verificar datos
echo "
=== VERIFICANDO DATOS ==="
psql -U postgres -d auth_db -c "SELECT 'auth_db' as db, COUNT(*) as users FROM users;"
psql -U postgres -d appointment_db -c "SELECT 'appointment_db' as db, COUNT(*) as specialties FROM specialties;"
psql -U postgres -d appointment_db -c "SELECT 'appointment_db' as db, COUNT(*) as doctors FROM doctors;"

echo "
✅ Proceso completado"
