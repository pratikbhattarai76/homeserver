# Design Decisions

## Why Cloudflare Tunnel?
- Avoids port forwarding
- Reduces attack surface
- Provides secure ingress

---

## Why Docker?
- Service Isolation
- Easy Deployment
- Consistent Environments

---

## Why Reverse Proxy?
- Centralized Routing
- Multiple services under one domain

---

## Why Pull-Based Deployment?
- No inbound access required
- Server controls deployment
- Improved Security
