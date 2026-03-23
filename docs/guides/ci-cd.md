# CI/CD Overview

The CI/CD is only applied to the portfolio application. The portfolio code --> [Portfolio Code](https://github.com/pratikbhattarai76/portfolio-app-deployment-pipeline) 

## CI (Github Actions)
- Code is verifies on push
- Docker image is built
- Image is pushed to GHCR

---

## CD (Server Side)
- A Bash script checks for updated images
- Compares Image ID
- Recreates service only if the image has changed

---

## Benefits
- Automated deployment
- Avoids unnecessary restarts
- Secure pull-based model
