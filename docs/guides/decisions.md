# Design Decisions

## Why Docker
Containerizing the app means it runs the same on my laptop, in CI, and on the server. No "works on my machine" surprises. The image becomes the unit of deployment instead of source code plus a deploy script.

## Why a Multi-Stage Build
The Dockerfile has three stages: `deps`, `builder`, `runner`. Only the runner stage ends up in the final image. This means the published image contains the compiled `dist/` folder and production-only `node_modules`, but no source code, no dev dependencies, no build tools, and no TypeScript. Smaller image, smaller attack surface, faster pulls on the server.

## Why Astro SSR Instead of Static
The app has a contact form that sends email through Nodemailer. That requires a real Node.js server, not just static HTML. Astro's SSR mode gives me static-quality performance for the pages that don't need a server, plus real API routes for the ones that do.

## Why GHCR Over Docker Hub
GHCR is integrated with the same GitHub account that holds the source code, uses the same authentication via the ephemeral `GITHUB_TOKEN`, and the published package automatically links back to the repository thanks to the OCI source label in the Dockerfile. No separate account, no separate credentials, no rate limits to worry about for a personal project.

## Why GitOps Deployment
The CI pipeline updates the image tag in the Kubernetes manifest and pushes to the infrastructure repo. Argo CD detects the change and deploys. This gives a full audit trail (every deployment is a Git commit), easy rollbacks (revert the commit), and separation of concerns (CI builds and publishes, GitOps deploys).

Previously, the deployment was pull-based: a cron script on the server checked GHCR for new images every 30 minutes. That approach avoided giving CI any server access, but introduced up to 30 minutes of deployment delay and required maintaining a bash script. The GitOps approach deploys within minutes and is managed declaratively through Argo CD.

## Why `:latest` Plus Commit-SHA Tags
Every published image gets two tags: `latest` (for compatibility and quick manual pulls) and `commit-<short-sha>` (the immutable reference used in Kubernetes manifests). The Kubernetes deployment always pins to the exact commit SHA tag, so every deployment is traceable to a specific commit.

## Why a Non-Root Container User
The Dockerfile ends with `USER node`, switching from the default root user to the unprivileged `node` user that the official Node images ship with. If a vulnerability in the app or a dependency were ever exploited, the attacker would land as a non-root user with no ability to write outside the working directory.

## Why a Built-In Healthcheck
The Dockerfile includes a `HEALTHCHECK` instruction that uses Node's built-in `http` module to GET `/api/health`. Node is used instead of `curl` because the slim base image does not ship `curl` or `wget`, and pulling them in would add weight for no real gain. Using the runtime that is already in the image is the cleaner answer.

## Why a Smoke Test in CI
The CI workflow runs a smoke test that boots the actual built server, polls `/api/health` until it responds, hits the home page to verify expected markup is present, and then shuts the server down. This catches a class of bugs that type checking and unit tests would miss — broken builds, runtime errors on startup, missing assets — before any image is published.

## Why Separate Application and Infrastructure Repos
The application code (this repo) and the Kubernetes manifests ([k8s-homelab-platform](https://github.com/pratikbhattarai76/k8s-homelab-platform)) live in separate repositories. This mirrors real-world practice where platform teams own infrastructure config and application teams own application code. It also means CI in the app repo only needs to build and publish — it doesn't need kubectl access or cluster credentials.
