#!/usr/bin/env bash
# docker/nanoclaw/init.sh
#
# Init headless de NanoClaw pour integration Ekylibre.
# Lu a chaque demarrage du container nanoclaw. Idempotent.
#
# Etapes :
#   1. Validation env requises
#   2. Generation .env hote depuis variables d'env
#   3. Generation groups/<tenant>/ depuis /etc/nanoclaw/tenants.yml
#   4. Demarrage du host NanoClaw (pnpm start)
#
# Spec : claudedocs/workflow_nanoclaw_telegram_prod.md §3.2.
set -euo pipefail

log()  { echo "[$(date -Is)] init.sh: $*"; }
fail() { log "FATAL: $*"; exit 1; }

# === 1. Validation env ===
: "${ANTHROPIC_AUTH_TOKEN:?ANTHROPIC_AUTH_TOKEN obligatoire}"
: "${DUKE_WS_URL:?DUKE_WS_URL obligatoire (ex: ws://duke-api:8000/ws)}"
: "${EKYLIBRE_API_BASE_URL:?EKYLIBRE_API_BASE_URL obligatoire (ex: http://app:3000)}"
: "${NANOCLAW_AGENTS_NETWORK:=ekylibre}"

TENANTS_FILE="${NANOCLAW_TENANTS_FILE:-/etc/nanoclaw/tenants.yml}"
[[ -r "$TENANTS_FILE" ]] || fail "$TENANTS_FILE introuvable ou illisible"

# === 2. .env hote ===
cat > /app/.env <<EOF
# Genere par init.sh -- ne pas editer manuellement, recree a chaque restart
ANTHROPIC_AUTH_TOKEN=${ANTHROPIC_AUTH_TOKEN}
ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-}
NANOCLAW_DATA_DIR=/data
NANOCLAW_AGENTS_NETWORK=${NANOCLAW_AGENTS_NETWORK}
NANOCLAW_LOG_LEVEL=${NANOCLAW_LOG_LEVEL:-info}
NANOCLAW_HEALTHCHECK_PORT=9100
EOF
chmod 0600 /app/.env

# === 3. Provisioning groupes par tenant ===
mkdir -p /data/groups
TENANT_COUNT=$(yq '.tenants | length' "$TENANTS_FILE")
log "Provisioning $TENANT_COUNT tenant(s) depuis $TENANTS_FILE"

for i in $(seq 0 $((TENANT_COUNT - 1))); do
  TENANT_ID=$(yq ".tenants[$i].id" "$TENANTS_FILE")
  EKY_EMAIL=$(yq ".tenants[$i].ekylibre.email" "$TENANTS_FILE")
  EKY_TOKEN=$(yq ".tenants[$i].ekylibre.token" "$TENANTS_FILE")
  TG_BOT_TOKEN=$(yq ".tenants[$i].telegram.bot_token" "$TENANTS_FILE")
  TG_BOT_USERNAME=$(yq ".tenants[$i].telegram.bot_username" "$TENANTS_FILE")
  TG_AUTHORIZED_CHATS=$(yq -o=json -I=0 ".tenants[$i].telegram.authorized_chat_ids // []" "$TENANTS_FILE")
  LLM_PROVIDER=$(yq ".tenants[$i].llm_provider // \"claude\"" "$TENANTS_FILE")
  LOCALE=$(yq ".tenants[$i].locale // \"fra\"" "$TENANTS_FILE")

  [[ "$TENANT_ID" == "null" ]] && fail "tenants[$i].id manquant"
  [[ "$EKY_TOKEN" == "null" ]] && fail "tenants[$i].ekylibre.token manquant"
  [[ "$TG_BOT_TOKEN" == "null" ]] && fail "tenants[$i].telegram.bot_token manquant"

  GROUP_DIR="/data/groups/$TENANT_ID"
  mkdir -p "$GROUP_DIR/state" "$GROUP_DIR/memory"

  # CLAUDE.md (system prompt) -- depuis le template + variables tenant
  sed -e "s|{{TENANT_ID}}|$TENANT_ID|g" \
      -e "s|{{LOCALE}}|$LOCALE|g" \
      /app/group-template/CLAUDE.md > "$GROUP_DIR/CLAUDE.md"

  # .env du groupe (visible uniquement par le container Bun de ce tenant)
  cat > "$GROUP_DIR/.env" <<EOF
EKY_EMAIL=$EKY_EMAIL
EKY_TOKEN=$EKY_TOKEN
EKY_TENANT=$TENANT_ID
DUKE_WS_URL=$DUKE_WS_URL
DUKE_HTTP_URL=${DUKE_HTTP_URL:-${DUKE_WS_URL/ws:/http:}}
EKYLIBRE_API_BASE_URL=$EKYLIBRE_API_BASE_URL
TELEGRAM_BOT_TOKEN=$TG_BOT_TOKEN
TELEGRAM_BOT_USERNAME=$TG_BOT_USERNAME
TELEGRAM_AUTHORIZED_CHAT_IDS=$TG_AUTHORIZED_CHATS
DUKE_LLM_PROVIDER=$LLM_PROVIDER
LOCALE=$LOCALE
EOF
  chmod 0600 "$GROUP_DIR/.env"

  # Outils tenant : copie du template (duke-chat, eky-confirm, render-draft)
  cp -rn /app/group-template/tools "$GROUP_DIR/" 2>/dev/null || true

  log "  v tenant $TENANT_ID pret"
done

# === 4. Boot ===
log "Demarrage du host NanoClaw"
cd /app
exec pnpm start
