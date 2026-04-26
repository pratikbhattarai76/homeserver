# Services 
Each service runs in its own Docker container and is deployed via Docker compose. Services are grouped by purpose. All of them sit on the `docker-proxy` network internally,   `cloudflared` which sits on `docker-cloudflared`. Nginx Proxy Manager (NPM) sits in the two networks.

---

## Ingress Layer

### cloudflared
The Cloudflare Tunnel daemon. Maintains an outbound connection to Cloudflare's edge so that requests to public hostnames like `vault.pratik-labs.xyz` can reach the server without any inbound ports being open. This is the only entry point for external traffic.

### nginx-proxy-manager
Internal reverse proxy. Cloudflare Tunnel forwards all incoming requests to NPM, and NPM routes them to the correct backend container based on the hostname. NPM is on both Docker networks (`docker-cloudflared` and `docker-proxy`), which makes it the bridge between the public ingress layer and the internal services.

---

## Applications

### nextcloud-app and nextcloud-db 
Self-hosted file storage and personal cloud. The app container runs Nextcloud on Apache, the db container runs MariaDB. They are chained so that the app waits for the database to be halthy before starting. The 1TB hdd is mounted into the app  at `/external/storage` and exposed through Nextcloud's External Storage feature.

### vaultwarden
Self-hosted password manager, compatible with Bitwarden clients. Sits behind Cloudflare Access for extra identity layer beyond the application's own login.

### portfolio-app
The personal portfolio website. The only service in this stack with a CI/CD pipeline Built and published from the [portfolio-application-deployment](https://github.com/pratikbhattarai76/portfolio-application-deployment) repository, then pulled to the server via a cron-based update script. See [ci-cd.md](ci-cd.md) for the full pipeline.

---

## Monitoring Stack

### prometheus
Metrics collection. Scrapes node-exporter and cAdvisor on a 15-second interval and stores time series data locally.

### grafana
Visualization. Connects to Prometheus as its data source and serves dashboards for host metrics and container metrics.

### node-exporter
Host-level metrics agent. Exposes CPU, memory, disk, and network statistics from the underlying server for Prometheus to scrape.

### cadvisor
Container-level metrics agent. Exposes per-container CPU, memory, and I/O statistics from the underlying server for Prometheus to scrape.

### uptime-kuma
Service uptime monitoring. Probes each public service over HTTP and tracks response time and availability over time. Independent of the Prometheus stack so that monitoring still works if Prometheus or Grafana goes down

### gotify
Notification delivery. Receives alerts from Uptime Kuma and pushes them to subscribed devices.

## Notes
All services run in isolated docker containers.
