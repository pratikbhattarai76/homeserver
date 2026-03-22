#!/usr/bin/env bash
set -euo pipefail

SERVICE_DIR="/home/pratikserver/docker/portfolio"
IMAGE_REF="ghcr.io/pratikbhattarai76/portfolio-app:latest"
SERVICE_NAME="portfolio-app"
LOG_FILE="/home/pratikserver/scripts/update-portfolio.log"

{
  echo "========== $(date) =========="
  cd "$SERVICE_DIR"

  OLD_IMAGE_ID="$(docker image inspect "$IMAGE_REF" --format '{{.Id}}' 2>/dev/null || true)"
  echo "Old image ID: ${OLD_IMAGE_ID:-none}"

  echo "Pulling latest image..."
  docker compose pull "$SERVICE_NAME"

  NEW_IMAGE_ID="$(docker image inspect "$IMAGE_REF" --format '{{.Id}}' 2>/dev/null || true)"
  echo "New image ID: ${NEW_IMAGE_ID:-none}"

  if [ "${OLD_IMAGE_ID:-}" != "${NEW_IMAGE_ID:-}" ]; then
    echo "Image changed. Recreating $SERVICE_NAME..."
    docker compose up -d "$SERVICE_NAME"
  else
    echo "Same Image: Image Unchanged."
    echo "Skipping recreate."
  fi

  echo "Current container status:"
  docker compose ps
  echo
} >> "$LOG_FILE" 2>&1
