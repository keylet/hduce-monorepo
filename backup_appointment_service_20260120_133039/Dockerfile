FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar shared-libraries desde contexto raíz
COPY shared-libraries ./shared-libraries

# Instalar shared-libraries
RUN pip install -e ./shared-libraries --force-reinstall

# Copiar requirements del servicio
COPY backend/appointment-service/requirements.txt .

# Instalar dependencias del servicio
RUN pip install --no-cache-dir -r requirements.txt

# Copiar SOLO el código de appointment-service
COPY backend/appointment-service/ .

EXPOSE 8002

# Ejecutar el main.py de appointment-service
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]
