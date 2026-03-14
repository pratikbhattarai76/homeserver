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
1. Created Mount Point: `sudo mkdir -p /mnt/storage`
2. Added to `/etc/fstab` for persistence: `UUID=4250e634-f248-4591-b2b0-6d12919f6c8e  /mnt/storage  ext4  defaults  0  2`
3. Set Ownership: `sudo chown -R pratikserver:pratikserver /mnt/storage`

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

---

## 6. DevOps Workflow
To maintain industry standards, this project follows a strict **"Infrastructure as Code"** workflow:

*   **Code on Arch Laptop:** All YAML and configuration files are written and tested locally.
*   **Secret Management:** Secrets (Tokens/Passwords) are stored in `.env` files and strictly blocked from GitHub via `.gitignore`.
*   **Syncing:** Configurations are moved from the local workstation to the production server via `scp`.
*   **Deployment:** Services are managed via SSH using `docker compose up -d` for orchestration.
