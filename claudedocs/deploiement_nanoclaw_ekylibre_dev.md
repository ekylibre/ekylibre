# Déploiement NanoClaw sur ekylibre-dev.com — Procédure pas à pas

> Procédure opérationnelle pour le **premier déploiement** de NanoClaw (canal Telegram, multi-tenant) sur l'environnement `ekylibre-dev.com`. Suit la spec [`workflow_nanoclaw_telegram_prod.md`](./workflow_nanoclaw_telegram_prod.md).
>
> Hypothèse : `ekylibre-dev.com` tourne sur **Dokploy** (variante `docker-compose.dokploy.yml`). Les écarts pour la variante Caddy native (`docker-compose.yml`) sont signalés `→ variante Caddy :` en ligne.

| | |
|---|---|
| **Statut spec** | v1.0 — 2026-06-22 |
| **Statut image** | `v0.1.5` — bot Telegram répond aux inbound, agent_group wired, image agent buildée, OneCLI OK. **MAIS** spawn des containers agent exit 1 à cause d'un mismatch architectural host/container (cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.8). **Pilote V1 bloqué end-to-end.** |
| **Cible** | ekylibre-dev.com (pilote interne, pas d'utilisateurs externes) |
| **Tenant pilote** | `demo` |
| **Statut pilote** | ⛔ **BLOQUÉ** au spawn agent (§1.8). Fix : option 1 (bind mount chemins identiques host↔container) à coder, voir [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.8 |
| **Limites V1 connues** | Mono-tenant (1 bot par host) ; v2.db non persistante au restart — re-init idempotente ; dépendance SaaS OneCLI obligatoire. Voir [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.5, §1.6, §3 |

---

## 0. Pré-requis à valider AVANT de commencer

- [X] Accès SSH `root` (ou `docker` group) à la VM ekylibre-dev.com
- [X] Accès à la console Dokploy
- [X] Compte Anthropic actif avec un `ANTHROPIC_AUTH_TOKEN` valide (peut être le même que `ANTHROPIC_API_KEY` côté Duke)
- [X] Accès au compte GHCR `ghcr.io/ekylibre/*` (push) ou possibilité de builder directement sur la VM
- [X] Compte Telegram pour parler à `@BotFather`
- [X] Au moins 1 chat_id Telegram identifié (= ton compte personnel pour le test pilote)
- [X] Service Duke déjà UP et joignable depuis `app` sur `ws://duke-api:8000/ws` (à vérifier : `docker compose ps duke-api`)
- [ ] **Compte OneCLI** créé sur https://app.onecli.sh avec une `ONECLI_API_KEY` valide (cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.6 — NanoClaw v2 dépend de cette gateway SaaS upstream pour provisionner les credentials Claude des containers agent)

---

## 1. Construire et publier l'image NanoClaw

### 1.1 Build local (pour validation)

Le Dockerfile applique 4 patches au build (cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §2.1 à §2.4). Sanity check :

```bash
cd ~/projects/ekylibre
docker build -f docker/nanoclaw/Dockerfile -t ghcr.io/ekylibre/nanoclaw-ekylibre:v0.1.5 .
docker tag ghcr.io/ekylibre/nanoclaw-ekylibre:v0.1.5 ghcr.io/ekylibre/nanoclaw-ekylibre:latest
docker images ghcr.io/ekylibre/nanoclaw-ekylibre
```

### 1.2 Push vers GHCR

```bash
# Authentification GHCR (PAT avec scopes `write:packages, read:packages`)
export GHCR_TOKEN='XXXXXXX'
echo "$GHCR_TOKEN" | docker login ghcr.io -u ionosphere --password-stdin

# Tag + push
docker push ghcr.io/ekylibre/nanoclaw-ekylibre:v0.1.5
docker push ghcr.io/ekylibre/nanoclaw-ekylibre:latest

# Rendre l'image publique sur GHCR (UI : packages/nanoclaw-ekylibre → Package settings)
# Sinon la VM aura besoin d'un docker login GHCR aussi.
```

> **Alternative bare-metal** : si pas d'accès GHCR push, builder directement sur la VM ekylibre-dev.com en clonant le repo et en faisant le `docker build` sur place. Plus simple pour un pilote.

---

## 2. Préparer la VM ekylibre-dev.com

SSH dans la VM, puis :

### 2.1 Pull du repo Ekylibre à jour

```bash
cd /opt/ekylibre   # ou le chemin de déploiement réel
git pull origin 5.0-beta
```

S'assurer que `docker/nanoclaw/` et le bloc `nanoclaw:` du compose sont présents.

### 2.2 Créer le fichier `nanoclaw-tenants.yml` (secret)

```bash
# Doit exister avant `docker compose up` (sinon Docker le crée comme un dossier).
sudo touch /opt/ekylibre/nanoclaw-tenants.yml
sudo chmod 0600 /opt/ekylibre/nanoclaw-tenants.yml
sudo chown root:root /opt/ekylibre/nanoclaw-tenants.yml
```

Le remplir vient en §3 après création du bot.

### 2.3 Étendre `.env` avec les variables NanoClaw

À ajouter au `.env` de production (ne pas committer) :

```bash
# Image
NANOCLAW_IMAGE_TAG=v0.1.5

# Anthropic — peut réutiliser la même clé que Duke
ANTHROPIC_AUTH_TOKEN=sk-ant-...
ANTHROPIC_BASE_URL=

# OneCLI gateway (REQUIS — sans, les containers agent exit 125)
# Inscription : https://app.onecli.sh -> Account -> API Keys
ONECLI_API_KEY=ock_xxxxxxxxxxxxxxxxxxxxxxxx
ONECLI_URL=

# Provider LLM par défaut
NANOCLAW_LLM_PROVIDER=claude
NANOCLAW_LOG_LEVEL=info

# Chemin host vers le fichier tenants.yml
NANOCLAW_TENANTS_PATH=/opt/ekylibre/nanoclaw-tenants.yml
```

Validation immédiate :

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml config 2>&1 | grep -A 3 "^  nanoclaw:"
# → variante Caddy : remplacer `docker-compose.dokploy.yml` par `docker-compose.yml`
```

Doit afficher le service `nanoclaw` sans warning sur `NANOCLAW_*` ni `ANTHROPIC_AUTH_TOKEN`.

### 2.4 ⚠️ Patches embarqués dans l'image

7 patches au total (3 build + 4 runtime) cumulés pour rendre NanoClaw v2 compatible avec notre cas d'usage. Détaillés un par un dans **[`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §2**. Résumé :

| # | Couche | Patch | À retirer quand… |
|---|---|---|---|
| 2.1 | Build | `python3 make g++` dans le builder pour `better-sqlite3` | upstream prebuild node 24 dispo |
| 2.2 | Build | Source = branche `channels`, pas `main` | `channels` mergée dans `main` |
| 2.3 | Build | Suppression de `deltachat.ts` / `slack.ts` + ajout de `resolveChannelName?` à l'interface `ChannelAdapter` | `channels` upstream verte |
| 2.4 | Runtime | `corepack prepare pnpm@10.33.0 --activate` en stage 2 | jamais (intrinsèque) |
| 2.5 | Runtime | `init.sh` propage `TELEGRAM_BOT_TOKEN` du tenant au host `/app/.env` | architecture multi-tenant tranchée |
| 2.6 | Runtime | `init.sh` appelle `npx tsx scripts/init-first-agent.ts` après que v2.db soit prête | v2.db persistante + wiring déclaratif upstream |
| 2.7 | Runtime | `init.sh` overlay `CLAUDE.local.md` Ekylibre sur le `groups/dm-with-<tenant>/` créé | jamais (c'est notre system prompt) |
| 2.8 | Runtime | `init.sh` build l'image `nanoclaw-agent-v2-<slug>:latest` au premier boot via `container/build.sh` (idempotent, ~5 min) | jamais (intrinsèque à l'archi v2) |
| 2.9 | Runtime | Propagation de `ONECLI_API_KEY` au host `/app/.env` ; sans clé, les containers agent exit 125 | dépendance upstream à OneCLI levée (improbable) |
| 2.10 | Build | Sed sur `container/Dockerfile` pour fixer `ENV PATH="$PNPM_HOME/bin:$PATH"` (pnpm v10+ bin layout) | upstream corrigera le PATH |

**À surveiller upstream** : merge de `channels` → `main`, ou première release tag qui inclut la skill Telegram, pour dégeler 2.2 et 2.3.

---

## 3. Provisionner le bot Telegram + le tenant pilote

### 3.1 Créer un bot Telegram via BotFather

Depuis ton compte Telegram :

1. Ouvrir un chat avec `@BotFather`
2. `/newbot` → choisir un nom (ex: `Ekylibre Dev Assistant`)
3. Choisir un username unique terminant par `bot` (ex: `EkylibreDevAssistantBot`)
4. BotFather renvoie un `bot_token` du style `1234567890:AAH-...` → le copier
5. (Optionnel) `/setdescription`, `/setabouttext`, `/setuserpic` pour l'esthétique

### 3.2 Récupérer ton `chat_id` Telegram

```bash
# Envoyer un /start au bot d'abord, puis :
curl -s "https://api.telegram.org/bot<BOT_TOKEN>/getUpdates" | jq '.result[].message.chat.id' | sort -u
```

Note le `chat_id` (entier signé). C'est ce qui ira dans `authorized_chat_ids`.

### 3.3 Récupérer un `authentication_token` Ekylibre pour le tenant pilote

```bash
# Dans le container app prod
docker compose -f docker/prod/docker-compose.dokploy.yml exec app \
  bundle exec rails runner -e production "
    Apartment::Tenant.switch!('ekylibre-dev')   # remplacer par le vrai schema
    user = User.find_by(email: 'admin@ekylibre-dev.com')
    user.reset_authentication_token!
    puts user.authentication_token
  "
```

⚠️ V1 = **token utilisateur complet**, pas scoped. Mitigation V1.5 (cf. spec §10 entrée 1). Pour le pilote interne sur un compte admin contrôlé, le risque est accepté.

### 3.4 Renseigner `nanoclaw-tenants.yml`

Partir du template :

```bash
scp nanoclaw-tenants.yml xxxx:/home/ubuntu/ekylibre/nanoclaw-tenants.yml
ssh xxxxx
chmod 0600 /home/ubuntu/ekylibre/nanoclaw-tenants.yml
chown ubuntu:ubuntu /home/ubuntu/ekylibre/nanoclaw-tenants.yml
```

Contenu cible pour le pilote :

```yaml
tenants:
  - id: demo                            # doit matcher le schema Apartment
    locale: fra
    llm_provider: claude
    ekylibre:
      email: admin@ekylibre.org
      token: ekt_xxxxxxxxxxxxxxxxxxxxxxxx       # 3.3
    telegram:
      bot_token: "1234567890:AAH-..."           # 3.1
      bot_username: EkylibreDevAssistantBot     # 3.1
      authorized_chat_ids: [123456789]          # 3.2 — ton chat_id perso
```

Sanity check YAML :

```bash
python3 -c "import yaml; print(yaml.safe_load(open('/opt/ekylibre/nanoclaw-tenants.yml')))"
```

---

## 4. Déployer le service

### 4.1 Pull de l'image

```bash
cd /opt/ekylibre
docker compose -f docker/prod/docker-compose.dokploy.yml pull nanoclaw
# → variante Caddy : docker-compose.yml
```

### 4.2 Up du service

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml up -d nanoclaw
```

Surveiller le boot :

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml logs -f nanoclaw
```

Séquence attendue (durée totale : ~30 s au boot normal, **~5 min au tout premier boot** à cause du build de l'image agent) :

```
init.sh: Provisioning 1 tenant(s) depuis /etc/nanoclaw/tenants.yml
init.sh:   v tenant demo pret
init.sh: TELEGRAM_BOT_TOKEN propage au host .env (depuis tenant 'demo')
init.sh: Agent image deja presente: nanoclaw-agent-v2-0c35eebf:latest
   # OU au premier boot uniquement :
   # init.sh: Build de l'agent image nanoclaw-agent-v2-0c35eebf:latest (premier boot, peut prendre 5 min)...
   #     [logs docker build ...]
   # init.sh: Agent image buildee: nanoclaw-agent-v2-0c35eebf:latest
init.sh: Demarrage du host NanoClaw (background)
> nanoclaw@2.0.14 start /app
> node dist/index.js
[INFO] NanoClaw starting
[INFO] Central DB initialized path="/app/data/v2.db"
[INFO] Running migrations count=11
... [11 migrations] ...
[INFO] Central DB ready path="/app/data/v2.db"
[chat-sdk:telegram] Telegram adapter initialized { botUserId: '...', userName: 'EkylibreDevAssistantBot' }
[chat-sdk:telegram] Telegram polling started { ... }
[INFO] Channel adapter started channel="telegram" type="telegram"
[INFO] NanoClaw running
init.sh: Wait NanoClaw DB ready...
init.sh: NanoClaw DB ready (attempt N/90)
init.sh: Init premiere agent_group: telegram:5568569575 pour tenant 'demo'
    [output script init-first-agent.ts]
init.sh: CLAUDE.local.md Ekylibre installe dans /app/groups/dm-with-demo
init.sh: NanoClaw foreground (PID XXX)
... [welcome DM dans ~60 s : cold start container agent] ...
```

Drapeaux rouges :
- `WARN Channel credentials missing, skipping channel="telegram"` → patch 2.5 a foiré
- `WARN Channel registration skipped — no agent groups configured` → patch 2.6 a foiré
- `WARN OneCLI gateway error -- container will have no credentials` + `Container exited code=125` → `ONECLI_API_KEY` vide ou invalide dans `.env` (patch 2.9)
- `OneCLI returned 403` → compte OneCLI en limite agents (purger les agents inutilisés dans le dashboard)
- `WARN build agent image a echoue` → docker.sock mal mappé ou container/ absent (patch 2.8)
- `INFO OneCLI gateway applied` puis `Container exited code=1` en <500 ms → **bug §1.8 host/container path mismatch** ; spawn réussit mais l'agent reçoit des mounts vides. Fix : architecture à corriger, cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.8

### 4.3 Vérifier l'état

```bash
# Statut Docker
docker compose -f docker/prod/docker-compose.dokploy.yml ps nanoclaw

# Statut applicatif via la CLI embarquée
docker compose -f docker/prod/docker-compose.dokploy.yml exec nanoclaw nanoclaw status
```

Sortie attendue de `nanoclaw status` :
```
TENANT                         STATUS     CONTAINER ID
demo                           running    abc123def456
```

Note : `nanoclaw status` liste les tenants déclarés dans `nanoclaw-tenants.yml` ; le `running` ne reflète **pas** l'état des `agent_groups` upstream (qui sont la vraie source de routage — cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.2). Pour vérifier l'agent_group :

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml exec nanoclaw \
  sqlite3 /app/data/v2.db \
  "SELECT id, name, created_at FROM agent_groups"
```

Doit retourner au moins une ligne `dm-with-demo`.

---

## 5. Premier test utilisateur

Depuis ton compte Telegram, dans le chat ouvert avec ton bot :

### 5.1 Smoke test minimal

| Étape | Message envoyé | Comportement attendu |
|---|---|---|
| 1 | `/start` | Message d'accueil du bot (réponse du LLM via le CLAUDE.md du tenant) |
| 2 | `/help` | Liste des capacités / exemples |
| 3 | `Quel temps fait-il demain ?` | Hors périmètre Duke → réponse Claude directe |
| 4 | `Combien me reste-t-il de Karaté Zeon ?` | Appel `duke_chat` → réponse depuis Ekylibre (si stock présent dans le tenant) ou message "pas de stock connu" |

### 5.2 Test du flow intervention (le cas critique)

Message : `J'ai pulvérisé 2 L de Karaté Zeon sur Bel Air ce matin pendant 1h30.`

Attendu :
1. Bot envoie une carte brouillon avec les champs reconnus + boutons `[✓ Valider]` `[🗑 Annuler]`
2. Clic sur `Valider` → message `✅ Intervention #XXXX créée. Voir : https://ekylibre-dev.com/...`
3. Vérification côté Ekylibre : l'intervention apparaît dans `/backend/interventions` du tenant

> Pré-requis pour que ça marche : produit `Karaté Zeon` et parcelle `Bel Air` doivent exister dans le tenant `ekylibre-dev`. Sinon, adapter le message au stock réel.

### 5.3 Vérification logs

Pas de tokens en clair, pas de PII, JSON structuré :

```bash
docker compose -f docker/prod/docker-compose.dokploy.yml logs --tail=200 nanoclaw | jq -c 'select(.event)' | head -20
```

---

## 6. Procédures post-déploiement

### 6.1 Ajouter un second tenant (à chaud)

> **⚠️ V1 mono-tenant** — upstream NanoClaw v2 ne supporte qu'**un seul bot Telegram par host** (cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.1). Ajouter un 2e tenant dans `nanoclaw-tenants.yml` ne créera **pas** un 2e bot : seul le bot du premier tenant restera actif. `init.sh` logge un WARN dans ce cas.
>
> Pour ajouter un vrai 2e tenant, deux options à trancher (voir [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §3) :
> - **A** : Dupliquer le service nanoclaw dans le compose (1 container par tenant)
> - **B** : Wirer un 2e agent_group sur le même bot via `init-first-agent.ts` (multi-farms via un bot unique)
>
> Tant que la décision n'est pas prise, garder le pilote mono-tenant.

### 6.2 Mise à jour de l'image

```bash
# 1. Bump du tag dans .env
sed -i 's/NANOCLAW_IMAGE_TAG=.*/NANOCLAW_IMAGE_TAG=v0.1.5/' /opt/ekylibre/.env

# 2. Pull + recreate sans toucher les autres services
docker compose -f docker/prod/docker-compose.dokploy.yml pull nanoclaw
docker compose -f docker/prod/docker-compose.dokploy.yml up -d --no-deps nanoclaw
```

Pendant le restart (~30 s), Telegram met les messages en file côté serveur Bot API → pas de perte au retour du long-poll.

> ⚠️ Au restart, `v2.db` est **wipée** (cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.5). `init.sh` ré-init automatiquement l'agent_group via `scripts/init-first-agent.ts` (idempotent côté upstream). Pas d'action manuelle. À corriger en V1.1 (persistance v2.db).

### 6.3 Rotation d'un token Telegram (bot leaké)

```bash
# 1. @BotFather → /revoke → choisir le bot → nouveau token
# 2. sudo nano /opt/ekylibre/nanoclaw-tenants.yml → mettre à jour bot_token
# 3. nanoclaw reload
docker compose -f docker/prod/docker-compose.dokploy.yml exec nanoclaw nanoclaw reload
```

### 6.4 Sauvegardes

À configurer dans Dokploy (UI → backups) ou via cron host :

| Donnée | Chemin | Rétention |
|---|---|---|
| Volume `nanoclaw-data` | `/var/lib/docker/volumes/ekylibre_nanoclaw-data/_data` | 30 j |
| `nanoclaw-tenants.yml` | `/opt/ekylibre/nanoclaw-tenants.yml` (chiffré) | illimité |

⚠️ **À noter** : tant que la persistance de `v2.db` n'est pas corrigée (V1.1), le volume `nanoclaw-data` est **vide** — aucune donnée critique n'y est écrite par upstream. La sauvegarde devient pertinente quand v2.db migrera vers le volume. Cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.5.

---

## 7. Rollback

Si NanoClaw casse quelque chose ou si on veut revenir à l'état antérieur :

```bash
# Arrêter et retirer NanoClaw (sans toucher le reste de la stack)
docker compose -f docker/prod/docker-compose.dokploy.yml stop nanoclaw
docker compose -f docker/prod/docker-compose.dokploy.yml rm -f nanoclaw

# (Optionnel) purger le volume de données
docker volume rm ekylibre_nanoclaw-data
```

Aucun impact sur `app`, `sidekiq`, `db`, `duke-api`. NanoClaw est strictement **additif** dans la stack.

---

## 8. Checklist de validation finale

À cocher avant de considérer le pilote stable :

- [ ] Image `ghcr.io/ekylibre/nanoclaw-ekylibre:v0.1.5` publiée
- [ ] `.env` prod contient `ONECLI_API_KEY` non-vide + les autres variables NanoClaw
- [ ] `/opt/ekylibre/nanoclaw-tenants.yml` créé, 0600, root:root, syntaxe YAML valide
- [ ] `docker compose ... up -d nanoclaw` réussit, healthcheck passe en `healthy`
- [ ] Logs montrent `Agent image deja presente: nanoclaw-agent-v2-...:latest` (ou build OK au 1er boot)
- [ ] Logs montrent `Channel adapter started channel="telegram"` (pas `Channel credentials missing`)
- [ ] Logs montrent `CLAUDE.local.md Ekylibre installe dans /app/groups/dm-with-demo`
- [ ] Aucun `WARN OneCLI gateway error` au spawn des containers
- [ ] `sqlite3 v2.db "SELECT * FROM agent_groups"` retourne au moins 1 ligne
- [ ] Welcome DM Telegram reçu après le `up -d` (cold start agent ~60 s)
- [ ] Question Q&A Duke → réponse reçue
- [ ] Saisie d'intervention → carte brouillon + Valider → intervention créée dans Ekylibre
- [ ] Pare-feu host : aucun port entrant ajouté pour `nanoclaw` (Telegram = sortant)
- [ ] Issue de tracking ouverte pour les **patches §2.2 et §2.3** (dégeler quand `channels` mergé)
- [ ] Issue de tracking ouverte pour la **persistance v2.db** (V1.1)
- [ ] Décision architecture multi-tenant prise (A vs B, cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §3)
- [ ] Décision RGPD/souveraineté sur la dépendance OneCLI documentée (cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §1.6)
- [ ] Page utilisateur publiée pour les pilotes (`/help` content + limites V1)

---

## 9. Points d'attention restants (à valider pendant le pilote)

Issues consolidées de la spec §10 + des découvertes pendant l'intégration ekylibre-dev.com (cf. [`notes_nanoclaw_v2.md`](./notes_nanoclaw_v2.md) §5) :

| # | Sujet | Statut |
|---|---|---|
| 0 | ⛔ **Mismatch host/container paths au spawn agent** ([`notes`](./notes_nanoclaw_v2.md) §1.8) | **BLOQUANT — pilote V1 inutilisable end-to-end tant que pas fixé. Option 1 (bind mount paths identiques) à coder.** |
| 1 | Persistance v2.db | Réglé en même temps que #0 (même fix) |
| 2 | Persistance `groups/` | Idem |
| 3 | Architecture multi-tenant (A vs B) | Décision après pilote stable |
| 4 | Tracking branche `channels` upstream | Watch sur le merge `channels → main` ; dégeler patches §2.2 §2.3 |
| 5 | `nanoclaw reload` réel upstream | Pas valide en l'état (`tenants.yml` ne contrôle plus le routage) |
| 6 | Compat Dokploy variant | C'est ce déploiement même qui valide |

---

## 10. Contacts en cas d'incident

- Owner pilote : David Joulin (djoulin@ekylibre.com)
- Référent Duke : (à compléter)
- Référent infra Dokploy : (à compléter)

## Historique

| Version | Date | Auteur | Modif |
|---|---|---|---|
| 1.0 | 2026-06-22 | David Joulin (assisté par Claude) | Création initiale après build local OK |
| 1.1 | 2026-06-23 | David Joulin (assisté par Claude) | Mise à jour après nuit d'intégration ekylibre-dev.com : 7 patches stratifiés, image v0.1.3, bot Telegram répondant ; renvoi vers `notes_nanoclaw_v2.md` pour les écarts spec↔upstream |
| 1.2 | 2026-06-23 | David Joulin (assisté par Claude) | Ajout patches 2.8 (build image agent) et 2.9 (OneCLI gateway requis). Image v0.1.4. Nouveau pré-requis : compte OneCLI |
| 1.3 | 2026-06-23 | David Joulin (assisté par Claude) | Ajout patch 2.10 (PATH pnpm v10+ dans container/Dockerfile) suite à échec build image agent au premier boot. Image v0.1.5 |
| 1.4 | 2026-06-23 | David Joulin (assisté par Claude) | **Découverte blocant §1.8** : mismatch host/container paths au spawn agent. Tous les étages amont fonctionnent (bot, OneCLI, image agent, wiring) mais le container agent exit 1 parce que ses mounts vont sur des paths du host inexistants. Fix architectural recommandé : bind mount avec chemins identiques host↔container. Reprise demain |
