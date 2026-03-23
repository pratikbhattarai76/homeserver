# Networking Design

## Overview
The system follows a private-by-default model.

---

## Flow
User -> Cloudflare -> Cloudflare Tunnel -> Nginx Proxy Manager -> Docker Services

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
- Internal services are isolated
- Communication vis Docker DNS (Service Names)
