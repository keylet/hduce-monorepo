FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements primero (para cache de Docker)
COPY appointment-service/requirements.txt .

# Instalar dependencias del servicio
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt pydantic-settings

# IMPORTANTE: NO copiamos shared-libraries aquí porque se montan como volumen
# en docker-compose.yml. Solo necesitamos asegurar que existan.

# Copiar el código del servicio
COPY appointment-service/ /app/

# Configurar PYTHONPATH para encontrar shared-libraries
ENV PYTHONPATH=/app:/app/shared-libraries:

# Verificar archivos copiados
RUN echo "=== Archivos copiados a /app ===" && ls -la /app/

EXPOSE 8002

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]

