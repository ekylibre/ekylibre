#!/usr/bin/env bash
# Supprime un tenant en production. IRREVERSIBLE.
# Usage: ./docker/prod/scripts/tenant-drop.sh <tenant_name>
set -e

TENANT="${1:?Usage: tenant-drop.sh <tenant_name>}"

read -p "Supprimer DEFINITIVEMENT le tenant '$TENANT' ? Tapez le nom pour confirmer : " CONFIRM
if [ "$CONFIRM" != "$TENANT" ]; then
  echo "Annule."
  exit 1
fi

COMPOSE_FILE="$(cd "$(dirname "$0")/.." && pwd)/docker-compose.yml"

docker compose -f "$COMPOSE_FILE" exec \
  -e TENANT="$TENANT" \
  app bundle exec rake tenant:drop

echo "Tenant '$TENANT' supprime."
