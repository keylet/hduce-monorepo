=== DOCKER IMAGES PARA AWS ===

ESTRUCTURA:
- Dockerfile.auth.prod      (Puerto 8000)
- Dockerfile.user.prod      (Puerto 8001)  
- Dockerfile.appointment.prod (Puerto 8002)
- Dockerfile.notification.prod (Puerto 8003)
- Dockerfile.mqtt.prod      (Puerto 8004)
- Dockerfile.metrics.prod   (Puerto 8005)

USO:
# Build de una imagen
docker build -f Dockerfile.auth.prod -t hduce-auth:prod .

# Build todas
.\build-all.ps1

DOCKERHUB:
# Tag y push
docker tag hduce-auth:prod tuusuario/hduce-auth:latest
docker push tuusuario/hduce-auth:latest
