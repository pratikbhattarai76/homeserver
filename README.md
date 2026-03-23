# 🏠 Private Cloud Infrastructure

A self-hosted private cloud and homelab infrastructure project focused on secure remote access, containerized service deployment, reverse-proxy-based ingress, and observability.

## Architecture Diagram

![Pratik-Labs Architecture](docs/architecture/architecture.png)

---

## 🧠 Overview

This project documents a self-hosted private cloud infrastructure built to practice real-world DevOps concepts, including secure ingress, containerized service deployment, reverse proxy routing, and observability in a production-like environment.

The stack is centered around Docker Compose, Cloudflare Tunnel, Nginx Proxy Manager, internal Docker networking, and persistent storage design across SSD and HDD tiers.

The environment is designed with **no public application ports exposed**, where Cloudflare handles the public edge while internal services remain isolated behind Docker networks and reverse proxy routing.

---

## 🖥️ Hardware & Environment

- **Host:** Custom Home Server  
- **CPU:** Intel i7-4770  
- **RAM:** 16GB DDR3  
- **System Drive:** 120GB SSD  
- **Data Drive:** 1TB HDD  
- **OS:** Ubuntu Server 24.04 LTS  
- **Admin Workstation:** Arch Linux Laptop  

---

## 🏗️ Core Architecture

### Ingress & Access
- **Domain:** `pratik-labs.xyz`  
- **DNS / Edge:** Cloudflare  
- **Public Ingress:** Cloudflare Tunnel (`cloudflared`)  
- **Identity Layer:** Cloudflare Access  
- **Reverse Proxy:** Nginx Proxy Manager  

### Container Platform
- **Container Runtime:** Docker Engine  
- **Orchestration:** Docker Compose  
- **Networking:** Internal Docker networks with service discovery via DNS  

### Private Administration
- **Remote Access:** Tailscale + SSH  
- **File Access:** SFTP over SSH  
- **Firewall:** UFW (restricted access policy)  

---

## 🌐 Network Design

The infrastructure follows a **private-by-default architecture**:

- No public application ports exposed  
- All ingress handled via outbound-only Cloudflare Tunnel  
- Internal communication via Docker networks and service names  
- Administrative access restricted via SSH and private networking (Tailscale)  

### Docker Networks
- **`docker-cloudflared`** → ingress handoff network  
- **`docker-proxy`** → internal service communication  

---

## 📦 Deployed Services

| Service | Description |
|--------|------------|
| **Cloudflare Tunnel** | Secure ingress without exposing ports |
| **Nginx Proxy Manager** | Reverse proxy and routing |
| **Nextcloud** | Self-hosted storage with hybrid SSD + HDD design |
| **MariaDB** | Database backend for Nextcloud |
| **Vaultwarden** | Self-hosted password manager |
| **Portfolio Application** | Containerized app deployed from separate repo |
| **Uptime Kuma** | Service uptime monitoring |
| **Prometheus** | Metrics collection |
| **Grafana** | Metrics visualization |
| **Node Exporter** | Host-level metrics |
| **cAdvisor** | Container-level metrics |
| **Portainer** | Docker management UI |

---

## 💾 Storage Design

A hybrid storage model balances performance and capacity:

### SSD Tier
- OS  
- Docker data  
- Databases  
- Application state  

### HDD Tier
- Media storage  
- Large file storage (`/mnt/storage`)  

### Strategy
Latency-sensitive workloads remain on SSD, while large data is offloaded to HDD.  
Nextcloud uses both tiers for optimal performance and capacity.

---

## 🔐 Security Model

Security is a core design principle:

- No public application ports exposed  
- Cloudflare Tunnel for ingress  
- Cloudflare Access for identity-based protection  
- UFW firewall with default deny  
- SSH key-based authentication  
- Secrets managed via `.env` (not stored in Git)  
- Container isolation through Docker networking  

---

## 🚀 Deployment Automation

This infrastructure integrates with a **pull-based deployment model**:

- Docker images are built via GitHub Actions  
- Images are published to GitHub Container Registry (GHCR)  
- A scheduled Bash script on the server checks for updates  
- Services are updated automatically using Docker Compose  

### Why Pull-Based?

- No inbound deployment access required  
- Server remains private  
- Secure and controlled updates  
- Mirrors real-world internal deployment patterns  

---

## ⚙️ Operations Workflow

1. Configuration is version-controlled in GitHub  
2. Infrastructure changes are synchronized to the server  
3. Services are deployed via Docker Compose  
4. Application updates are handled via automated pull-based deployment  

---

## 📁 Repository Structure

```text
.
├── docker
│   ├── cloudflared
│   │   └── docker-compose.yml
│   ├── monitoring
│   │   ├── docker-compose.yml
│   │   └── prometheus
│   │       └── prometheus.yml
│   ├── nextcloud
│   │   └── docker-compose.yml
│   ├── nginx-proxy-manager
│   │   └── docker-compose.yml
│   ├── portainer
│   │   └── docker-compose.yml
│   ├── portfolio
│   │   └── docker-compose.yml
│   ├── uptime-kuma
│   │   └── docker-compose.yml
│   └── vaultwarden
│       └── docker-compose.yml
├── docs
│   ├── architecture.drawio
│   └── architecture.png
├── README.md
└── scripts
    └── update-portfolio.sh


```

---

## 📌 Notes
This repository contains infrastructure configuration and documentation only. 
The portfolio application source code is maintained seperately: [Portfolio Repository](https://github.com/pratikbhattarai76/portfolio-app-deployment-pipeline)
