# Grafana Dockerfile para HDuce
FROM grafana/grafana:10.1.0

# Copiar configuración personalizada
COPY grafana.ini /etc/grafana/grafana.ini

# Copiar dashboards de HDuce
COPY dashboards/ /etc/grafana/provisioning/dashboards/

# Exponer puerto
EXPOSE 3000
