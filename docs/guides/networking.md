# Networking Design

## Overview
The system follows a private-by-default model.

---

## Flow
```text
User -> Cloudflare -> Cloudflare Tunnel -> Nginx Proxy Manager -> Docker Services
```
---

## Components
- Cloudflare Tunnel -> Secure Ingress 
- Nginx Proxy Manager -> Reverse Proxy
- Docker Networks:
  - docker-cloudflared - Ingress Layer
  - docker-proxy -> Internal Services
  
---
  
## Design Decisions
- No public application ports exposed
- All external traffic flows throught Cloudflare Tunnel
- Internal services are isolated using Docker Networks
- Internal Service Communication via Docker DNS (Service Names)
- Reverse proxy centralizes routing and access control
