FROM python:3.11-slim

WORKDIR /app

# 1. Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Copiar shared-libraries DESDE LA RAÍZ
COPY ./shared-libraries ./shared-libraries

# 3. Instalar shared-libraries
RUN pip install -e ./shared-libraries

# 4. Copiar requirements del servicio
COPY ./backend/user-service/requirements.txt .

# 5. Instalar dependencias del servicio
RUN pip install --no-cache-dir -r requirements.txt

# 6. Copiar el código del servicio
COPY ./backend/user-service/ .

# 7. Ejecutar servicio
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
