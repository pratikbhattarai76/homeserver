# Deployment Flow
This project portfolio application uses a pull-based deployment model. The portfolio code --> [Portfolio Code](https://github.com/pratikbhattarai76/portfolio-application-deployment) 

---

## Flow
1. Code is pushed to GitHub
2. GitHub Actions validates and builds the Docker image
3. Image is pushed to GitHub Container Registry (GHCR)
4. A bash script runs on the server every 30 mins via cron
5. The script pulls the latest image
6. If the image has changed, Docker Compose recreates the service

---

## Why Pull-Based?
- No inbound SSH from CI
- Improved security
- Server remains private
