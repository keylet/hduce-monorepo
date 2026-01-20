#!/bin/bash
# Script para preparar el entorno de notification-service

echo "?? Preparando notification-service..."

# Crear enlace simb?lico a shared-libraries (si no existe)
if [ ! -L "/app/shared-libraries" ] && [ ! -d "/app/shared-libraries" ]; then
    echo "?? Creando enlace a shared-libraries..."
    ln -sf /shared-libraries /app/shared-libraries
fi

# Ejecutar el comando original
exec "$@"
