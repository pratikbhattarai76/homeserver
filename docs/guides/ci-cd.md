# CI/CD Pipeline

The pipeline is defined in `.github/workflows/docker.yml` and has three jobs: `verify`, `build-and-push`, and `update-deployment`.

## verify
Runs on every pull request and every push to main. Steps:

1. Checkout the code.
2. Set up Node.js (pinned to the same version as the Dockerfile).
3. `npm ci` to install dependencies, with the npm cache restored from previous runs.
4. `npm run ci:verify`, which runs three things in sequence:
   - `npm run check` — Astro/TypeScript type checking.
   - `npm run build` — production build.
   - `npm run smoke` — boot the built server and validate it actually responds.
5. Build the Docker image (without pushing) to confirm the build itself works.

If any step fails, the workflow fails and nothing reaches the next job.

## build-and-push
Only runs on pushes to main, and only after `verify` has passed. Steps:

1. Checkout, set up Buildx.
2. Log into GHCR using the ephemeral `GITHUB_TOKEN`.
3. Generate tags via `docker/metadata-action`: `latest` (only on main) and `commit-<short-sha>` for every build.
4. Build and push the image with both tags applied. Buildx cache is shared with the verify job via GitHub Actions cache.

The image is published as `ghcr.io/pratikbhattarai76/portfolio-app`.

## update-deployment
Only runs on pushes to main, after `build-and-push` has passed. Steps:

1. Checkout the [k8s-homelab-platform](https://github.com/pratikbhattarai76/k8s-homelab-platform) repo using a PAT stored as `PORTFOLIO_K8S_SERVER_DEPLOYMENT`.
2. Use `sed` to replace the image tag in `manifests/apps/portfolio/deployment.yml` with `commit-<short-sha>`.
3. Commit and push the change.

Argo CD watches the homelab repo and auto-syncs when it detects the manifest change — pulling the new image and restarting the pod.

## Concurrency Control
The workflow uses a concurrency group keyed on the branch with `cancel-in-progress: true`. If multiple commits land on main in quick succession, only the latest one finishes building — older builds are cancelled mid-run. This prevents race conditions where an older build could overwrite a newer one in the registry.

## Permissions
Each job has its own scoped permissions block. `verify` only gets `contents: read`. `build-and-push` gets `contents: read` and `packages: write`. `update-deployment` uses a PAT for cross-repo access. Each job receives the minimum it needs and nothing more.

## Previous Deployment Model
Before migrating to Kubernetes, the deployment side was pull-based: a bash script on the server ran every 30 minutes via cron, pulled the `latest` tag from GHCR, compared image IDs, and recreated the container if a new image was detected. That approach is documented in the [private-cloud-infrastructure](https://github.com/pratikbhattarai76/private-cloud-infrastructure) repository.
