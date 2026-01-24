FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements primero
COPY backend/user-service/requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar shared-libraries y instalarlas
COPY shared-libraries/ /app/shared-libraries/
RUN cd /app/shared-libraries && pip install -e .

# Copiar el código del servicio
COPY backend/user-service/ /app/

ENV PYTHONPATH=/app:$PYTHONPATH

EXPOSE 8001

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8001"]
