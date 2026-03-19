# 🏠 Private Cloud Infrastructure

A self-hosted private cloud and homelab infrastructure project focused on secure remote access, containerized service deployment, reverse-proxy-based ingress, and observability.

## Architecture Diagram

![Pratik-Labs Architecture](docs/architecture.png)

## Overview

This project documents my home server infrastructure, built to practice real-world DevOps and cloud engineering concepts in a self-hosted environment. The stack is centered around Docker Compose, Cloudflare Tunnel, Nginx Proxy Manager, internal Docker networking, and persistent storage design across SSD and HDD tiers.

The environment is designed around a zero-open-port model for public ingress, with Cloudflare handling the public edge and tunnel connectivity while internal services remain isolated behind Docker networks and reverse proxy routing.

## Hardware & Environment

- **Host:** Custom Home Server
- **CPU:** Intel i7-4770
- **RAM:** 16GB DDR3
- **System Drive:** 120GB SSD
- **Data Drive:** 1TB HDD
- **OS:** Ubuntu Server 24.04 LTS
- **Admin Workstation:** Arch Linux Laptop

## Core Architecture

### Ingress & Access
- **Domain:** `pratik-labs.xyz`
- **DNS Provider / Edge:** Cloudflare
- **Public Ingress:** Cloudflare Tunnel (`cloudflared`)
- **Identity Layer:** Cloudflare Access
- **Reverse Proxy:** Nginx Proxy Manager

### Container Platform
- **Container Runtime:** Docker Engine
- **Orchestration:** Docker Compose
- **Service Networking:** Docker bridge networks with internal DNS-based service discovery

### Private Administration
- **Remote Management:** Tailscale + SSH
- **File Access:** SFTP over SSH
- **Firewall:** UFW with restricted management access

## Network Design

The infrastructure follows a private-by-default design:

- No public router port forwarding for application traffic
- Public access is handled through an outbound-only Cloudflare Tunnel
- Internal services communicate over Docker networks using service names instead of static IPs
- Administrative interfaces are additionally protected with Cloudflare Access where appropriate

### Docker Networks
- **`docker-cloudflared`**: tunnel-facing network for ingress handoff
- **`docker-proxy`**: internal application network for reverse proxy routing and inter-service communication

## Deployed Services

### Cloudflare Tunnel
Provides secure outbound tunnel connectivity between the home server and Cloudflare, allowing public access to internal services without exposing router ports.

### Nginx Proxy Manager
Acts as the internal reverse proxy and hostname-based traffic router for all web services. It handles service routing and centralizes ingress management behind the Cloudflare tunnel.

### Nextcloud
Self-hosted private cloud platform used for centralized file and photo access.

- Reverse-proxied through `cloud.pratik-labs.xyz`
- Backed by a dedicated MariaDB container
- Uses hybrid storage:
  - **SSD tier** for application state, database-backed metadata, and responsive UI operations
  - **HDD tier** for large photo/media storage mounted from `/mnt/storage`

### MariaDB
Dedicated database backend for Nextcloud, running as a separate persistent containerized service.

### Vaultwarden
Self-hosted Bitwarden-compatible password manager.

- Reverse-proxied through `vault.pratik-labs.xyz`
- Public signups disabled
- Persistent application data stored on SSD-backed storage

### Portfolio Application
Containerized personal portfolio service deployed from a separate application repository and pulled as a prebuilt Docker image.

### Uptime Kuma
Endpoint-based service monitoring for public-facing applications and internal availability checks.

- Reverse-proxied through `status.pratik-labs.xyz`
- Used primarily for HTTPS-based monitoring of real service availability

### Prometheus
Metrics collection and time-series storage for infrastructure observability.

### Grafana
Visualization layer for infrastructure dashboards powered by Prometheus metrics.

### Node Exporter
Provides host-level metrics such as CPU, RAM, disk, and system performance data.

### cAdvisor
Provides container-level resource metrics for Docker workloads.

### Portainer
Web-based Docker management interface used for operational convenience and quick inspection of running services.

## Storage Design

The server uses a hybrid storage model to balance performance and capacity.

### SSD Tier
Used for:
- Ubuntu OS
- Docker service state
- Container Data Directories
- Databases
- Monitoring State
- Configuration-heavy Workloads

### HDD Tier
Used for:
- Large photo/media storage
- Bulk file storage mounted under `/mnt/storage`

### Storage Strategy
This design keeps latency-sensitive application state on SSD while offloading large user media to the HDD. In particular, Nextcloud uses both tiers: its application and metadata-related state remain on SSD, while large photo storage is mapped from the HDD into the container.

## Security Model

Security is a major design focus of this environment.

- **No public router exposure** for application traffic
- **Cloudflare Tunnel** used for secure ingress
- **Cloudflare Access** used to protect management interfaces
- **UFW** configured with a restrictive default policy
- **SSH key authentication** used for remote administration
- **Secrets kept out of Git** through local `.env` files and `.gitignore`
- **Container isolation** enforced through Docker networks and service separation

## Operations Workflow

This project follows a simple infrastructure workflow:

1. Configuration is written and updated locally on the Arch Linux workstation
2. Changes are tracked in GitHub
3. Configuration is synchronized to the Ubuntu server
4. Services are deployed and updated with Docker Compose over SSH

This keeps the infrastructure reproducible, version-controlled, and easy to evolve over time.

## Repository Structure

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
└── README.md

```
## Key Learning Areas

This project helps me practice and demonstrate:

- Docker and Docker Compose
- Teverse proxy Design
- Cloudflare Tunnel and Private Ingress
- Internal Service Networking
- Persistent Container Storage
- Monitoring and Observability
- Linux Server Administration
- Zero-trust-oriented Remote Access Patterns
- Self-hosted Service Operations

## Future Improvements

Planned next steps for the project include:

- Automated backup and restore procedures
- CI/CD for containerized application deployment
- Improved alerting and notification integrations
- Pinned image versions and update strategy improvements
- Terraform and cloud-based infrastructure projects to extend beyond the homelab

## Notes

This repository contains infrastructure configuration and documentation only. Application source code for the portfolio service is maintained separately in its own repository.
For Portfolio Application : [portfolio-app](https://github.com/pratikbhattarai76/portfolio-app)
