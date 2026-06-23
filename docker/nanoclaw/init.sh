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
ONECLI_API_KEY=${ONECLI_API_KEY:-}
ONECLI_URL=${ONECLI_URL:-https://app.onecli.sh}
NANOCLAW_DATA_DIR=/data
NANOCLAW_AGENTS_NETWORK=${NANOCLAW_AGENTS_NETWORK}
NANOCLAW_LOG_LEVEL=${NANOCLAW_LOG_LEVEL:-info}
NANOCLAW_HEALTHCHECK_PORT=9100
EOF
chmod 0600 /app/.env

# Warn precoce si ONECLI_API_KEY est vide : les containers agent vont se
# spawner mais sans credentials Claude et exit 125.
if [[ -z "${ONECLI_API_KEY:-}" ]]; then
  log "WARN: ONECLI_API_KEY vide -- les containers agent vont echouer."
  log "WARN: Obtenir une cle sur https://app.onecli.sh puis l'ajouter au .env du compose."
fi

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

# === 4. Channel credentials au host .env ===
#
# Limitation V1 : NanoClaw v2 lit les credentials de canal (TELEGRAM_BOT_TOKEN, ...)
# via readEnvFile(['KEY']) dans /app/.env (host level). Pas dans process.env, pas
# dans groups/<id>/.env. Donc UN host = UN bot Telegram, point.
#
# Pour la V1 mono-tenant, on propage le bot_token du premier tenant declare au
# host .env. Si plusieurs tenants partagent ce host, seul le premier sera servi
# par le bot configure -- on log un WARN explicite.
#
# Architecture cible V1.5 (a trancher) :
#   - soit 1 container nanoclaw par tenant (spec §2.2 inverse)
#   - soit 1 bot central + routage par chat_id via le mecanisme groups/ upstream
FIRST_TENANT_ID=$(yq '.tenants[0].id' "$TENANTS_FILE")
FIRST_TG_TOKEN=$(yq '.tenants[0].telegram.bot_token' "$TENANTS_FILE")
if [[ "$FIRST_TG_TOKEN" != "null" && -n "$FIRST_TG_TOKEN" ]]; then
  printf 'TELEGRAM_BOT_TOKEN=%s\n' "$FIRST_TG_TOKEN" >> /app/.env
  log "TELEGRAM_BOT_TOKEN propage au host .env (depuis tenant '$FIRST_TENANT_ID')"
fi
if [[ "$TENANT_COUNT" -gt 1 ]]; then
  log "WARN: $TENANT_COUNT tenants declares, mais NanoClaw v2 = 1 bot par host."
  log "WARN: Seul le bot du tenant '$FIRST_TENANT_ID' (premier dans tenants.yml) sera actif."
fi

# === 4.5 Build de l'image agent (idempotent, premier boot seulement) ===
#
# NanoClaw spawn un container Docker par session active. L'image attendue est
# `nanoclaw-agent-v2-<sha1(cwd)[:8]>:latest`, buildee par container/build.sh
# upstream. Comme on utilise le docker.sock du host, l'image est buildee sur
# le daemon host et persiste tant que le host n'est pas wipe.
#
# Calcul du slug : equivalent bash de src/install-slug.ts upstream.
INSTALL_SLUG=$(printf %s /app | sha1sum | cut -c1-8)
AGENT_IMAGE="nanoclaw-agent-v2-${INSTALL_SLUG}:latest"
if docker image inspect "$AGENT_IMAGE" >/dev/null 2>&1; then
  log "Agent image deja presente: $AGENT_IMAGE"
else
  log "Build de l'agent image $AGENT_IMAGE (premier boot, peut prendre 5 min)..."
  if (cd /app/container && bash build.sh) 2>&1 | sed 's/^/    /'; then
    log "Agent image buildee: $AGENT_IMAGE"
  else
    log "WARN: build agent image a echoue -- les spawn vont exit 125. Verifier docker.sock."
  fi
fi

# === 5. Boot NanoClaw en background + init du premier agent_group ===
#
# Limitation V1 supplementaire : creer groups/<id>/ sur disque ne suffit pas pour
# que NanoClaw v2 route un inbound. Il faut une row dans la table agent_groups
# de la SQLite centrale (/app/data/v2.db), creee par scripts/init-first-agent.ts
# (cf. .claude/skills/init-first-agent/SKILL.md upstream).
#
# Strategie :
#   1. Demarrer pnpm start en background -- nanoclaw applique ses migrations,
#      cree v2.db et la table agent_groups.
#   2. Attendre que la table soit prete (poll sqlite3, max 90 s).
#   3. Appeler scripts/init-first-agent.ts pour wirer le tenant 0. Le script est
#      idempotent (upsert users / reuse agent_group / reuse messaging_group).
#   4. Overlay notre template Ekylibre CLAUDE.local.md sur le dossier cree par
#      initGroupFilesystem (la migration v2 utilise .local.md, pas CLAUDE.md).
#   5. wait sur le PID nanoclaw (PID 1 = init.sh, tini propage les signaux).
#
# A retirer quand on aura l'architecture cible (1 container/tenant ou routage
# multi-farm via chat_id).

log "Demarrage du host NanoClaw (background)"
cd /app
pnpm start &
NANOCLAW_PID=$!

# Attente que les migrations v2 aient cree la table agent_groups.
log "Wait NanoClaw DB ready..."
DB_READY=0
for attempt in $(seq 1 90); do
  if [[ -f /app/data/v2.db ]] \
     && sqlite3 /app/data/v2.db \
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='agent_groups'" \
        2>/dev/null | grep -q 1; then
    log "NanoClaw DB ready (attempt $attempt/90)"
    DB_READY=1
    break
  fi
  sleep 1
done

if [[ "$DB_READY" -eq 0 ]]; then
  log "WARN: NanoClaw DB jamais prete apres 90 s -- on passe en foreground sans init agent"
else
  FIRST_USER_ID=$(yq '.tenants[0].telegram.authorized_chat_ids[0] // "null"' "$TENANTS_FILE")
  if [[ "$FIRST_USER_ID" == "null" ]]; then
    log "WARN: tenants[0].telegram.authorized_chat_ids vide -- agent non initialise"
  else
    log "Init premiere agent_group: telegram:$FIRST_USER_ID pour tenant '$FIRST_TENANT_ID'"
    npx tsx scripts/init-first-agent.ts \
      --channel telegram \
      --user-id "telegram:$FIRST_USER_ID" \
      --platform-id "telegram:$FIRST_USER_ID" \
      --display-name "$FIRST_TENANT_ID" \
      --agent-name "Ekylibre Assistant" \
      2>&1 | sed 's/^/    /' \
      || log "WARN: init-first-agent.ts exit non-zero (probablement deja init -- OK)"

    # Overlay du CLAUDE.local.md Ekylibre sur le folder cree par initGroupFilesystem.
    # Le naming upstream est `dm-with-<display-name>` (avec normalisation eventuelle).
    NEW_GROUP_DIR=$(ls -td /app/groups/dm-with-${FIRST_TENANT_ID}* 2>/dev/null | head -n1 || true)
    if [[ -n "$NEW_GROUP_DIR" && -d "$NEW_GROUP_DIR" && -f /app/group-template/CLAUDE.md ]]; then
      sed -e "s|{{TENANT_ID}}|$FIRST_TENANT_ID|g" \
          -e "s|{{LOCALE}}|fra|g" \
          /app/group-template/CLAUDE.md > "$NEW_GROUP_DIR/CLAUDE.local.md"
      log "CLAUDE.local.md Ekylibre installe dans $NEW_GROUP_DIR"
    else
      log "WARN: dossier groups/dm-with-${FIRST_TENANT_ID}* introuvable apres init -- CLAUDE.local.md non installe"
    fi
  fi
fi

# Foreground sur nanoclaw -- tini (PID 1 via ENTRYPOINT) propage SIGTERM/SIGINT.
log "NanoClaw foreground (PID $NANOCLAW_PID)"
wait $NANOCLAW_PID
