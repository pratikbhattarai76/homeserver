# Design Decisions
This document explains why I used the technologies. Not just what was chosen, but why it was chosen over the alternatives. Some of these were deliberate from the start, others came from debugging and learning along the way.

---

## Why Cloudflare Tunnel?
The server has no public ports open. All the external traffic comes in through an outbound-only Cloudflare Tunnel, which means the server never listens for incoming connections from the internet. This avoid port forwarding entirely and keeps the home IP hidden from DNS lookups.

Cloudflare also handles TLS certificates, DDoS protection, and provides Cloudflare Access for identity-based protection on sensitive services like Grafana, Nginx Proxy Manager, and Uptime Kuma.

---

## Why Docker?
Every service runs in its own container. This gives service isolation, consistent environments across the server and local deployment, and easy cleanup when something goes wrong. Docker Compose handles multi-container coordination for services that needs it (like Nextcloud and its database, Monitoring Stack)

---
## Why Nginx Proxy Manager?
NPM acts as the internal reverse proxy between Cloudflare Tunnel and the backend services. The tunnel forwards request to NPM, and NPM routes to the correct container based on the hostname.

Having NPM as a separete layer from the tunnel means I can change internal routing without touching the Cloudflare configuration. It also gives me a single internal ingress point that all services share.

NPM sits on both Docker networks (`docker-cloudflared` and `docker-proxy`) which is what makes it the bridge between the public ingress layer and the internal service layer.

---
## Why Pull-Based Deployment?
The portfolio application is deployed using a pull-based model. A bash script runs on the server every 30 minutes via cron, pulls the latest image from GHCR, compares image IDs, and recreates the container only if something changed.

Three reasons for this over push-based (where CI does the SSH into server):
1. No inbound access is needed. CI has no SSH keys, no deploy credentials, no way to reach the server directly. The server pulls when it is ready.
2. A compromised CI pipeline can push a bad image to GHCR but cannot execute any harmful commands on the server. So, the blast radius is bounded.
3. The server controls its own update flow. Pausing the cron script stops all updates regardless of what CI publishes.

---

## Why `:latest` for the Portfolio App?
Using `:latest` is normally and anti-pattern because it makes deployments non-reproducible and also is somewhat capable of breaking the service due to the mismatch of some configs after new version. Here it is intentionally kept latest and it is safe because the update script compares image digest, not tag names. The tag is the update channel, the digest is the version. The CI workflow also tags every build with `commit-<sha>` so there is always an immutable tag available for rollback if needed.

All other services use pinned image versions and do not use `:latest`.

---

## Healthcheck Strategy
Healthchecks were added selectively, not universally. The principle was to add a check where it catches a failure mode that would not be visible, and skip it where the cost outweighs the value such as `node-exporter` because it's image by default didn't ship bash or curl for checking the Healthcheck and I would have to use other methods which would not be worth it.

### Probe types used
Different services expose different liveness interfaces, so the probing method vaires across the service stacks:

- Database protocol probe - `mariadb-admin ping` for nextcloud-db. Tests the same TCP path application uses. No credentials needed because `ping` only checks server reachability, not authentication
- HTTP healthcheck endpoint - `curl -f` against `/api/health` for Grafana, `/healthy` for Prometheus, `/status.php` for Nextcloud, `/api` for Nginx Proxy Manager. It is used wherever the maintainer of the service ships a dedicated liveness endpoint.
- Image-shipped healthchecks - Vaultwarden, Gotify, Uptime Kuma, cAdvisot, and the portfolio app ships healthchecks baked into their Dockerfiles. It can be verified via `docker inspect`.

### Service-readiness chaining
`nextcloud-app` uses `depends_on: condition: service_healthy` against `nextcloud-db` to eliminate the startup race condition. Without this, the application can boot before MariaDB finishes InnoDB initialization.

### Intentionally without healthchecks
- **node-exporter** - built on a `scratch` base image with no shell, no HTTP client, and no package manager. Crashes hard on failure and Docker restarts it.
- **cloudflared** - the daemon handles connection failures internally by exiting and letting Docker restart it. Trying container health to tunnel state would mark the container unhealthy on every internet outage which creates alert noise about a condition that I as an operator already know about.

### Probe parameters
Default values unless noted: `interval: 30s`, `timeout: 10s`, `retries: 3-5` (higher for databases), `start_period: 30-60s` (higher for slow-booting services like Nextcloud and databases).

---

## Resource Limits
Memory and CPU limits are set on the three services most likely to cause problems if they run away: `nextcloud-db`, `nextcloud-app` and `prometheus`. All three get `mem_limit: 2g`. Nextcloud services get `cpus: 2.0`, Prometheus gets `cpus: 1.0`.

These limits are deliberately generous. After checking the existing status it is kept 10 to 20 times the cap of the current usage. Current usage is well under 200MB for each service. The limits exist as circuit breakers for runaway scenarios (memory leaks, bad queries, proper metrics in Prometheus). Without them, a container would consume all 16GB of host RAM and trigger the Linux OOM killer, which might kill the wrong process.

Other services (cloudflared, NPM, grafana, vaultwarden, uptime-kuma, gotify) do not have limits set. They are small, stateless or near-stateless, and have not shown any resource growth patterns that justify the added configuration.

Proper right-sizing would require collecting baseline data from Prometheus over several weeks and setting limits at observed peak plus some leeway or headroom.

---

## Removed Services

### Portainer
Portainer was removed bacause it duplicated functionality that Ansible and Docker Compose already provide in code-driven and reproducible way. It also required mounting `/var/run/docker.sock`, which grants root-equivalent control over the host. The rest of the stack follows a principle of least privilege, and a web UI with full host control was harmful, even behind Cloudflare Access.

---

## Ansible Refactor
The original Ansible structure had eight individual deployment playbooks `(deploy-nextcloud.yml`, `deploy-portfolio.yml`, etc.) that were nearly identical - each one checked for the service discovery, the compose file and the env file, then ran `docker compose up -d`. The only differences between them were the service name, path, and whether an env file was required.

These were refactored into a single shared task file `deploy-service.yml` that holds the deployment procedure once, and a single `deploy-all.yml` that calls it once per service with `import_tasks` and per-service tags. The individual playbooks were removed.
The original Ansible structure had eight individual deployment playbooks (`deploy-nextcloud.yml`, `deploy-portfolio.yml`, etc.) that were nearly identical — each one checked for the service directory, the compose file, and the env file, then ran `docker compose up -d`. The only differences between them were the service name, path, and whether an env file was required.

These were refactored into a single shared task file (`deploy-service.yml`) that holds the deployment procedure once, and a single `deploy-all.yml` that calls it once per service with `import_tasks` and per-service tags. The individual playbooks were removed.

Deploying a single service is now done with tags: `ansible-playbook deploy-all.yml --tags monitoring`. Deploying everything is just `ansible-playbook deploy-all.yml` with no tag filter.

`import_tasks` is used instead of `include_tasks` because tags need to propagate from the calling task to the included tasks, which only works with static imports.

The `docker compose pull` step was also removed from the deployment procedure. All services use pinned image versions so pulling on every deploy is unnecessary network traffic. The one `:latest` service (portfolio) has its own dedicated pull mechanism via the cron-based update script.

---

## Nextcloud Storage

Nextcloud's data volumes are set up as follows:

- `nextcloud-db-data` (named volume) — MariaDB data. Migrated from a bind mount (`./db-data`) to a named volume for consistency with the monitoring stack's volume approach.
- `./nextcloud-config` (bind mount) — Nextcloud's web root and configuration. Standard pattern from the official Nextcloud Docker docs.
- `/mnt/storage:/external/storage` (bind mount) — the 1TB HDD mounted into the container at `/external/storage` for use with Nextcloud's External Storage feature. This avoids the fragility of nesting bind mounts inside Nextcloud's internal data directory.

Previously, photos were mounted directly into Nextcloud's user data path (`/var/www/html/data/<user>/files/Pictures`). This caused potential `oc_filecache` desync issues because Nextcloud's file indexer would race with direct filesystem changes. The External Storage approach avoids this by letting Nextcloud manage the mount through its own supported mechanism.

---

## What Is Intentionally Not Done

- **Backups** — not currently configured. The plan is to set up restic-based backups to an external USB drive and an off-site destination (Backblaze B2) before the server holds any data that cannot be recreated. This was deferred because a Kubernetes migration is planned.
- **ansible-vault** — secrets are currently managed as `.env` files on the operator's laptop and synced to the server via `infra-sync.yml`. Encrypting them with ansible-vault and committing them to the repo would be more robust, but was deferred as the current approach works for a single-operator environment.
- **Log rotation for the portfolio update script** — the log file grows indefinitely. Acceptable for now given the small output per run, but should be addressed if the server runs for extended periods.
