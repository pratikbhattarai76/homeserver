# Networking Design

The system follows a private-by-default model. The server has no inbound ports open to the internet - all external traffic comes in through an outbound-only Cloudflare Tunnel.

---

## Request Flow

```text
User → Cloudflare → Cloudflare Tunnel → Nginx Proxy Manager → Docker Service
```

A user request to `vault.pratik-labs.xyz` first hits Cloudflare's edge, which terminates TLS and applies any Cloudflare Access policies. The request is then forwarded down the existing outbound tunnel connection to the cloudflared container on the server. From there it reaches Nginx Proxy Manager, which routes to the correct backend container based on the hostname. The backend container responds, and the response travels back the same way.

---

## Components

- **Cloudflare Tunnel** — outbound-only secure ingress. The only entry point for external traffic.
- **Nginx Proxy Manager** — internal reverse proxy. Routes requests by hostname to the right backend container.
- **Docker Networks**
  - `docker-cloudflared` — the ingress handoff network. Only the cloudflared container and NPM are on this network.
  - `docker-proxy` — the internal service network. NPM and all backend services are on this network.

NPM sits on **both** networks, which is what makes it the bridge between the public ingress layer and the internal services. No backend service is reachable from the cloudflared network directly.

---

## Design Decisions

- No public application ports exposed on the host.
- All external traffic flows through Cloudflare Tunnel, never through port forwarding.
- Internal services are isolated on the `docker-proxy` network and only reachable through NPM.
- Internal service communication uses Docker's built-in DNS, so services reach each other by container name (e.g. `nextcloud-app` connects to `nextcloud-db` by name, not IP).
- The reverse proxy centralizes routing and access control in one place rather than spreading it across each service.
