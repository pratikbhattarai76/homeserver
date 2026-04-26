# Architecture

The portfolio application is deployed as a containerized server-side rendered (SSR) application on Kubernetes.

## Flow

```
User
  ↓
Cloudflare DNS → Cloudflare Tunnel
  ↓
cloudflared pod → Traefik Ingress
  ↓
Portfolio Service → Portfolio Pod (Astro SSR on Node.js)
```

## Explanation

- The application is built using Astro with server-side rendering.
- It runs inside a Kubernetes pod as a Docker container using Node.js as the runtime.
- Cloudflare handles DNS and TLS termination for the domain.
- Traefik routes requests based on the `Host` header matching `portfolio.pratik-labs.xyz`.
- The application listens on port 4321 inside the container, exposed via a ClusterIP Service on port 80.
- Argo CD manages the Deployment, Service, and Ingress manifests from Git.

## Key Design Decisions

- Docker is used for consistent runtime across environments.
- Node.js is required because the app uses SSR and features like Nodemailer.
- The Kubernetes cluster only runs the built image — application source code is never on the server.
- Deployment manifests live in a separate infrastructure repo ([k8s-homelab-platform](https://github.com/pratikbhattarai76/k8s-homelab-platform)), keeping application code and infrastructure concerns decoupled.
