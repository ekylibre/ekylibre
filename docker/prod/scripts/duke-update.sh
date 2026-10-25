#!/usr/bin/env bash
# Met a jour Duke vers la derniere version de l'image (selon DUKE_IMAGE_TAG).
# Usage: ./docker/prod/scripts/duke-update.sh
set -e

COMPOSE_FILE="$(cd "$(dirname "$0")/.." && pwd)/docker-compose.yml"

docker compose -f "$COMPOSE_FILE" --profile duke pull duke-api
docker compose -f "$COMPOSE_FILE" --profile duke up -d --force-recreate duke-api

echo "Duke mis a jour."
