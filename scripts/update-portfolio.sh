#!/usr/bin/env bash
set -euo pipefail

SERVICE_DIR="/home/pratikserver/docker/portfolio"
SERVICE_NAME="portfolio-app"
IMAGE_REF="ghcr.io/pratikbhattarai76/portfolio-app:latest"
LOG_FILE="/home/pratikserver/scripts/update-portfolio.log"

{
  echo "========== $(date) =========="
  cd "$SERVICE_DIR"

  echo "Pulling latest image..."
  docker compose pull "$SERVICE_NAME"

  TARGET_IMAGE_ID="$(docker image inspect "$IMAGE_REF" --format '{{.Id}}' 2>/dev/null || true)"
  RUNNING_IMAGE_ID="$(docker inspect "$SERVICE_NAME" --format '{{.Image}}' 2>/dev/null || true)"

  echo "Target image ID: ${TARGET_IMAGE_ID:-none}"
  echo "Running container image ID: ${RUNNING_IMAGE_ID:-none}"

  if [ -z "${TARGET_IMAGE_ID:-}" ]; then
    echo "Target image not found locally after pull."
  elif [ "${RUNNING_IMAGE_ID:-}" != "${TARGET_IMAGE_ID:-}" ]; then
    echo "Running container is outdated. Recreating $SERVICE_NAME..."
    docker compose up -d "$SERVICE_NAME"
  else
    echo "Container already running latest image."
    echo "Skipping recreate."
  fi

  echo "Current container status:"
  docker compose ps
  echo
} >> "$LOG_FILE" 2>&1
