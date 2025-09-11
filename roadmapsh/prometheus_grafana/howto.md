
## Step-by-Step Guide to Setting Up Prometheus & Grafana

### 1. Prepare Your Server

- Ensure your server is accessible and has Docker installed (recommended for simplicity).
- Install your application (Nginx, Node.js, etc.) if not already running.

### 2. Deploy Prometheus

**Using Docker (recommended):**

```bash
docker run -d \
  --name=prometheus \
  -p 9090:9090 \
  -v /path/to/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

**Prometheus Configuration (`prometheus.yml`):**

Configure global parameters, scrape configs, and retention policies:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:9113']
```

### 3. Install Exporters

Exporters collect system and service metrics:

- **Node Exporter:** For system metrics (CPU, memory, disk, network)

```bash
docker run -d --name=node_exporter -p 9100:9100 prom/node-exporter
```

- **NGINX Exporter:** For NGINX metrics

```bash
docker run -d --name=nginx_exporter -p 9113:9113 nginx/nginx-prometheus-exporter
```

- **Other exporters:** For MySQL, MongoDB, etc., find suitable exporters.

### 4. Deploy Grafana

```bash
docker run -d \
  --name=grafana \
  -p 3000:3000 \
  -e "GF_SECURITY_ADMIN_PASSWORD=yourpassword" \
  grafana/grafana
```

### 5. Connect Grafana to Prometheus

- Access Grafana at `http://your_server:3000`
- Login (default user: `admin`, password: `yourpassword`)
- Add Prometheus as a data source:
  - Configuration URL: `http://localhost:9090`
- Create dashboards:
  - Use existing dashboards from Grafana's dashboard repository or build custom ones
  - Use PromQL queries to visualize metrics

### 6. Set Up Alerts & Notifications (Optional)

- Define alerting rules in Prometheus (`alert.rules.yml`)
- Configure Alertmanager for notifications (email, Slack)

---

## Tips & Best Practices

- Use Docker Compose to orchestrate all components together.
- Secure your Grafana and Prometheus instances with authentication and firewalls.
- Use persistent storage volumes for Prometheus data.
- Explore Grafana's community dashboards for quick setup.

---

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [NGINX Prometheus Exporter](https://github.com/nginxinc/nginx-prometheus-exporter)

---
