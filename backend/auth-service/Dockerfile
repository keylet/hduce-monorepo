FROM python:3.11-slim

WORKDIR /app

# 1. Instalar dependencias
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Copiar requirements
COPY backend/auth-service/requirements.txt .

# 3. Instalar dependencias
RUN pip install --no-cache-dir --upgrade pip
# Instalar dependencias del auth-service
RUN pip install --no-cache-dir -r requirements.txt

# Instalar dependencias de shared-libraries si existen
RUN if [ -f /app/shared-libraries/requirements.txt ]; then \
    pip install --no-cache-dir -r /app/shared-libraries/requirements.txt; \
    fi

# 4. Copiar SOLO auth-service (pero mantener estructura)
COPY backend/auth-service/ /app/
COPY shared-libraries/ /app/shared-libraries/

# 5. Asegurar que Python encuentre los módulos
ENV PYTHONPATH="/app:/app/shared-libraries:$PYTHONPATH"

# 6. Puerto
EXPOSE 8000

# 7. Comando SIMPLE - main está en /app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

