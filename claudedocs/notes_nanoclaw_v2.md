# Notes techniques — NanoClaw v2 dans l'intégration Ekylibre

> Mémo des écarts entre [la spec](./workflow_nanoclaw_telegram_prod.md) et la réalité de NanoClaw v2 upstream, et des patches qu'on applique pour faire marcher l'intégration. À tenir à jour au fur et à mesure des découvertes.

| | |
|---|---|
| **Version repo upstream** | branche `channels` @ `8137440698f8972bb17948dd54e6e2bc0019b060` (2026-06-06) |
| **Statut spec** | v1.0 — partiellement incorrecte (architecture multi-tenant) |
| **Statut image custom** | `ghcr.io/ekylibre/nanoclaw-ekylibre:v0.1.3` — tous patches intégrés, build OK, runtime OK pour pilote mono-tenant |

---

## 1. Écarts spec ↔ upstream

La spec a été rédigée en supposant que NanoClaw v2 supportait nativement **"1 bot Telegram par tenant via le mécanisme `groups/`"**. Investigation effective :

### 1.1 Credentials de canal → centralisés, pas per-group

`src/channels/telegram.ts` (et tous les autres adapters) appelle :
```typescript
const env = readEnvFile(['TELEGRAM_BOT_TOKEN']);
```

`readEnvFile` (`src/env.ts`) lit **uniquement `/app/.env`** (le `cwd` du process nanoclaw). Il **n'utilise pas `process.env`** — choix explicite documenté upstream :
> Does NOT load anything into process.env — callers decide what to do with the values. This keeps secrets out of the process environment so they don't leak to child processes.

**Conséquence** : un host NanoClaw = **un seul** `TELEGRAM_BOT_TOKEN` actif. Le modèle "1 bot par tenant" n'est pas implémenté par upstream à ce niveau.

### 1.2 Routage multi-tenant → via le mécanisme `agent_groups` en DB, pas via `groups/` sur disque

Le mécanisme `groups/<id>/` upstream désigne en réalité des **dossiers de wiring d'agent**, pas des silos par tenant comme on l'imaginait. La SQLite centrale `/app/data/v2.db` (tables `users`, `agent_groups`, `messaging_groups`, `messaging_group_agents`, ...) est la source de vérité du routage.

Quand un message inbound arrive :
1. NanoClaw cherche un `messaging_group` par `(channel_type, platform_id)`. Si absent → auto-créé.
2. Cherche les `agent_groups` câblés à ce `messaging_group` via `messaging_group_agents`.
3. Si zéro → log `Channel registration skipped — no agent groups configured`.
4. Si ≥1 → dispatche au container Bun de cet agent_group (folder `groups/dm-with-<name>/`).

Notre `init.sh` créait `/data/groups/<tenant>/` sur disque mais **ne peuplait pas** les tables DB → le routage skipait toujours.

### 1.3 Initialisation d'agent → script TypeScript dédié, pas implicite

Upstream fournit `scripts/init-first-agent.ts` (via la skill `.claude/skills/init-first-agent/`) qui :
1. Upsert `users` row + grant `owner` role si pas d'owner
2. Crée `agent_groups` row + folder `groups/dm-with-<display_name>/` via `initGroupFilesystem`
3. Réutilise / crée la `messaging_groups` row
4. Wire le tout via `messaging_group_agents`
5. Push un welcome message via la socket CLI (`data/cli.sock`) avec fallback `inbound.db`

**Idempotent** : upsert sur users, reuse sur agent_group si folder déjà présent.

### 1.4 Template système prompt → `CLAUDE.local.md`, pas `CLAUDE.md`

La migration v2 logge :
```
INFO Migrated groups to CLAUDE.local.md model
  actions=["main/CLAUDE.md → CLAUDE.local.md", "groups/global/ removed"]
```

NanoClaw v2 lit le system prompt depuis `groups/<name>/CLAUDE.local.md` (et non `CLAUDE.md`). Notre `init.sh` écrit donc dans `CLAUDE.local.md`.

### 1.5 Persistance — v2.db dans `/app/data`, PAS dans `/data`

Malgré `NANOCLAW_DATA_DIR=/data` dans `/app/.env`, les logs montrent :
```
INFO Central DB initialized path="/app/data/v2.db"
```

Cette variable d'env semble **ignorée** par le boot upstream (au moins à ce SHA). Conséquence : v2.db et `groups/` sont **dans le filesystem éphémère du container**, pas sur le volume `nanoclaw-data` qu'on bind sur `/data`.

À chaque restart du container : v2.db wipée → re-init nécessaire. Pour le pilote actuel, mitigé par le fait qu'on **re-exécute `init-first-agent.ts` à chaque boot** dans init.sh (idempotent).

**À investiguer V1.1** : soit bind-mount `nanoclaw-data:/app/data` (au lieu de `/data`), soit retrouver le bon nom de var d'env upstream (`NANOCLAW_HOME` ? `DATA_DIR` ?), soit patcher le code source.

### 1.6 Dépendance OneCLI gateway

NanoClaw v2 **dépend de OneCLI** (https://app.onecli.sh), une SaaS gateway upstream gérée par nanocoai, pour provisionner les credentials Claude des containers agent. Référence :

- `src/container-runner.ts` ligne 10 : `import { OneCLI } from '@onecli-sh/sdk';`
- `src/config.ts` ligne 9 : `readEnvFile(['ONECLI_URL', 'ONECLI_API_KEY', ...])`
- `src/container-runner.ts` ligne 441-444 : `onecli.ensureAgent(...)` puis `onecli.applyContainerConfig(args, ...)` qui injecte des env vars dans la spec docker spawn.

Sans `ONECLI_API_KEY` valide dans `/app/.env`, le flow casse :
```
WARN OneCLI gateway error -- container will have no credentials
    OneCLIRequestError: [URL=https://app.onecli.sh/api/agents] [StatusCode=401] OneCLI returned 401 Unauthorized
INFO Spawning container ...
INFO Container exited code=125
```

`ANTHROPIC_AUTH_TOKEN` du host **n'est PAS utilisé** par les containers agent — il sert au host nanoclaw pour ses propres appels (skills internes peut-être), mais le path runtime des agents passe par OneCLI exclusivement.

**Implications opérationnelles** :
- Coût : OneCLI est un SaaS facturé (tarification à vérifier sur leur site)
- RGPD / souveraineté : credentials Claude transitent par les serveurs nanocoai (US, probablement)
- Disponibilité : panne OneCLI = panne assistant

**Bypass possible (option B initiale, non retenue V1)** : patcher `container-runner.ts` pour `--env ANTHROPIC_AUTH_TOKEN=...` directement aux containers, sans passer par OneCLI. Demande aussi de patcher l'`entrypoint.sh` de l'image agent pour utiliser ce token. Coût : 1-2 jours dev + fragilité aux updates upstream.

### 1.7 Image agent à builder localement

NanoClaw spawn un container Docker par session, image nommée `nanoclaw-agent-v2-<sha1(cwd)[:8]>:latest` (cf. `src/install-slug.ts`). Pour notre container nanoclaw, cwd = `/app` → slug = `0c35eebf` → image = `nanoclaw-agent-v2-0c35eebf:latest`.

L'image est **buildée par `container/build.sh`** upstream (Dockerfile dans `container/Dockerfile` du repo cloné). Notre `init.sh` vérifie sa présence sur le daemon Docker du host (via `docker.sock` monté) au boot et la build si absente. Idempotent.

Build initial : ~5 min, ~1 Go d'image. Persiste sur le host tant que le daemon Docker n'est pas wipé. Restart du container nanoclaw → image déjà présente → skip build.

### 1.8 ⛔ BLOQUANT — Mismatch chemins host vs container au spawn agent

**Le bug le plus profond, et il bloque le pilote V1 end-to-end.**

NanoClaw v2 est conçu pour tourner **directement sur le host** (clone du repo + `bash nanoclaw.sh`). Dans ce modèle, `process.cwd()` = path du repo = path résoluble par le daemon Docker, donc les mounts marchent.

Quand on **containerise nanoclaw** avec `docker.sock` monté, le pattern casse :

1. Inside container nanoclaw : `process.cwd()` = `/app`. `PROJECT_ROOT = /app`. `DATA_DIR = /app/data`. `GROUPS_DIR = /app/groups`. `container/agent-runner/src` est à `/app/container/agent-runner/src`.
2. NanoClaw appelle `docker run -v /app/container/agent-runner/src:/app/src ...` via le socket.
3. La requête arrive sur le daemon Docker du **host VM**. Le daemon cherche `/app/container/agent-runner/src` sur le **filesystem du host**, où ce path **n'existe pas** (il n'existe que dans le container nanoclaw).
4. Docker **auto-crée** un dossier vide à cet endroit sur le host → mount réussi mais l'agent container reçoit un `/app/src` **vide**.
5. `bun run /app/src/index.ts` → `error: Module not found "/app/src/index.ts"` → container exit 1 en ~160 ms.

**Symptômes observés** (logs nanoclaw, après que OneCLI et l'image agent fonctionnent) :
```
INFO Spawning container ... containerName="nanoclaw-v2-dm-with-demo-XXX"
INFO Container exited code=1 containerName="..."
```

**Vérification host** :
```bash
ls -la /app/container/agent-runner/src/    # vide ou inexistant
ls /app/groups/                            # créé par Docker, vide
```

**Implications** : ce même bug touche aussi v2.db et groups/ qu'on a documenté en §1.5 — la raison pour laquelle `NANOCLAW_DATA_DIR=/data` semble "ignoré", c'est que NanoClaw écrit bien dans `/app/data/v2.db` côté container, mais le daemon Docker, lui, voit cette data en dehors du volume `/data`. Les paths qui matchent côté host n'auraient pas ce bug.

**Solutions possibles** (à trancher) :

1. **Bind mount avec chemins identiques host/container** (recommandé) :
   - Dockerfile : `WORKDIR /opt/ekylibre/nanoclaw-runtime` au lieu de `/app`
   - Compose : `- /opt/ekylibre/nanoclaw-runtime:/opt/ekylibre/nanoclaw-runtime`
   - init.sh : bootstrap depuis `/backup-app` au premier boot si le path est vide
   - Bénéfices : règle aussi §1.5 (persistance v2.db automatique)
   - Coût : ~30 min de code + wipe du volume actuel + redéploiement

2. **Bind mount sur `/app`** : pareil mais avec `/app:/app`. Plus simple mais conflit potentiel sur le namespace `/app` du host.

3. **Pivot vers déploiement direct sur la VM (sans containeriser nanoclaw)** : abandonne notre image custom, suit le modèle upstream. Perd l'avantage de portabilité de notre Dockerfile.

Pour le pilote V1, **option 1 recommandée**. À implémenter calmement, pas en debugging session de minuit.

---

## 2. Patches appliqués dans l'image custom

Tous appliqués dans notre `docker/nanoclaw/Dockerfile` et `docker/nanoclaw/init.sh`. Marqueurs en clair pour pouvoir les retirer un par un quand upstream se stabilise.

### 2.1 Build — toolchain natif pour `better-sqlite3`

```dockerfile
RUN apt-get install -y python3 make g++   # stage 1 builder
```
Sans, `node-gyp rebuild` de `better-sqlite3` échoue sur `node:24-bookworm-slim` (pas de prebuild pour node 24).
À retirer quand upstream `better-sqlite3` aura des prebuilds pour node 24 (ou downgrade node).

### 2.2 Build — sourcing de la branche `channels` (pas `main`)

```dockerfile
ARG NANOCLAW_BRANCH=channels
RUN git clone -b ${NANOCLAW_BRANCH} ...
```
La branche `main` n'a pas la skill Telegram en deps. La branche `channels` est l'intégration officielle. **À retirer quand `channels` sera mergée dans `main`** ou qu'une release tag inclura Telegram (aucune dans `git tag -l` au moment du build : v2.0.x et v2.1.x sont `main` sans channels).

### 2.3 Build — TS2307/TS2339/TS2353 sur 3 fichiers `src/channels/`

```dockerfile
RUN rm src/channels/deltachat.ts src/channels/slack.ts \
    && sed -i 's#^  openDM?(userHandle: string): Promise<string>;$#&\n  resolveChannelName?: (platformId: string) => Promise<string | null>;#' \
           src/channels/adapter.ts \
    && grep -q 'resolveChannelName?: ' src/channels/adapter.ts || exit 1
```

- `deltachat.ts` importe `@deltachat/stdio-rpc-server` non déclaré dans `package.json` ; commenté hors d'`index.ts` → suppression non destructive
- `slack.ts` et `telegram.ts` utilisent `resolveChannelName` non déclaré sur l'interface `ChannelAdapter` ; on l'ajoute en optionnel
- À retirer quand `channels` upstream sera vert (PR à surveiller : `feat/resolve-channel-name`)

### 2.4 Runtime — `pnpm` via `corepack` dans la stage 2

```dockerfile
RUN corepack enable && corepack prepare pnpm@10.33.0 --activate
```
La stage 1 a pnpm (via corepack pour `pnpm install + pnpm build`), mais le `COPY --from=builder /build /app` ne propage pas le binaire pnpm. Sans cette ligne, `exec pnpm start` dans init.sh échoue avec `pnpm: not found`.
À garder même si tout est résolu upstream — c'est une dépendance runtime intrinsèque, pas un patch.

### 2.5 Runtime — propagation `TELEGRAM_BOT_TOKEN` au host `.env`

Dans `init.sh`, après la boucle de provisioning des tenants :
```bash
printf 'TELEGRAM_BOT_TOKEN=%s\n' "$FIRST_TG_TOKEN" >> /app/.env
```
Compense le fait qu'upstream n'a pas (encore) de support multi-bot via groups/. **À retirer quand la cible architecture V1.5 sera tranchée** (cf. §3).

### 2.6 Runtime — initialisation du `agent_group` au boot

Dans `init.sh`, avant le `wait $NANOCLAW_PID` :
```bash
npx tsx scripts/init-first-agent.ts \
  --channel telegram \
  --user-id "telegram:$FIRST_USER_ID" \
  --platform-id "telegram:$FIRST_USER_ID" \
  --display-name "$FIRST_TENANT_ID" \
  --agent-name "Ekylibre Assistant"
```

Pré-requis :
- Lancer `pnpm start` en background d'abord
- Attendre que la table `agent_groups` existe dans v2.db (poll sqlite3, max 90 s)
- L'idempotency est upstream (reuse si déjà créé)

**À retirer quand** v2.db sera persistant (alors `init-first-agent` n'aurait à tourner que la 1re fois — on garderait un guard d'idempotency mais ce serait un no-op). Ou quand upstream proposera une voie déclarative (config file d'agent_groups, par exemple).

### 2.7 Runtime — overlay du `CLAUDE.local.md` Ekylibre

Après `init-first-agent.ts`, dans `init.sh` :
```bash
sed -e "s|{{TENANT_ID}}|$FIRST_TENANT_ID|g" \
    -e "s|{{LOCALE}}|fra|g" \
    /app/group-template/CLAUDE.md > "$NEW_GROUP_DIR/CLAUDE.local.md"
```

Le script upstream crée un `groups/dm-with-<tenant>/` avec un système prompt **générique**. On l'écrase avec notre template Ekylibre (règles Duke, désambiguïsation, sécurité — cf. spec Annexe A).

**À conserver** : c'est notre system prompt produit ; ce n'est pas un workaround à retirer.

### 2.8 Runtime — Build de l'image agent au premier boot

Dans `init.sh`, avant `pnpm start &` :
```bash
INSTALL_SLUG=$(printf %s /app | sha1sum | cut -c1-8)
AGENT_IMAGE="nanoclaw-agent-v2-${INSTALL_SLUG}:latest"
if ! docker image inspect "$AGENT_IMAGE" >/dev/null 2>&1; then
  (cd /app/container && bash build.sh) 2>&1 | sed 's/^/    /'
fi
```

Sans ce build, le spawn des containers agent échoue en `exit 125` (image inexistante). Le build est lancé sur le daemon Docker du host via `docker.sock` monté → l'image persiste tant que le daemon n'est pas wipé. Idempotent : skip si déjà présente.

**À conserver** : étape intrinsèque à l'architecture v2 upstream (chaque session = un container).

### 2.9 Runtime — Propagation `ONECLI_API_KEY` au host `.env`

Dans `init.sh`, dans le `cat > /app/.env <<EOF` :
```bash
ONECLI_API_KEY=${ONECLI_API_KEY:-}
ONECLI_URL=${ONECLI_URL:-https://app.onecli.sh}
```

Plus un WARN précoce si `ONECLI_API_KEY` est vide.

**À retirer** : si on adopte un jour l'option B (self-hosted complet sans OneCLI, cf. §1.6). Tant que NanoClaw v2 dépend de la gateway upstream, on garde cette propagation.

### 2.10 Build — Patch `container/Dockerfile` pour PATH de pnpm v10+

Dans notre `Dockerfile` stage builder, après le clone upstream :
```bash
sed -i 's#^ENV PATH="\$PNPM_HOME:\$PATH"$#ENV PATH="$PNPM_HOME/bin:$PATH"#' container/Dockerfile
```

Upstream `container/Dockerfile` (image agent) pose `ENV PATH="$PNPM_HOME:$PATH"` (sans `/bin`). pnpm v10+ a déplacé son bin global de `$PNPM_HOME` vers `$PNPM_HOME/bin`. Sans le patch, `pnpm install -g vercel` échoue avec :
```
[ERROR] The configured global bin directory "/pnpm/bin" is not in PATH
Run "pnpm setup" to update your shell configuration.
```
→ build de l'image agent échoue → `init.sh` continue avec un WARN → spawn des containers agent exit 125 (image absente).

**À retirer** : quand upstream mettra `$PNPM_HOME/bin` dans PATH (le bon comportement pour pnpm v10+).

---

## 3. Décisions architecture V1.5 à trancher

Le modèle spec "1 bot Telegram par tenant" ne marche pas tel quel sur NanoClaw v2 upstream. Deux pistes mutually-exclusive :

### Option A — 1 container NanoClaw par tenant

Inverse la spec §2.2 : on a 1 service `nanoclaw-<tenant>` dans le compose, chacun avec son propre `.env` (`TELEGRAM_BOT_TOKEN`, `EKY_TENANT`), son propre volume, sa propre DB v2.db.

**Pros** : isolation OS-level réelle ; pas de partage de DB ; chaque tenant peut être stoppé/restart sans impact sur les autres.
**Cons** : RAM × N ; orchestration plus lourde ; perd l'avantage du host central NanoClaw.

### Option B — 1 bot Telegram central, multi-farms via routage `agent_groups`

Garder 1 container NanoClaw qui pilote 1 bot Telegram unique (`@EkylibreAssistantBot` p.ex.). Quand un user `chat_id` X envoie un message, NanoClaw consulte les `agent_groups` câblés à ce `chat_id` et route vers l'agent du tenant correspondant.

**Pros** : 1 seule infra à maintenir ; alignement avec le design v2 upstream ; coût RAM constant.
**Cons** : un utilisateur multi-fermes doit avoir N `messaging_groups` distincts ; UX moins claire (`@EkylibreAssistantBot` pour tout vs `@MyFarmerAssistantBot` brandé) ; isolation logique uniquement, pas OS-level (mais c'est le modèle upstream assume).

### Recommandation

**Option B** est l'alignement upstream et permet de monter en charge sans X-er les containers. Mais demande qu'on comprenne mieux le routage `groups/` et qu'on étende `init-first-agent.ts` (ou son équivalent) pour câbler N agents pour N tenants sur le même bot. Le pilote mono-tenant actuel ne force pas le choix — on peut décider après quelques semaines d'exploitation.

---

## 4. Liste des fichiers/scripts upstream importants

| Fichier | Rôle |
|---|---|
| `src/env.ts` | `readEnvFile([keys])` — lit `/app/.env`, jamais `process.env` |
| `src/channels/telegram.ts` | Adapter Telegram ; lit `TELEGRAM_BOT_TOKEN` ; appelle `registerChannelAdapter` |
| `src/channels/adapter.ts` | Interface `ChannelAdapter` ; **patch §2.3** y ajoute `resolveChannelName?` |
| `src/channels/index.ts` | Barrel des imports ; commentés = désactivés (slack, deltachat, etc.) |
| `src/db/` | Modules DAO pour v2.db (à explorer pour V1.5) |
| `scripts/init-first-agent.ts` | Script d'init du wiring d'agent (cf. §1.3) |
| `.claude/skills/init-first-agent/SKILL.md` | Documentation interactive de la skill (lue pendant l'investigation) |
| `groups/main/CLAUDE.md` | Template upstream du system prompt (devient `CLAUDE.local.md` après migration v2) |
| `groups/global/` | Supprimé par la migration v2 (legacy) |
| `data/v2.db` | SQLite centrale, tables users/agent_groups/messaging_groups/wiring |

---

## 5. Inconnues / à creuser

| # | Question | Pourquoi |
|---|---|---|
| 1 | ~~Quel env var redirige `data/` vers `/data` ?~~ → **Confirmé en §1.8 : pas un env var, mismatch host/container fondamental** | Bloque la persistance ET les spawns d'agents |
| 2 | ~~`groups/` est-il aussi configurable ?~~ → **Idem §1.8** | Même problème, même fix |
| 3 | Le mécanisme `/add-telegram` skill non interactive existe-t-il ? | Notre Dockerfile reproduit en gros ce que la skill fait — vérifier qu'on est complet |
| 4 | Quel est le format attendu de `agent_destinations` ? | Pour câbler 2 agent_groups vers 2 tenants sur 1 bot |
| 5 | ~~`Containers Bun` upstream — vraiment containers Docker ?~~ → **Confirmé en §1.8 : oui, des containers Docker spawnés par session** | Documenté |
| 6 | Schedule de release upstream pour `channels` → `main` | Dégeler nos patches §2.2 et §2.3 |
| 7 | **PRIORITAIRE** — Comment patcher l'architecture host/container path (§1.8) | Bloque le pilote V1 end-to-end ; option 1 recommandée |

---

## 6. Historique

| Date | Auteur | Note |
|---|---|---|
| 2026-06-23 | David Joulin (assisté par Claude) | Création après nuit d'intégration du pilote ekylibre-dev.com — patches §2.1 à §2.7 stabilisés ; persistance v2.db à corriger en priorité |
| 2026-06-23 | David Joulin (assisté par Claude) | Ajout §1.6 (dépendance OneCLI gateway), §1.7 (image agent à builder), patches §2.8 (build image au boot) et §2.9 (propagation `ONECLI_API_KEY`). Option A retenue : OneCLI signup + build local |
| 2026-06-23 | David Joulin (assisté par Claude) | Ajout patch §2.10 (PATH pnpm v10+ dans container/Dockerfile) suite à échec build image agent au premier boot avec ONECLI_API_KEY |
| 2026-06-23 | David Joulin (assisté par Claude) | **§1.8 — Découverte du blocant architectural host/container path mismatch.** Pilote V1 bloqué au spawn des containers agent. Option 1 (bind mount paths identiques) à implémenter à tête reposée |
