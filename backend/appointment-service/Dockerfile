FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# CORRECCIÓN CRÍTICA: Copiar SOLO los archivos de appointment-service
# Usar rutas relativas desde el contexto de build
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar solo los archivos Python de appointment-service
COPY . .

EXPOSE 8002

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]
