# docker/nanoclaw/Dockerfile
#
# Image NanoClaw-Ekylibre : NanoClaw v2 upstream + skill Telegram + init headless.
# Publiee sur ghcr.io/ekylibre/nanoclaw-ekylibre.
#
# Spec : claudedocs/workflow_nanoclaw_telegram_prod.md §3.
#
# Build (depuis la racine du repo) :
#   docker build -f docker/nanoclaw/Dockerfile --build-arg NANOCLAW_SHA=<sha> -t ghcr.io/ekylibre/nanoclaw-ekylibre:latest .
#   or docker build -f docker/nanoclaw/Dockerfile -t ghcr.io/ekylibre/nanoclaw-ekylibre:latest .

# NanoClaw upstream branch + SHA.
# IMPORTANT : on build depuis la branche `channels`, PAS depuis main.
# La branche `channels` est la branche d'integration officielle des chat adapters
# (telegram, signal, discord, ...) et embarque @chat-adapter/telegram dans
# son package.json + les helpers fileres (telegram-pairing, telegram-markdown-sanitize).
# Le main branch ne les a pas -> tsc echoue avec TS2307.
#
# Mise a jour : recuperer un SHA frais avec
#   curl -fsSL https://api.github.com/repos/nanocoai/nanoclaw/commits/channels | jq -r .sha
ARG NANOCLAW_BRANCH=channels
ARG NANOCLAW_SHA=8137440698f8972bb17948dd54e6e2bc0019b060

# === Stage 1 : build ===
FROM node:24-bookworm-slim AS builder

ARG NANOCLAW_BRANCH
ARG NANOCLAW_SHA

# python3 / make / g++ : requis pour compiler better-sqlite3 (node-gyp) car
# l'image slim n'a aucun prebuild pour node 24. Reste cantonne a la stage 1 :
# zero impact sur l'image finale.
RUN apt-get update && apt-get install -y --no-install-recommends \
      git ca-certificates curl \
      python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# Clone direct de la branche channels au SHA pinne. Telegram + @chat-adapter/telegram
# sont deja dans le package.json, pas besoin de patcher.
WORKDIR /build
RUN git clone -b ${NANOCLAW_BRANCH} https://github.com/nanocoai/nanoclaw.git . \
    && git checkout ${NANOCLAW_SHA}

# Workaround branche channels @8137440 : 3 erreurs tsc qui ne nous concernent pas
# au runtime mais bloquent le build.
#   1. src/channels/deltachat.ts importe `@deltachat/stdio-rpc-server` non declare
#      dans package.json. Pas dans index.ts (commente upstream). On le supprime.
#   2. src/channels/slack.ts utilise resolveChannelName (idem). Pas dans index.ts.
#      On le supprime.
#   3. src/channels/telegram.ts utilise resolveChannelName mais le type
#      ChannelAdapter ne le declare pas. On l'ajoute en optionnel sur l'interface.
# A retirer des que la branche channels est verte upstream.
RUN rm src/channels/deltachat.ts src/channels/slack.ts \
    && sed -i 's#^  openDM?(userHandle: string): Promise<string>;$#&\n  resolveChannelName?: (platformId: string) => Promise<string | null>;#' \
           src/channels/adapter.ts \
    && grep -q 'resolveChannelName?: ' src/channels/adapter.ts \
       || (echo "FATAL: patch resolveChannelName failed -- adapter.ts upstream a change" >&2; exit 1)

# Patch container/Dockerfile (image agent) : pnpm v10+ met le bin global dans
# $PNPM_HOME/bin, alors qu'upstream pose PATH=$PNPM_HOME:$PATH (sans /bin).
# Consequence : `pnpm install -g vercel` exit 1 avec "global bin directory
# /pnpm/bin is not in PATH". A retirer quand upstream corrigera.
RUN grep -q 'ENV PATH="\$PNPM_HOME:\$PATH"' container/Dockerfile \
    && sed -i 's#^ENV PATH="\$PNPM_HOME:\$PATH"$#ENV PATH="$PNPM_HOME/bin:$PATH"#' \
              container/Dockerfile \
    && grep -q 'ENV PATH="\$PNPM_HOME/bin:\$PATH"' container/Dockerfile \
       || (echo "FATAL: patch container/Dockerfile PNPM_HOME a echoue" >&2; exit 1)

RUN corepack enable && corepack prepare pnpm@10.33.0 --activate \
    && pnpm install --frozen-lockfile \
    && pnpm build

# === Stage 2 : runtime ===
FROM node:24-bookworm-slim

# pnpm via corepack -- requis au runtime pour `pnpm start` dans init.sh.
# Pinne sur la meme version que la stage 1 pour eviter les surprises.
# Le download corepack a lieu pendant le build, pas au boot du container.
RUN corepack enable && corepack prepare pnpm@10.33.0 --activate

# Outils runtime necessaires :
# - docker-cli : NanoClaw spawn ses containers Bun via le socket monte
# - tini       : init PID 1 propre pour la propagation des signaux
# - yq         : parsing YAML du fichier tenants.yml dans init.sh / nanoclaw CLI
# - jq         : parsing JSON pour healthcheck et CLI
# - curl       : healthcheck HTTP local + signal_host() de la CLI
# - sqlite3    : poll de readiness de v2.db dans init.sh avant init-first-agent
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates docker.io tini jq curl sqlite3 \
    && curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build /app

# Bin helpers Ekylibre (init.sh, healthcheck.sh, nanoclaw CLI)
COPY docker/nanoclaw/init.sh /usr/local/bin/init.sh
COPY docker/nanoclaw/healthcheck.sh /usr/local/bin/healthcheck.sh
COPY docker/nanoclaw/nanoclaw-cli.sh /usr/local/bin/nanoclaw
COPY docker/nanoclaw/group-template/ /app/group-template/
RUN chmod +x /usr/local/bin/init.sh /usr/local/bin/healthcheck.sh /usr/local/bin/nanoclaw

# /data persiste : inbound.db, outbound.db, groups/<tenant>/state/, memory/
VOLUME ["/data"]

EXPOSE 9100
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/init.sh"]
