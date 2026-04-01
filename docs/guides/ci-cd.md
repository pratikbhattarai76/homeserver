# CI/CD Overview

The CI/CD is only applied to the portfolio application. The portfolio code --> [Portfolio Code](https://github.com/pratikbhattarai76/portfolio-app-deployment-pipeline) 

## CI (Github Actions)
- Code is verifies on push
- Docker image is built
- Image is pushed to GHCR

---
## CD (Server Side)

A pull-based deployment model is used:

- A scheduled script (cron) runs on the server every 30 mins
- It pulls the latest image from GHCR
- Compares the current and latest image IDs
- Recreates the container only if a new image is detected

---

## Benefits

- Automated and consistent build pipeline
- Prevents deployment of broken builds
- Avoids unnecessary container restarts
- Secure pull-based deployment (no public exposure required)
- Works well in private/zero-trust environments (Cloudflare Tunnel)
