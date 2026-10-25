#!/usr/bin/env bash
# docker/nanoclaw/healthcheck.sh
#
# Health = le host NanoClaw repond + au moins 1 container agent tourne.
# Spec : claudedocs/workflow_nanoclaw_telegram_prod.md §3.3.
set -euo pipefail

curl -fsS "http://localhost:${NANOCLAW_HEALTHCHECK_PORT:-9100}/health" >/dev/null

RUNNING=$(docker ps --filter "label=nanoclaw.role=agent" --filter "status=running" -q | wc -l)
[[ "$RUNNING" -ge 1 ]]
