FROM python:3.11-slim

WORKDIR /app

# 1. Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Copiar requirements primero
COPY ./backend/appointment-service/requirements.txt .

# 3. Instalar dependencias Python
RUN pip install --no-cache-dir -r requirements.txt

# 4. IMPORTANTE: Copiar TODO el directorio appointment-service
COPY ./backend/appointment-service/ .

# 5. Exponer puerto
EXPOSE 8002

# 6. Comando para ejecutar
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002", "--reload"]
