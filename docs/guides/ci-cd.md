# CI/CD
The portfolio application is the only service in this stack with a CI/CD pipeline. This document describes how the portfolio app gets from a git push to a running container on the server.

---

## Two Repositories, One Pipeline
The portfolio application lives in two separate repositories that meet at GitHub Container Registry (GHCR):

- [portfolio-application-deployment](https://github.com/pratikbhattarai76/portfolio-application-deployment) - application source code, Dockerfile, and the GitHub Actions workflow that pushes the container image.
- private-cloud-infrastructure (this repository) - the compose file, deployment script, and Ansible playbook that pull and run published image on the home server.

The handoff happens at `ghcr.io/pratikbhattarai76/portfolio-app`. The application repo's job ends when the image is pushed. The infrastructure repo's job starts when the cron script pulls it.

```text
portfolio-application-deployment                                         private-cloud-infrastructure
              |                                                                     
              | push to main                                                          |
              |                                                                       |
              |                                                                       |
              |                                                                       |
              |                                                                       |
              |                                                                       |
              |                                                                       |
              ↓                                                                       | 
GitHub Action builds and pushes the image                                             |
              |                                                                       |
              |                                                                       |  
              ↓                                                                       ↓
ghcr.io/pratikbhattarai76/portfolio-app:latest ────────────────────────────→  update-portfolio.sh
                                                    pulled by cron job         (every 30 minutes)
                                                                                      |
                                                                                      ↓
                                                                            docker compose recreates
                                                                            container if image changed
```
This separation matters because the application repository can be developed, tested, and rebuilt without touching infrastructure. The infrastructure repo can be organized without rebuilding the application. And the container registry is the contract between them.

---

## CI Side (GitHub Actions)
The workflow lives in the application repository at `.github/workflows/docker.yml`. It has two jobs:

**`verify`** runs on every pull request and every push to main. It installs dependencies, runs `npm run check` for type checking, runs the production build, runs a smoke test that boots the built server and validates `/api/health` and `/`, then builds the Docker image without pushing. If any of these steps fail, the workflow fails and nothing gets published.

**`build-and-push`** only runs on pushes to main. It depends on `verify` passing. It logs into GHCR using `GITHUB_TOKEN`, generates two tags using `docker/metadata-action` (`latest` for the update channel and `commit-<sha>` for an immutable rollback reference), then builds and pushes the image to GHCR.

Both jobs use Buildx with GitHub Actions cache scoped to `portfolio-app`, so layer reuse is shared across runs and across the two jobs.

The workflow uses concurrency groups with `cancel-in-progress: true`. If multiple commits land on main in quick succession, only the latest one builds — older builds are cancelled mid-run. This avoids race conditions where an older build could publish after a newer one.

Permissions are scoped per job. `verify` only needs `contents: read`. `build-and-push` needs `contents: read` and `packages: write`. Each job gets the minimum it needs and nothing more.

---

## CD Side (Server)
The deployment side lives in this repository as `scripts/update-portfolio.sh`, scheduled to run every 30 minutes.

The script:

1. Runs `docker compose pull` for the portfolio service to fetch the current `latest` image from GHCR.
2. Compares the freshly-pulled image ID against the image ID of the currently running container.
3. If they differ, runs `docker compose up -d portfolio-app` to recreate the container with the new image.
4. If they match, exits without disturbing the running container.
5. Logs all output to `/home/pratikserver/scripts/update-portfolio.log`.

This means every code change to the portfolio app reaches production within at most 30 minutes after CI publishes the image, with no manual intervention.

---

## Why Pull-Based Instead of Push-Based?

This is the architectural decision that shapes the whole pipeline. The full reasoning is in [decisions.md](decisions.md#why-pull-based-deployment), but the short version is: the server has no inbound access from CI, the blast radius of a compromised CI pipeline is bounded to "publishes a bad image" rather than "executes harmful commands," and the server controls its own update cadence by controlling the cron schedule.

---

## What Is Not Covered Here

The Dockerfile contents, the GitHub Actions workflow YAML, application source code, and build dependencies all live in the application repository. See portfolio-application-repository's README for build details. This document only covers how the published image gets pulled and run on the server.
