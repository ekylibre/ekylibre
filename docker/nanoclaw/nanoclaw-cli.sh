#!/usr/bin/env bash
# docker/nanoclaw/nanoclaw-cli.sh -- installe en /usr/local/bin/nanoclaw.
#
# Helper operateur execute DANS le container nanoclaw :
#   docker compose exec nanoclaw nanoclaw <command>
#
# Lit /etc/nanoclaw/tenants.yml, gere /data/groups/<id>/ sur le volume persistant,
# et supervise les containers Bun labellises `nanoclaw.role=agent`.
#
# Commandes :
#   reload          re-provisionne tous les tenants, purge les retires, signale le host
#   enroll <id>     provisionne un seul tenant (pas de reload global)
#   revoke <id>     stoppe + purge le container Bun du tenant + son groups/<id>/
#   status          liste les tenants et l'etat de leurs containers Bun
#   logs <id> [-f]  tail des logs du container Bun du tenant
#
# Hypotheses sur le contrat upstream NanoClaw :
#   - Les containers Bun sont labellises avec :
#       * nanoclaw.role=agent
#       * nanoclaw.tenant=<id>
#   - Le host expose au moins l'endpoint http://localhost:$HEALTH_PORT/health.
#   - Le host pioche les changements de /data/groups/ a chaud :
#       * via POST /reload si l'endpoint existe, sinon
#       * via SIGHUP a PID 1 (le process pnpm start), sinon
#       * fallback : l'operateur doit restart le service nanoclaw.
#
# Spec : claudedocs/workflow_nanoclaw_telegram_prod.md §3.4 + §6.

set -euo pipefail

TENANTS_FILE="${NANOCLAW_TENANTS_FILE:-/etc/nanoclaw/tenants.yml}"
GROUPS_DIR="${NANOCLAW_DATA_DIR:-/data}/groups"
HEALTH_PORT="${NANOCLAW_HEALTHCHECK_PORT:-9100}"

log()  { echo "[$(date -Is)] nanoclaw: $*"; }
fail() { log "ERROR: $*" >&2; exit 1; }

require_tenants_file() {
  [[ -r "$TENANTS_FILE" ]] || fail "tenants.yml unreadable: $TENANTS_FILE"
}

# Renvoie l'index yml du tenant (0..N-1) ou "null" si absent.
tenant_index() {
  local id=$1
  yq ".tenants | map(.id == \"$id\") | index(true)" "$TENANTS_FILE"
}

# Re-rend groups/<id>/CLAUDE.md + .env pour le tenant a l'index yml donne.
# Mirroir intentionnel de la boucle init.sh ; les deux doivent rester en phase.
provision_index() {
  local i=$1
  local TENANT_ID EKY_EMAIL EKY_TOKEN TG_BOT_TOKEN TG_BOT_USERNAME TG_AUTHORIZED_CHATS LLM_PROVIDER LOCALE

  TENANT_ID=$(yq ".tenants[$i].id" "$TENANTS_FILE")
  EKY_EMAIL=$(yq ".tenants[$i].ekylibre.email" "$TENANTS_FILE")
  EKY_TOKEN=$(yq ".tenants[$i].ekylibre.token" "$TENANTS_FILE")
  TG_BOT_TOKEN=$(yq ".tenants[$i].telegram.bot_token" "$TENANTS_FILE")
  TG_BOT_USERNAME=$(yq ".tenants[$i].telegram.bot_username" "$TENANTS_FILE")
  TG_AUTHORIZED_CHATS=$(yq -o=json -I=0 ".tenants[$i].telegram.authorized_chat_ids // []" "$TENANTS_FILE")
  LLM_PROVIDER=$(yq ".tenants[$i].llm_provider // \"claude\"" "$TENANTS_FILE")
  LOCALE=$(yq ".tenants[$i].locale // \"fra\"" "$TENANTS_FILE")

  [[ "$TENANT_ID" == "null" ]] && fail "tenants[$i].id manquant"
  [[ "$EKY_TOKEN" == "null" ]] && fail "tenants[$i].ekylibre.token manquant ($TENANT_ID)"
  [[ "$TG_BOT_TOKEN" == "null" ]] && fail "tenants[$i].telegram.bot_token manquant ($TENANT_ID)"

  local GROUP_DIR="$GROUPS_DIR/$TENANT_ID"
  mkdir -p "$GROUP_DIR/state" "$GROUP_DIR/memory"

  sed -e "s|{{TENANT_ID}}|$TENANT_ID|g" \
      -e "s|{{LOCALE}}|$LOCALE|g" \
      /app/group-template/CLAUDE.md > "$GROUP_DIR/CLAUDE.md"

  cat > "$GROUP_DIR/.env" <<EOF
EKY_EMAIL=$EKY_EMAIL
EKY_TOKEN=$EKY_TOKEN
EKY_TENANT=$TENANT_ID
DUKE_WS_URL=${DUKE_WS_URL:-}
DUKE_HTTP_URL=${DUKE_HTTP_URL:-${DUKE_WS_URL/ws:/http:}}
EKYLIBRE_API_BASE_URL=${EKYLIBRE_API_BASE_URL:-}
TELEGRAM_BOT_TOKEN=$TG_BOT_TOKEN
TELEGRAM_BOT_USERNAME=$TG_BOT_USERNAME
TELEGRAM_AUTHORIZED_CHAT_IDS=$TG_AUTHORIZED_CHATS
DUKE_LLM_PROVIDER=$LLM_PROVIDER
LOCALE=$LOCALE
EOF
  chmod 0600 "$GROUP_DIR/.env"

  cp -rn /app/group-template/tools "$GROUP_DIR/" 2>/dev/null || true

  printf '%s\n' "$TENANT_ID"
}

# Demande au host NanoClaw de re-scanner /data/groups/. Best-effort :
# HTTP POST puis SIGHUP. Si rien ne fonctionne, l'operateur doit restart.
signal_host() {
  if curl -fsS -X POST "http://localhost:$HEALTH_PORT/reload" -o /dev/null 2>/dev/null; then
    log "host reloaded via HTTP /reload"
    return 0
  fi
  if kill -HUP 1 2>/dev/null; then
    log "host signaled via SIGHUP (PID 1)"
    return 0
  fi
  log "WARN: could not signal host -- restart the nanoclaw container to apply changes"
  return 1
}

cmd_reload() {
  require_tenants_file
  log "reload: re-provisioning all tenants from $TENANTS_FILE"
  local total
  total=$(yq '.tenants | length' "$TENANTS_FILE")
  declare -A wanted=()
  for ((i=0; i<total; i++)); do
    local id
    id=$(provision_index "$i")
    wanted[$id]=1
    log "  v $id provisioned"
  done

  # Purge des groupes orphelins (tenant retire du yml).
  if [[ -d "$GROUPS_DIR" ]]; then
    shopt -s nullglob
    for dir in "$GROUPS_DIR"/*/; do
      local id
      id=$(basename "$dir")
      if [[ -z "${wanted[$id]:-}" ]]; then
        log "  x $id removed from yml -- stopping container + purging $dir"
        docker ps -q --filter "label=nanoclaw.tenant=$id" | xargs -r docker rm -f
        rm -rf "$dir"
      fi
    done
    shopt -u nullglob
  fi

  signal_host || true
}

cmd_enroll() {
  local id=${1:-}
  [[ -z "$id" ]] && fail "usage: nanoclaw enroll <id>"
  require_tenants_file
  local idx
  idx=$(tenant_index "$id")
  [[ "$idx" == "null" ]] && fail "tenant '$id' not found in $TENANTS_FILE"
  provision_index "$idx" >/dev/null
  log "tenant $id provisioned"
  signal_host || true
}

cmd_revoke() {
  local id=${1:-}
  [[ -z "$id" ]] && fail "usage: nanoclaw revoke <id>"
  log "revoking tenant $id"
  docker ps -q --filter "label=nanoclaw.tenant=$id" | xargs -r docker rm -f
  rm -rf "${GROUPS_DIR:?}/$id"
  log "tenant $id revoked (container removed + group dir purged)"
}

cmd_status() {
  require_tenants_file
  local total
  total=$(yq '.tenants | length' "$TENANTS_FILE")
  printf '%-30s %-10s %s\n' "TENANT" "STATUS" "CONTAINER ID"
  for ((i=0; i<total; i++)); do
    local id cid status
    id=$(yq ".tenants[$i].id" "$TENANTS_FILE")
    cid=$(docker ps -q --filter "label=nanoclaw.tenant=$id" --filter "status=running" | head -n1 || true)
    if [[ -n "${cid:-}" ]]; then
      status="running"
    else
      status="stopped"
    fi
    printf '%-30s %-10s %s\n' "$id" "$status" "${cid:-—}"
  done
}

cmd_logs() {
  local id=${1:-}
  [[ -z "$id" ]] && fail "usage: nanoclaw logs <id> [-f]"
  shift
  local cid
  cid=$(docker ps -aq --filter "label=nanoclaw.tenant=$id" | head -n1 || true)
  [[ -z "${cid:-}" ]] && fail "no container found for tenant '$id'"
  docker logs "$@" "$cid"
}

usage() {
  cat <<EOF
Usage: nanoclaw <command> [args]

Commands:
  reload          re-provision all tenants and signal the host to reload
  enroll <id>     provision a single tenant (no global reload)
  revoke <id>     stop + purge the tenant's Bun container and group dir
  status          list tenants and the state of their Bun containers
  logs <id> [-f]  tail the Bun container logs

Reads:  $TENANTS_FILE
Groups: $GROUPS_DIR/<id>/
EOF
}

cmd=${1:-}
shift || true
case "$cmd" in
  reload)  cmd_reload "$@" ;;
  enroll)  cmd_enroll "$@" ;;
  revoke)  cmd_revoke "$@" ;;
  status)  cmd_status "$@" ;;
  logs)    cmd_logs "$@" ;;
  ""|help|--help|-h) usage ;;
  *) fail "unknown command: $cmd (run 'nanoclaw help')" ;;
esac
