#!/bin/bash

# Iniciar la API de FastAPI en segundo plano
echo "?? Iniciando API de Notification Service en puerto 8003..."
python main.py &

# Esperar un momento para que la API inicie
sleep 3

# Iniciar el consumidor de RabbitMQ en primer plano (mantiene el contenedor activo)
echo "?? Iniciando Consumer de RabbitMQ..."
python independent_consumer.py
