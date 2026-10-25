#!/usr/bin/env bash
# Recharge le lexicon (utile apres mise a jour de .lexicon-version).
# Usage: ./docker/prod/scripts/lexicon-reload.sh
set -e

COMPOSE_FILE="$(cd "$(dirname "$0")/.." && pwd)/docker-compose.yml"

docker compose -f "$COMPOSE_FILE" exec app bundle exec rake lexicon:load
