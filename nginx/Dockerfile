# nginx/Dockerfile
FROM nginx:alpine

# Copiar configuración
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Exponer puertos
EXPOSE 80
EXPOSE 443

# Iniciar NGINX
CMD ["nginx", "-g", "daemon off;"]