#!/usr/bin/env bash
# Lance Duke (assistant chatbot) en plus du stack Ekylibre.
# Usage:
#   ./docker/prod/scripts/duke-up.sh                 # Duke seul (LLM cloud : Claude/Mistral)
#   ./docker/prod/scripts/duke-up.sh --with-local-llm # + Ollama local
set -e

COMPOSE_FILE="$(cd "$(dirname "$0")/.." && pwd)/docker-compose.yml"

PROFILES=(--profile duke)
if [ "${1:-}" = "--with-local-llm" ]; then
  PROFILES+=(--profile duke-llm-local)
fi

# Verifie que .env contient les vars Duke minimales
ENV_FILE="$(cd "$(dirname "$0")/.." && pwd)/.env"
for var in DUKE_USER DUKE_PASSWORD DUKE_DB_USER DUKE_DB_PASSWORD HASH_SECRET; do
  if ! grep -qE "^${var}=.+$" "$ENV_FILE" 2>/dev/null; then
    echo "ERROR: $var n'est pas defini dans $ENV_FILE"
    echo "Voir docker/prod/.env.dist pour la liste complete."
    exit 1
  fi
done

echo "==PULL DUKE IMAGES=="
docker compose -f "$COMPOSE_FILE" "${PROFILES[@]}" pull

echo "==START DUKE=="
docker compose -f "$COMPOSE_FILE" "${PROFILES[@]}" up -d

echo
echo "Duke demarre. Accessible sur : https://duke.${HOST_DOMAIN_NAME:-<HOST_DOMAIN_NAME>}/healthz"
