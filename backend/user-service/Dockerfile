FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements primero
COPY backend/user-service/requirements.txt .
COPY shared-libraries ./shared-libraries

# Instalar shared-libraries
RUN pip install -e ./shared-libraries --no-cache-dir

# Instalar requirements del user-service
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código del user-service
COPY backend/user-service/ .

# VERIFICACIÓN SIMPLE Y SEGURA (sin caracteres especiales)
RUN echo "Verificando imports críticos..." && \
    python -c "from hduce_shared.auth.jwt_manager import JWTManager; print('✅ JWTManager importado exitosamente')"

# Comando por defecto
CMD ["python", "main.py"]
