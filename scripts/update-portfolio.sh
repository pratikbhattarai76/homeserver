#!/usr/bin/env bash
set -euo pipefail

SERVICE_DIR="/home/pratikserver/docker/portfolio"
SERVICE_NAME="portfolio-app"
LOG_FILE="/home/pratikserver/scripts/update-portfolio.log"

{
  echo "========== $(date) =========="
  cd "$SERVICE_DIR"

  OLD_IMAGE_ID="$(docker compose images -q "$SERVICE_NAME" || true)"
  echo "Old image ID: ${OLD_IMAGE_ID:-none}"

  echo "Pulling latest image..."
  docker compose pull "$SERVICE_NAME"

  NEW_IMAGE_ID="$(docker compose images -q "$SERVICE_NAME" || true)"
  echo "New image ID: ${NEW_IMAGE_ID:-none}"

  if [ "${OLD_IMAGE_ID:-}" != "${NEW_IMAGE_ID:-}" ]; then
    echo "Image changed. Recreating $SERVICE_NAME..."
  else
    echo "Same Image: Image Unchanged."
  fi

  docker compose up -d "$SERVICE_NAME"

  echo "Current container status: "
  docker compose ps

  echo
} >> "$LOG_FILE" 2>&1



