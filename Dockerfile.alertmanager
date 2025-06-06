FROM prom/prometheus:latest

# Create config directory in container
USER root
RUN mkdir -p /etc/prometheus

# Copy Prometheus configuration files into the container
COPY monitoring/prometheus.yml /etc/prometheus/prometheus.yml
COPY monitoring/alerts.yml /etc/prometheus/alerts.yml

# Set the working directory
WORKDIR /etc/prometheus

# Expose Prometheus port
EXPOSE 9090

# Start Prometheus with explicit config path
CMD ["--config.file=/etc/prometheus/prometheus.yml", "--web.route-prefix=/prometheus", "--web.external-url=/prometheus"]