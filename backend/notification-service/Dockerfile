# Dockerfile simplificado para notification-service
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar shared-libraries primero (ya está en el contexto)
COPY ./shared-libraries ./shared-libraries

# Instalar shared-libraries
RUN pip install -e ./shared-libraries

# Copiar requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el resto del código
COPY . .

# Script de inicio simple
RUN echo '#!/bin/bash' > start.sh && \
    echo 'echo "🚀 Iniciando API de Notification Service..."' >> start.sh && \
    echo 'python main.py &' >> start.sh && \
    echo 'sleep 3' >> start.sh && \
    echo 'echo "🎯 Iniciando Consumer de RabbitMQ..."' >> start.sh && \
    echo 'python independent_consumer.py' >> start.sh && \
    chmod +x start.sh

# Exponer puerto
EXPOSE 8003

# Comando de inicio
CMD ["./start.sh"]
