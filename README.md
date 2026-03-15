# 🏠 Home Server Infrastructure
**A Professional, private cloud infrastructure built with a focus on Zero Trust networking, Infrastructure as Code, and Security.**

## 🖥️ Hardware Specs
- **Model:** Custom
- **CPU:** Intel i7-4770
- **RAM:** 16GB DDR3
- **System Drive:** 120GB SSD
- **Data Drive:** 1TB HDD
- **OS:** Ubuntu Server 22.04 LTS

---

## 1. Storage Strategy & Configuration
To optimize performance, the OS and Docker configurations live on the SSD while, the 1TB HDD is used for data storage.

- **Device:** `/dev/sda1`
- **UUID:** `4250e634-f248-4591-b2b0-6d12919f6c8e`
- **Mount Point:** `/mnt/storage`
- **Filesystem:** `ext4`

### 1.1 How It Was Configured:
- Created Mount Point: `sudo mkdir -p /mnt/storage`
- Added to `/etc/fstab` for persistence: `UUID=4250e634-f248-4591-b2b0-6d12919f6c8e  /mnt/storage  ext4  defaults  0  2`
- Set Ownership: `sudo chown -R pratikserver:pratikserver /mnt/storage`

---

## 2. Container Environment
- **Engine:** Docker Engine
- **Orchestration:** Docker Compose
- **User Permissions:** `pratikserver` added to `docker` group.

### 2.1 Installation verification:
- `docker --version`
- `docker compose version`

---

## 3. Networking & Security
This infrastructure follows a **Zero Trust** model. No ports are opened on the local router; all ingress traffic is handled via an encrypted tunnel.

- **Network Isolation:** A dedicated Docker bridge network `docker-proxy` handles inter-container communication.
- **Service Discovery:** Containers communicate via internal Docker DNS (Service Names) rather than static IPs.
- **External Access:** Cloudflare Tunnel (`cloudflared`) connects the local `docker-proxy` network to the Cloudflare Edge.

### 3.1 Network Setup:
```bash
docker network create docker-proxy
```
### 3.2 Identity-Aware Access Control
- **Tool:** Cloudflare Access (Zero Trust)
- **Policy:** Restricted to authorized email via One-Time PIN (OTP).
- **Result:** Management UI (`proxy.pratik-labs.xyz`) is hidden behind an identity wall, providing MFA for the infrastructure.

---

## 4. Traffic Management
Nginx Proxy Manager (NPM) is used as a Reverse Proxy to route incoming traffic from the tunnel to the correct application.

- **Admin Subdomain:** `proxy.pratik-labs.xyz`
- **Internal Route:** `http://proxy:81`
- **Features:** SSL management, Access Lists, and custom headers.

---

## 5. Deployed Services

### 5.1 Vaultwarden (Password Manager)
- **Subdomain:** `vault.pratik-labs.xyz`
- **Description:** Lightweight Bitwarden-compatible server.
- **Persistence:** Database stored on SSD (`./vw-data`) for high-performance I/O.
- **Security:** `SIGNUPS_ALLOWED=false` (Disabled after initial admin account creation).

### 5.2 Nextcloud
- **Subdomain:** `cloud.pratik-labs.xyz`
- **Database:** MariaDB `lts-ubi9` (Enterprise-grade Red Hat UBI based image).
- **Collaborative Storage:** Implemented a shared 'FamilyUploads' directory within the Pictures mount. 
- **Hybrid Storage Strategy:** 
    - **Performance Layer (SSD):** Application core, metadata, and image thumbnails are stored on the SSD for a responsive user interface.
    - **Capacity Layer (HDD):** The 1TB HDD directory `/mnt/storage/Photos/Pictures` is mapped via a **Docker Bind Mount** directly into the user's data directory.
- **Protocol Abstraction:** Utilizes MariaDB as a "drop-in replacement" for MySQL, configuring connectivity via `MYSQL_` environment variables.

### 5.3 Portainer
- **Subdomain:** `portainer.pratik-labs.xyz`
- **Purpose:** GUI-based Docker orchestration and management.
- **Security:** Integrated with the host's `/var/run/docker.sock` to provide real-time control over the container environment. Restricted via Cloudflare Access identity verification.

### 5.4 Monitoring & Observability Stack (Prometheus & Grafana)
- **Subdomain:** `monitor.pratik-labs.xyz`
- **Architecture:** 
    - **Prometheus:** Acts as the Time Series Database (TSDB) collecting metrics.
    - **Node Exporter:** Captures host hardware metrics (CPU, RAM, Disk I/O).
    - **cAdvisor:** Captures per-container resource usage.
    - **Grafana:** Provides visual dashboards (Utilizing Community IDs `1860` and `19908`).
- **Network Strategy:** Internal-only isolation. Metrics are scraped over the `docker-proxy` network; no telemetry ports are exposed to the public internet.

### 5.5 Uptime Kuma
- **Subdomain:** `status.pratik-labs.xyz`
- **Monitoring Strategy:** 
    - **Docker Socket Integration:** Direct process monitoring for critical containers
    - **Push Notifications:** (Planned) Integrated alerting via Gotify/Discord for instant downtime alerts.

---

## 6. System Hardening & Firewall
To maintain a "Silent Server" profile, the host utilizes a strict firewall configuration:
- **UFW (Uncomplicated Firewall):** Configured to `Default Deny Incoming`. 
- **Allowed Traffic:** 
    - Port `22/tcp` (SSH) restricted to local and Tailscale interfaces.
    - Full access via `tailscale0` for secure remote management.
- **Zero-Port Exposure:** No web ports (80/443) are opened on the router; all traffic is handled via an outbound-only Cloudflare Tunnel.

---

## 7. DevOps Workflow
To maintain industry standards, this project follows a strict **"Infrastructure as Code"** workflow:

-   **Code on Arch Laptop:** All YAML and configuration files are written and tested locally.
-   **Secret Management:** Secrets (Tokens/Passwords) are stored in `.env` files and strictly blocked from GitHub via `.gitignore`.
-   **Syncing:** Configurations are moved from the local workstation to the production server via `scp`.
-   **Deployment:** Services are managed via SSH using `docker compose up -d` for orchestration.

---

## 8. Remote File Management
To maintain a minimal attack surface, file management is handled via **SFTP** (SSH File Transfer Protocol) instead of Samba.

- **Protocol:** SFTP (via SSH Port 22)
- **Mount Point:** `sftp://pratikserver@192.168.1.250/mnt/storage`
- **Integration:** Integrated into Arch KDE Plasma via Dolphin Places.
- **Security:** Uses Ed25519 SSH Keys for passwordless, encrypted data transfer.

---

## 9. Hybrid Storage Logic
A key architectural decision was the "Decoupled Storage" model. 

- **The Portal Concept:** Using Docker volumes, I created a "portal" between the physical 1TB HDD and the Nextcloud internal filesystem.
- **Path Mapping:** 
   `Host: /mnt/storage/Photos/Pictures` → `Container: /var/www/html/data/pratikbhattarai76/files/Pictures`
- **Outcome:** Large media files remain on the high-capacity HDD, while the database and cache stay on the SSD. This provides the speed of an SSD with the 1TB capacity of the HDD.

---

## 10. Security & Identity Handshake
- **Secrets Management:** No passwords or tokens are stored in plain text within the repository. The `${VARIABLE}` syntax in Docker Compose pulls values from a local-only `.env` file.
- **IAP (Identity-Aware Proxy):** The infrastructure utilizes Cloudflare Access as an authentication layer. Users must pass a multi-factor email verification before traffic is allowed to reach the internal NGINX Proxy.
- **Service Isolation:** Each application is isolated within its own container, and only the Reverse Proxy is allowed to communicate with the Cloudflare Tunnel.

---
