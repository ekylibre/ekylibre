#!/usr/bin/env bash
# Initialise un nouveau tenant en production.
# Usage: ./docker/prod/scripts/tenant-init.sh <tenant_name> <admin_email> <admin_password>
set -e

TENANT="${1:?Usage: tenant-init.sh <tenant_name> <admin_email> <admin_password>}"
EMAIL="${2:?Email required}"
PASSWORD="${3:?Password required}"

COMPOSE_FILE="$(cd "$(dirname "$0")/.." && pwd)/docker-compose.yml"

docker compose -f "$COMPOSE_FILE" exec \
  -e TENANT="$TENANT" \
  -e EMAIL="$EMAIL" \
  -e PASSWORD="$PASSWORD" \
  app bundle exec rake tenant:init

echo
echo "Tenant '$TENANT' cree. Accessible sur : https://${TENANT}.${HOST_DOMAIN_NAME:-<HOST_DOMAIN_NAME>}"
