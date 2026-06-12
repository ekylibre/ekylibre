# Workflow — Environnement de production Docker pour Ekylibre

**Demande** : Créer un environnement de production complet dans `docker/prod/`, modélisé sur `docker/dev/`, permettant à un opérateur de déployer Ekylibre simplement (saisie d'un nom de domaine, chargement du lexicon). Le déploiement doit aussi permettre de **lancer Duke** (assistant chatbot agricole, repo `/home/djoulin/projects/duke`) en service opt-in.

**Type** : Plan d'implémentation (aucun code n'est produit par ce workflow — utiliser `/sc:implement` ensuite phase par phase).

**Branche cible** : `5.0-beta`

---

## 1. Analyse de l'existant

### 1.1 `docker/dev/` — modèle de référence
- `docker-compose.yml` : 5 services (`app`, `sidekiq`, `caddy`, `redis`, `db`), tous reliés au réseau `ekylibre`. `db` est `kartoza/postgis:13`, `redis:7-alpine`, `caddy:2-alpine`.
- `Dockerfile` : basé sur `ghcr.io/ekylibre/docker-base-images/ruby2.6:latest`. Crée l'utilisateur `ekylibre` avec UID/GID configurables.
- `Caddyfile` : TLS interne (`tls internal`), route `*.ekylibre.localhost` vers `app:3000`, redirige `:80 → :443`.
- `.env.dist` : 11 variables — `RAILS_ENV`, `HOST_DOMAIN_NAME`, `ADMIN_*`, `DB_*`, `REDIS_URL`, MinIO.
- `sidekiq_startup.sh` : `bundle install` puis `bundle exec sidekiq`.
- `docker/startup.sh` (partagé) : `db:create` → `db:migrate` → (premier run ou changement de version) `lexicon:load` → démarre Unicorn en prod ou Rails server en dev.
- `docker/db/init.sql` : crée le schéma `postgis` + extensions (`postgis`, `uuid-ossp`, `pgcrypto`, `unaccent`, `pg_trgm`).
- `docker/db/init-duke-role.sh` : crée un rôle PostgreSQL en lecture seule pour Duke (BI tool externe).

### 1.2 `docker/prod/` — état actuel (vétuste / cassé)
Fichiers présents mais à reconstruire :
- `docker-compose.yml` (mai 2023) : référence `redis:5.0-alpine`, image GitLab CI cassée, `version: "3.4"` obsolète, healthcheck app absent, pas de Caddy.
- `Dockerfile` : utilise `ruby2.6:2` (image non maintenue), pas de `--build-arg UID`, copie un `unicorn.rb` qui dépend d'un gem `unicorn` **absent du Gemfile** (vérifié : `grep ^gem.*unicorn Gemfile` → 0 résultats). `startup.sh:48` invoque pourtant `bundle exec unicorn`. **Bug bloquant à corriger**.
- `nginx.conf` : `<your-domain-name>` codé en dur dans `server_name` et chemins SSL → édition manuelle obligatoire avant build.
- `.env.sample` : 9 variables, `SECRET_KEY_BASE=!ChangeMe!` en dur, pas de `HOST_DOMAIN_NAME`, pas d'`ADMIN_*`.
- `letsencrypt/generate_certificates.sh` : challenge `--manual` DNS, email et domaine codés en dur (`!ChangeMe!`).
- `tenants.yml` : `production: []` (vide, par défaut).
- `README.md` : 5 étapes, suppose une édition manuelle de 3 fichiers avant le `up`.

### 1.3 Écarts à combler pour atteindre l'objectif
1. **Setup en une commande** : aujourd'hui 3 fichiers à éditer manuellement (nginx.conf, certbot script, .env). Cible : 1 seul fichier `.env` à remplir.
2. **TLS automatique** : remplacer le couple nginx+certbot manuel par Caddy 2 (Let's Encrypt automatique via ACME, wildcard via DNS-01 si nécessaire, ou cert-per-tenant en HTTP-01).
3. **App server** : aligner Gemfile + Dockerfile + startup.sh sur un serveur unique (recommandation : Puma 5, plus simple, déjà présent dans la baseline Rails 5.2).
4. **Lexicon idempotent** : `startup.sh` gère déjà la détection de version, mais il faut le rendre visible et restartable. Ajout d'un mode `lexicon:load` explicite via `docker compose run`.
5. **Sécurité prod** : non-écriture du code applicatif dans le container (image figée), `SECRET_KEY_BASE` généré, `RAILS_SERVE_STATIC_FILES=true`, `RAILS_LOG_TO_STDOUT=true`, healthchecks sur tous les services.
6. **Backups & persistance** : volumes nommés pour DB, certs Caddy, logs, uploads (`/app/private`, `/app/public/system`).
7. **Procédure d'admin tenant** : créer un tenant en prod nécessite `rake tenant:init`, à documenter via un wrapper `docker compose exec app …`.
8. **Service Duke (opt-in)** : Duke est un service Python (FastAPI + asyncpg) **distribué via image publique** `ghcr.io/ekylibre/duke/duke-api:latest`. Il a besoin :
   - de sa propre DB (`postgres-duke`, Postgres 16),
   - d'un accès lecture seule à la DB Ekylibre via le rôle `duke_reader` (créé par `docker/db/init-duke-role.sh` si `DUKE_USER`/`DUKE_PASSWORD` sont définis) — sur le **même réseau interne** que la DB Ekylibre,
   - d'un accès interne à l'API Ekylibre via `http://app:3000`,
   - d'une route Caddy `duke.<HOST_DOMAIN_NAME>` → `duke-api:8000`,
   - éventuellement de Whisper STT (image taggée `:latest-stt` ou variable d'image dédiée) et d'Ollama (sous-profile cascadé).
   Le service doit être **désactivé par défaut** (profile Compose `duke`) pour ne rien imposer aux déploiements qui ne veulent pas du chatbot.

### 1.4 Image Duke — invariants à respecter
- **Image publique** : `ghcr.io/ekylibre/duke/duke-api:latest` (tag par défaut, override possible via `DUKE_IMAGE_TAG`). Aucun clone de repo, aucun build local côté Ekylibre.
- **Port interne** : 8000. CMD bakée : `uvicorn duke.main:app --host 0.0.0.0 --port 8000`.
- **Healthcheck bakée** : `curl /healthz`.
- **Variables d'environnement** requises (`.env.example` de Duke documente les 30+ vars) :
  - `EKYLIBRE_API_BASE_URL=http://app:3000` (résolu via le réseau partagé Ekylibre).
  - `EKYLIBRE_DB_DSN=postgresql://duke_reader:<pwd>@db:5432/eky_production` (résolu via le réseau partagé Ekylibre).
  - `DUKE_DB_DSN=postgresql+asyncpg://duke:<pwd>@postgres-duke:5432/duke`.
  - `HASH_SECRET` (obligatoire en prod, audit RGPD).
  - Clés LLM (`ANTHROPIC_API_KEY`, `MISTRAL_API_KEY`) — au moins une non-vide.
- **STT (optionnel)** : si `ENABLE_SERVER_STT=true` à runtime, l'image doit avoir été buildée avec `INSTALL_STT=true`. **Variante** : si l'équipe Duke publie deux tags (`:latest` slim et `:latest-stt` avec Whisper), choisir via `DUKE_IMAGE_TAG=latest-stt`. **À confirmer avec l'équipe Duke** quels tags sont publiés.

---

## 2. Décisions d'architecture

| Sujet | Choix | Pourquoi |
|---|---|---|
| Reverse-proxy + TLS | **Caddy 2** (au lieu de nginx + certbot) | Provisionnement Let's Encrypt automatique ; même outil que dev → cohérence ; un seul fichier `Caddyfile` paramétrable par variable d'env (`HOST_DOMAIN_NAME`). |
| App server | **Puma** (au lieu d'Unicorn cassé) | Compatible Rails 5.2, threads + workers, plus simple ; `config/puma.rb` existe déjà dans `config/`. Si Unicorn est imposé, ajouter `gem 'unicorn'` dans une section production-only. **À trancher avec l'utilisateur** avant la phase 3. |
| DB | `kartoza/postgis:13` (idem dev) | PostGIS multi-extensions out-of-the-box ; volume `database-prod-volume` persistant ; pas d'exposition de port hôte par défaut (uniquement interne). |
| Redis | `redis:7-alpine` (au lieu de 5) | Aligné sur dev, support `vm.overcommit_memory` ; volume optionnel si on veut persister les jobs Sidekiq. |
| Sidekiq | Container dédié `sidekiq` avec `restart: on-failure` | Identique à dev mais sans bind-mount du code source. |
| Assets | `assets:precompile` au build de l'image | Image autoportante, pas de volume code en prod. Volume `public-assets` partagé entre `app` et `caddy` uniquement si Caddy sert le static — sinon Rails sert avec `RAILS_SERVE_STATIC_FILES=true`. |
| Gestion des secrets | `.env` (gitignore) + `.env.dist` (tracké) | Cohérent avec dev. `SECRET_KEY_BASE` généré au premier `up` par un script idempotent si absent. |
| Domaine | Variable `HOST_DOMAIN_NAME` injectée dans Caddyfile via `caddy run --envfile` ou substitution `{$HOST_DOMAIN_NAME}` (syntaxe Caddy native) | Une seule source de vérité, partagée par Caddy + Rails (`config/application.rb` lit déjà `HOST_DOMAIN_NAME`). |
| Multi-tenant TLS | Wildcard `*.example.com` via DNS-01 (Cloudflare/OVH/Gandi) **OU** certs par tenant via HTTP-01 (recommandé si < 50 tenants) | Choix utilisateur. Le HTTP-01 ne nécessite aucune clé API DNS et fonctionne par défaut. **À demander à l'utilisateur en phase 2**. |
| Lexicon | Étape automatique au premier démarrage (idempotente), avec sortie visible ; commande manuelle documentée | Le code de `startup.sh:31-44` est déjà bon — il suffit de l'exposer dans la doc et d'ajouter un message clair. |
| Backup DB | Service optionnel `db-backup` (sidecar) qui `pg_dump` toutes les 24h vers un volume nommé | Out-of-scope du strict minimum, mais à proposer. **À demander à l'utilisateur**. |
| **Duke** | **Profile Compose `duke`** + **image publique `ghcr.io/ekylibre/duke/duke-api:${DUKE_IMAGE_TAG:-latest}`** + variables d'env regroupées dans `.env` Ekylibre | Image pré-buildée publiée sur GHCR → `docker compose pull` au lieu de build local. Un seul `.env` à éditer (vars `DUKE_*` dans une section dédiée). Activation explicite : `docker compose --profile duke up -d`. Réseau partagé `ekylibre` (= réseau `default` du stack) → Duke voit `db:5432` et `app:3000` directement. |
| **Duke — STT** | Tag d'image `latest-stt` via `DUKE_IMAGE_TAG=latest-stt` + runtime `ENABLE_SERVER_STT=true` | Pas de build local — variante d'image avec Whisper bundled. Désactivé par défaut. |
| **Duke — Ollama** | Sous-profile `duke-llm-local` cascadé sur `duke` | Local LLM optionnel, activé via `docker compose --profile duke --profile duke-llm-local up -d`. |

---

## 3. Inventaire des livrables

```
docker/prod/
├── README.md                    # Procédure complète (FR), 10–15 étapes max
├── docker-compose.yml           # 5 services par défaut (app, sidekiq, caddy, redis, db)
│                                #   + profile `duke` : duke-api, postgres-duke
│                                #   + profile `duke-llm-local` : ollama, ollama-pull
├── Dockerfile                   # Image immuable basée sur ghcr.io/ekylibre/docker-base-images/ruby2.6
├── Caddyfile                    # Templated par {$HOST_DOMAIN_NAME} ; bloc duke.<domaine> conditionnel
├── .env.dist                    # Toutes les variables (Ekylibre + Duke), valeurs d'exemple inoffensives
├── .env                         # gitignored, créé par cp depuis .env.dist
├── startup.sh                   # Wrapper prod : fail-fast sur SECRET_KEY_BASE vide, db:create, db:migrate, lexicon:load, puma
├── sidekiq_startup.sh           # bundle exec sidekiq -C config/sidekiq.yml
└── scripts/
    ├── tenant-init.sh           # wrapper docker compose exec → rake tenant:init
    ├── tenant-drop.sh           # idem → rake tenant:drop
    ├── lexicon-reload.sh        # idem → rake lexicon:load
    └── duke-up.sh               # wrapper docker compose --profile duke up -d (+ pull-llm-local optionnel)
```

Fichiers à **modifier hors `docker/prod/`** :
- `.gitignore` : ajouter `docker/prod/.env` (si pas déjà couvert par `docker/dev/.env`).
- `docker/startup.sh` : à conserver tel quel **ou** dupliquer dans `docker/prod/startup.sh` pour découpler dev et prod (recommandé — éviter qu'une modif dev casse la prod).
- `Gemfile` : ajouter `gem 'unicorn'` dans `group :production` **si** Unicorn est retenu (voir §2).

---

## 4. Phases d'implémentation

### Phase 0 — Décisions utilisateur ✅ VERROUILLÉ

| Sujet | Décision |
|---|---|
| **App server** | **Puma** — ajouter `gem 'puma'` dans `group :production` si absent, créer/vérifier `config/puma.rb`. |
| **TLS** | **HTTP-01 par sous-domaine** — Caddyfile standard, pas d'image Caddy custom, pas de variables DNS dans `.env`. |
| **Backup DB** | **Manuel** — pas de service sidecar ; section README dédiée avec `docker compose exec db pg_dump …`. |
| **Duke** | **Service opt-in via profile Compose `duke`** — désactivé par défaut. Build depuis `../../../duke` (repo sibling). |

**Conséquences sur les phases suivantes** :
- Phase 1.1 (.env.dist) : retirer les variables `CADDY_TLS_DNS_PROVIDER` et `CLOUDFLARE_API_TOKEN`. **Ajouter** une section `# === Duke (optionnel) ===` avec tous les vars `DUKE_*`, `EKYLIBRE_DB_DSN`, `HASH_SECRET`, clés LLM, options STT/Ollama.
- Phase 1.2 (Caddyfile) : conserver la variante HTTP-01 simple, pas de bloc `tls { dns … }`. **Ajouter** un bloc `duke.{$HOST_DOMAIN_NAME}` (toujours présent ; si Duke n'est pas up, Caddy renvoie 502, comportement acceptable).
- Phase 1.4 (docker-compose.yml) : pas de service `db-backup`. **Ajouter** services `duke-api`, `postgres-duke` (profile `duke`) et `ollama`, `ollama-pull` (profile `duke-llm-local`).
- Phase 3 (Puma + health) : ACTIVE.
- Phase 4 (TLS) : limitée à la variante HTTP-01 — pas de `Dockerfile.caddy` custom à builder.
- **Nouvelle Phase 4.5** (Duke intégration) : voir ci-dessous.

### Phase 1 — Squelette des fichiers (`docker/prod/`)
**Durée** : 30 min.

Créer (ou réécrire) :

1. **`docker/prod/.env.dist`** — variables exhaustives, classées :
   ```
   # === Application ===
   RAILS_ENV=production
   HOST_DOMAIN_NAME=example.com            # SANS protocole, SANS sous-domaine
   ADMIN_USERNAME=admin
   ADMIN_PASSWORD=ChangeMe!                # 16+ chars recommandés
   SECRET_KEY_BASE=                        # laisser vide → généré au premier up
   RAILS_SERVE_STATIC_FILES=true
   RAILS_LOG_TO_STDOUT=true

   # === Database ===
   DB_HOST=db
   DB_PROD_NAME=eky_production
   DB_USERNAME=ekylibre
   DB_PASSWORD=ChangeMe!
   DUKE_USER=                              # optionnel — laisser vide pour désactiver
   DUKE_PASSWORD=

   # === Redis ===
   REDIS_URL=redis://redis

   # === TLS (Let's Encrypt) ===
   LETSENCRYPT_EMAIL=admin@example.com
   # CADDY_TLS_DNS_PROVIDER=cloudflare      # décommenter si DNS-01 (sinon HTTP-01 par défaut)
   # CLOUDFLARE_API_TOKEN=

   # === Object storage (optionnel) ===
   MINIO_HOST=
   MINIO_ACCESS_KEY=
   MINIO_SECRET_KEY=

   # === Observability (optionnel) ===
   ELASTIC_APM_ACTIVE=false

   # === Duke (optionnel — activer avec --profile duke) ===
   # Image Duke (publique sur GHCR — aucun build local).
   # Variantes : `latest` (slim) | `latest-stt` (avec Whisper bundled, ~+250 MB)
   DUKE_IMAGE_TAG=latest

   # Rôle PostgreSQL lecture seule créé automatiquement par docker/db/init-duke-role.sh
   # Laisser vides pour ne PAS créer le rôle (déploiement sans Duke).
   DUKE_USER=duke_reader
   DUKE_PASSWORD=ChangeMe!

   # Duke own DB (Postgres 16 séparé)
   DUKE_DB_USER=duke
   DUKE_DB_PASSWORD=ChangeMe!
   DUKE_DB_NAME=duke

   # DSN injectés dans le container duke-api (référencent les noms de services Compose)
   EKYLIBRE_API_BASE_URL=http://app:3000
   EKYLIBRE_DB_DSN=postgresql://duke_reader:ChangeMe!@db:5432/eky_production
   DUKE_DB_DSN=postgresql+asyncpg://duke:ChangeMe!@postgres-duke:5432/duke

   # Audit / RGPD — OBLIGATOIRE en prod (hash tenant+email dans audit log)
   HASH_SECRET=                            # openssl rand -hex 32

   # Whisper STT (opt-in à runtime — nécessite DUKE_IMAGE_TAG=latest-stt)
   ENABLE_SERVER_STT=false

   # LLM providers (au moins 1 requis si Duke activé)
   LLM_DEFAULT_PROVIDER=claude
   ANTHROPIC_API_KEY=
   CLAUDE_MODEL=claude-opus-4-7
   MISTRAL_API_KEY=
   MISTRAL_MODEL=mistral-large-latest

   # Local LLM via Ollama (sous-profile duke-llm-local)
   OLLAMA_BASE_URL=                        # http://ollama:11434 si activé
   OLLAMA_MODEL=mistral-nemo

   # WS sécurité
   ALLOWED_WS_ORIGINS=https://example.com,https://*.example.com
   SESSION_IDLE_TIMEOUT_S=1800
   RATE_LIMIT_PER_MIN=30
   ```

2. **`docker/prod/Caddyfile`** — un seul template Caddy paramétré :
   ```caddyfile
   {
       email {$LETSENCRYPT_EMAIL}
       admin off
   }

   # Bloc Duke — match spécifique AVANT le wildcard Ekylibre.
   # Si le profile `duke` n'est pas activé, Caddy renvoie 502 — comportement attendu.
   duke.{$HOST_DOMAIN_NAME} {
       reverse_proxy duke-api:8000 {
           header_up Host {host}
           header_up X-Forwarded-Proto https
       }
   }

   {$HOST_DOMAIN_NAME}, *.{$HOST_DOMAIN_NAME} {
       reverse_proxy app:3000 {
           header_up Host {host}
           header_up X-Forwarded-Proto https
           header_up X-Forwarded-For {remote_host}
       }
       encode gzip
       header {
           Strict-Transport-Security "max-age=31536000; includeSubDomains"
           X-Content-Type-Options nosniff
           Referrer-Policy strict-origin-when-cross-origin
       }
   }
   ```

3. **`docker/prod/Dockerfile`** — basé sur le dev mais sans bind-mount :
   - `FROM ghcr.io/ekylibre/docker-base-images/ruby2.6:latest`
   - `ARG UID=1000`, `ARG GID=1000`
   - `COPY . /app` (build context = racine du repo)
   - `bundle install --without development test --deployment` → `/app/vendor/bundle` baked dans l'image
   - `yarn install --frozen-lockfile && bundle exec rake webpacker:compile` (si Webpacker actif — vérifié en phase 0).
   - `SECRET_KEY_BASE=1 RAILS_ENV=production bundle exec rake assets:precompile`
   - `USER ekylibre`
   - **Ne pas** copier `unicorn.rb`/`puma.rb` ici (déjà dans `config/`).

4. **`docker/prod/docker-compose.yml`** — 5 services :
   - **`app`** : `build: docker/prod/Dockerfile`, `command: docker/prod/startup.sh`, healthcheck `curl -f http://localhost:3000/health || exit 1` (vérifier qu'un endpoint health existe — sinon route `/health` à créer ou `wget --spider http://localhost:3000/`), volumes `log:/app/log`, `uploads:/app/private`, `public-assets:/app/public`, `depends_on: { db: { condition: service_healthy }, redis }`.
   - **`sidekiq`** : même image, `command: docker/prod/sidekiq_startup.sh`, `restart: on-failure`.
   - **`caddy`** : `image: caddy:2-alpine`, ports `80:80`, `443:443`, volumes `./Caddyfile:/etc/caddy/Caddyfile:ro`, `caddy-data:/data`, `caddy-config:/config`, `public-assets:/srv/public:ro` (si on délègue les statics à Caddy — sinon retirer), `env_file: .env`, `depends_on: app`.
   - **`redis`** : `image: redis:7-alpine`, healthcheck `redis-cli ping`, volume `redis-data:/data` (optionnel mais recommandé).
   - **`db`** : `image: kartoza/postgis:13`, volumes `database-prod-volume:/var/lib/postgresql/data` + `../db/init.sql` + `../db/init-duke-role.sh`, **pas d'exposition de port hôte** (commenté), healthcheck `pg_isready`. Variables `DUKE_USER`/`DUKE_PASSWORD` passées au container (le script crée le rôle si elles sont non-vides).
   - **Pas** de service `certbot` (remplacé par Caddy).
   - **Services Duke (profile `duke`)** — voir Phase 4.5 pour le détail :
     - `duke-api` : `build: { context: ../../../duke, dockerfile: docker/Dockerfile, args: { INSTALL_STT: "${INSTALL_STT:-false}" } }`, `command: uvicorn duke.main:app --host 0.0.0.0 --port 8000`, healthcheck `/healthz`, volumes `whisper-cache:/home/duke/.cache/huggingface`, env Duke complète (DSN, clés LLM, etc.), `depends_on: { postgres-duke: healthy, db: healthy, app: started }`, réseaux `ekylibre` + `duke`.
     - `postgres-duke` : `postgres:16-alpine`, env `POSTGRES_USER/PASSWORD/DB` (DUKE_DB_*), volume `postgres-duke-data`, port NON exposé, healthcheck `pg_isready`.
   - **Services LLM local (profile `duke-llm-local`)** :
     - `ollama` : `ollama/ollama:latest`, port NON exposé, volume `ollama-models`, healthcheck `ollama list`.
     - `ollama-pull` : sidecar one-shot, pull `${OLLAMA_MODEL}` puis exit.

5. **`docker/prod/startup.sh`** — copie adaptée de `docker/startup.sh` :
   ```bash
   #!/usr/bin/env bash
   set -e

   # Generate SECRET_KEY_BASE if missing (idempotent first-run)
   if [ -z "$SECRET_KEY_BASE" ]; then
     echo "==GEN SECRET_KEY_BASE=="
     export SECRET_KEY_BASE=$(bundle exec rake secret)
     # Persist back to mounted .env? Non — ré-injecté au prochain up via .env.
     # Mieux : faire un fail-fast et demander à l'utilisateur de le générer.
   fi

   echo "==DB CREATE/MIGRATE=="
   bundle exec rake db:create db:migrate

   # Lexicon load — idempotent par version
   DB_URI="postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}/${DB_PROD_NAME}"
   LEXICON_LOADED=$(psql -qtAX -d "$DB_URI" -c "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name='lexicon');")
   if [ "$LEXICON_LOADED" = "f" ]; then
     echo "==LOAD LEXICON (premier démarrage — peut prendre 5-10 min)=="
     bundle exec rake lexicon:load
   else
     LOADED_VER=$(psql -qtAX -d "$DB_URI" -c "SELECT version FROM lexicon.version;")
     WANTED_VER=$(cat .lexicon-version)
     if [ "$LOADED_VER" != "$WANTED_VER" ]; then
       echo "==UPDATE LEXICON ($LOADED_VER → $WANTED_VER)=="
       bundle exec rake lexicon:load
     fi
   fi

   echo "==START PUMA=="
   exec bundle exec puma -C config/puma.rb -e production -b tcp://0.0.0.0:3000
   ```
   **Note** : la génération automatique de `SECRET_KEY_BASE` à chaque restart casserait toutes les sessions. **Décision** : si vide, **fail-fast** avec un message clair (`"Run: openssl rand -hex 64 and put it in .env"`).

6. **`docker/prod/sidekiq_startup.sh`** — minimal :
   ```bash
   #!/usr/bin/env bash
   set -e
   exec bundle exec sidekiq -C config/sidekiq.yml
   ```

7. **`docker/prod/scripts/tenant-init.sh`** — wrapper :
   ```bash
   #!/usr/bin/env bash
   set -e
   TENANT="${1:?Usage: tenant-init.sh <tenant_name> <email> <password>}"
   EMAIL="${2:?Email required}"
   PASSWORD="${3:?Password required}"
   docker compose -f docker/prod/docker-compose.yml exec -e TENANT="$TENANT" -e EMAIL="$EMAIL" -e PASSWORD="$PASSWORD" \
     app bundle exec rake tenant:init
   ```
   + `tenant-drop.sh`, `lexicon-reload.sh` sur le même modèle.

### Phase 2 — Vérifications de compatibilité (sans modifier le code)
**Durée** : 20 min.

1. Lancer un build à blanc : `docker compose -f docker/prod/docker-compose.yml build app` → vérifier `bundle install --without development test --deployment` réussit, et `assets:precompile` ne crashe pas.
2. Vérifier qu'un endpoint healthcheck est utilisable : grep `'/health'` dans `config/routes.rb`. Si absent, ajouter en phase 5 une route minimale `get '/health', to: ->(env) { [200, {}, ['ok']] }` **hors authentification et hors apartment middleware**.
3. Vérifier la présence de `config/puma.rb` ; sinon, le créer avec une config standard (`workers 2`, `threads 5,5`, `port 3000`).
4. S'assurer que `lib/tasks/tenant.rake` accepte bien les variables `TENANT`, `EMAIL`, `PASSWORD` (déjà documenté dans `CLAUDE.md`).
5. Confirmer que `RAILS_SERVE_STATIC_FILES` est honoré par `config/environments/production.rb:23` (déjà vérifié).

### Phase 3 — App server (Puma) et endpoint health
**Durée** : 15 min. À sauter si Unicorn est choisi.

1. Créer `config/puma.rb` si absent :
   ```ruby
   workers Integer(ENV.fetch('WEB_CONCURRENCY', 2))
   threads_count = Integer(ENV.fetch('RAILS_MAX_THREADS', 5))
   threads threads_count, threads_count
   preload_app!
   port ENV.fetch('PORT', 3000)
   environment ENV.fetch('RAILS_ENV', 'production')
   on_worker_boot { ActiveRecord::Base.establish_connection if defined?(ActiveRecord) }
   ```
2. Ajouter `gem 'puma', '~> 5.6'` dans `Gemfile` (group :production) **si pas déjà présent**.
3. Ajouter une route `/health` au-dessus de `config/routes.rb` pour bypasser l'authentification :
   ```ruby
   get '/health', to: proc { [200, { 'Content-Type' => 'text/plain' }, ['ok']] }
   ```
4. Bundle update : `bundle install` localement pour mettre à jour `Gemfile.lock`. **Attention** : `Gemfile.lock` est déjà modifié sur la branche → coordonner avec l'utilisateur (cf. `git status` : `M Gemfile.lock`).

### Phase 4 — TLS Caddy — variante HTTP-01 (par défaut) ou DNS-01
**Durée** : 30 min.

**Variante HTTP-01** (zéro config DNS) :
- Caddyfile tel que défini en phase 1.5.
- Limite : Let's Encrypt rate-limit = 50 certs/semaine par domaine racine. Suffisant pour < 50 tenants.

**Variante DNS-01 wildcard** (recommandée à grande échelle) :
- Image Caddy custom dans `docker/prod/Dockerfile.caddy` :
  ```dockerfile
  FROM caddy:2-builder-alpine AS builder
  RUN xcaddy build --with github.com/caddy-dns/cloudflare
  FROM caddy:2-alpine
  COPY --from=builder /usr/bin/caddy /usr/bin/caddy
  ```
- `docker-compose.yml` : `build: { dockerfile: Dockerfile.caddy }` pour le service caddy.
- Caddyfile :
  ```caddyfile
  *.{$HOST_DOMAIN_NAME} {
      tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
      }
      reverse_proxy app:3000
  }
  ```

→ Choix verrouillé en phase 0.

### Phase 4.5 — Intégration Duke (opt-in via profile Compose)
**Durée** : 30 min (image pré-buildée → pas de build local).

**Pré-requis** : aucun clone de repo nécessaire. L'image `ghcr.io/ekylibre/duke/duke-api:${DUKE_IMAGE_TAG:-latest}` doit être publique sur GHCR (ou les credentials Docker doivent être configurés via `docker login ghcr.io`). **À confirmer avec l'équipe Duke** que l'image est bien publiée et que `latest` est tagué sur une release stable.

**Architecture réseau** :

```
                            ┌─────────────────────── network: ekylibre (default) ──┐
                            │                                                       │
   [caddy] ─► duke.<domain> │ [duke-api] ──► [db] (PostGIS Ekylibre, duke_reader)   │
                            │       │   ──► [app:3000] (API Ekylibre)               │
                            │       │                                               │
                            │       └──► [postgres-duke] (DB privée Duke)           │
                            │                                                       │
                            │ [app], [sidekiq], [redis], [db], [caddy]              │
                            └───────────────────────────────────────────────────────┘
```

**Tous les services Duke vivent dans le réseau `default` du stack Compose** (nommé `ekylibre` via `networks.default.name`), exactement comme dans `docker/dev/docker-compose.yml:99-101`. C'est ce qui permet à `duke-api` de résoudre `db:5432`, `app:3000`, `postgres-duke:5432` par nom de service. Aucun réseau Docker séparé n'est créé pour Duke.

**Tâches** :

1. **`docker-compose.yml`** — ajouter services sous profile (pas de `build:`, juste `image:`) :
   ```yaml
   duke-api:
     profiles: ["duke"]
     image: ghcr.io/ekylibre/duke/duke-api:${DUKE_IMAGE_TAG:-latest}
     container_name: duke-api
     env_file: .env
     environment:
       # DSN explicites — référencent les noms de services Compose résolus
       # nativement sur le réseau partagé `ekylibre`.
       EKYLIBRE_API_BASE_URL: ${EKYLIBRE_API_BASE_URL:-http://app:3000}
       EKYLIBRE_DB_DSN: ${EKYLIBRE_DB_DSN}
       DUKE_DB_DSN: ${DUKE_DB_DSN}
       MIGRATE_ON_BOOT: "true"     # Alembic upgrade head au boot (idempotent)
     volumes:
       # Persiste le cache Whisper si DUKE_IMAGE_TAG=latest-stt
       - whisper-cache:/home/duke/.cache/huggingface
     depends_on:
       postgres-duke:
         condition: service_healthy
       db:
         condition: service_healthy
       app:
         condition: service_started
     restart: unless-stopped
     # Healthcheck déjà bakée dans l'image (curl /healthz) — pas besoin d'override.

   postgres-duke:
     profiles: ["duke"]
     image: postgres:16-alpine
     container_name: postgres-duke
     environment:
       POSTGRES_USER: ${DUKE_DB_USER}
       POSTGRES_PASSWORD: ${DUKE_DB_PASSWORD}
       POSTGRES_DB: ${DUKE_DB_NAME}
     volumes:
       - postgres-duke-data:/var/lib/postgresql/data
     restart: unless-stopped
     healthcheck:
       test: ["CMD-SHELL", "pg_isready -U ${DUKE_DB_USER} -d ${DUKE_DB_NAME}"]
       interval: 5s
       timeout: 3s
       retries: 10

   ollama:
     profiles: ["duke-llm-local"]
     image: ollama/ollama:latest
     container_name: ollama
     volumes:
       - ollama-models:/root/.ollama
     restart: unless-stopped
     healthcheck:
       test: ["CMD", "ollama", "list"]
       interval: 10s
       timeout: 5s
       retries: 10

   ollama-pull:
     profiles: ["duke-llm-local"]
     image: ollama/ollama:latest
     container_name: ollama-pull
     depends_on:
       ollama:
         condition: service_healthy
     environment:
       OLLAMA_HOST: http://ollama:11434
     entrypoint: ["ollama", "pull", "${OLLAMA_MODEL:-mistral-nemo}"]
     restart: "no"
   ```
   - Aucune clause `networks:` n'est nécessaire — par défaut tous les services rejoignent le réseau `default` (nommé `ekylibre`).
   - Aucune clause `build:` — image tirée depuis GHCR.
   - Volumes additionnels : `postgres-duke-data`, `whisper-cache`, `ollama-models`.

2. **`docker/prod/scripts/duke-up.sh`** — wrapper :
   ```bash
   #!/usr/bin/env bash
   set -e
   PROFILES=(--profile duke)
   if [ "${1:-}" = "--with-local-llm" ]; then
     PROFILES+=(--profile duke-llm-local)
   fi
   # Pull explicite (Compose ne pull pas toujours sur up si l'image existe déjà localement)
   docker compose -f docker/prod/docker-compose.yml "${PROFILES[@]}" pull
   docker compose -f docker/prod/docker-compose.yml "${PROFILES[@]}" up -d
   ```

3. **Mise à jour Duke** — wrapper `scripts/duke-update.sh` :
   ```bash
   #!/usr/bin/env bash
   set -e
   docker compose -f docker/prod/docker-compose.yml --profile duke pull duke-api
   docker compose -f docker/prod/docker-compose.yml --profile duke up -d --force-recreate duke-api
   ```

4. **Caddyfile** — bloc `duke.{$HOST_DOMAIN_NAME}` déjà inclus en phase 1.2. Si Duke n'est pas up, le sous-domaine renvoie 502 — comportement attendu et documenté.

5. **Init DB du rôle `duke_reader`** — `docker/db/init-duke-role.sh` s'exécute au premier `up` du service `db` et lit `DUKE_USER` / `DUKE_PASSWORD` depuis l'environnement. Vérifier que ces vars sont bien passées au container `db` dans `docker-compose.yml` (déjà fait en dev — répliquer).

6. **Sécurité opérationnelle Duke** :
   - `ALLOWED_WS_ORIGINS` : limiter aux domaines Ekylibre prod (`https://example.com,https://*.example.com`).
   - `HASH_SECRET` : obligatoire (audit log RGPD).
   - `LOG_VERBOSE_PAYLOADS=false` en prod.
   - Pas d'exposition du port `postgres-duke` sur l'hôte.

**Critère d'acceptation** : `docker compose -f docker/prod/docker-compose.yml --profile duke up -d` démarre `duke-api` + `postgres-duke` en plus du stack Ekylibre, **sans build** (juste un pull GHCR). `curl -I https://duke.example.com/healthz` → 200. `docker compose exec duke-api curl -sf http://db:5432` (refuse de proto HTTP mais établit la connexion TCP) confirme le partage réseau avec la DB Ekylibre. Sans le `--profile duke`, le stack Ekylibre démarre normalement et `duke.example.com` renvoie 502 (acceptable).

### Phase 5 — Documentation (`docker/prod/README.md`)
**Durée** : 30 min.

Structure cible (15 sections, modélée sur `docker/dev/README.md`) :

1. **Prérequis** — Docker Engine ≥ 24, Docker Compose v2, 4 vCPU, 8 GB RAM mini, ports 80/443 ouverts, nom de domaine pointant vers le serveur.
2. **Configurer `.env`** — `cp .env.dist .env`, éditer **uniquement** `HOST_DOMAIN_NAME`, `LETSENCRYPT_EMAIL`, `ADMIN_*`, `DB_PASSWORD`, `SECRET_KEY_BASE` (via `openssl rand -hex 64`).
3. **DNS** — créer un A-record `*.example.com → IP_serveur` (ou A + wildcard CNAME selon hébergeur).
4. **Build des images** — `docker compose -f docker/prod/docker-compose.yml build`.
5. **Premier démarrage** — `docker compose -f docker/prod/docker-compose.yml up -d`. Suivre les logs : `docker compose -f docker/prod/docker-compose.yml logs -f app`. Le premier démarrage déclenche `db:create`, `db:migrate`, `lexicon:load` (5-10 min) puis Puma.
6. **Vérifier le TLS** — `curl -I https://example.com/health` → 200. Caddy a négocié le cert Let's Encrypt automatiquement.
7. **Créer un premier tenant** — `./docker/prod/scripts/tenant-init.sh acme admin@acme.com 'MotDePasse!'` → accessible sur `https://acme.example.com`.
8. **Charger des données de démo** (optionnel) — `docker compose ... exec -e TENANT=acme app bundle exec rake first_run FOLDER=demo`.
9. **Mise à jour applicative** — `git pull && docker compose ... build && docker compose ... up -d`. Migrations exécutées au démarrage. Lexicon rechargé si `.lexicon-version` a changé.
10. **Backups** — section dédiée selon décision phase 0 :
    - Manuel : `docker compose ... exec db pg_dump -U ekylibre eky_production > backup_$(date +%F).sql`.
    - Automatique (si activé) : volume `db-backups`, rotation 7 jours.
10b. **Activer Duke (optionnel)** — section dédiée :
    1. Renseigner dans `.env` : `DUKE_USER`, `DUKE_PASSWORD`, `DUKE_DB_*`, `HASH_SECRET`, au moins une clé LLM, `ALLOWED_WS_ORIGINS`. Optionnel : `DUKE_IMAGE_TAG=latest-stt` pour activer Whisper STT.
    2. **Important** : si la stack Ekylibre tourne déjà, recréer le service `db` pour exécuter `init-duke-role.sh` avec les nouvelles vars (`docker compose ... up -d --force-recreate db`).
    3. Lancer Duke : `./docker/prod/scripts/duke-up.sh` (ou `--with-local-llm` pour Ollama).
       → Pull de l'image `ghcr.io/ekylibre/duke/duke-api:latest` depuis GHCR (aucun build local).
    4. Vérifier : `curl -I https://duke.example.com/healthz` → 200.
    5. Mise à jour Duke : `./docker/prod/scripts/duke-update.sh` (pull + recreate du container `duke-api`).
    6. Embarquer le widget Duke dans Ekylibre : voir documentation Duke.
11. **Logs** — `docker compose ... logs -f app sidekiq`. Logs persistés dans le volume `log`.
12. **Sécurité opérationnelle** — vérifier `ADMIN_PASSWORD` fort, ne pas exposer le port `db:5432`, mettre à jour mensuellement (`docker compose pull && up -d`).
13. **Troubleshooting** — TLS bloqué (vérifier DNS + ports 80/443), lexicon timeout (augmenter `start_period` du healthcheck), Sidekiq qui crashe (vérifier Redis).
14. **Désinstallation** — `docker compose ... down -v` (ATTENTION : `-v` supprime la DB).
15. **Variables d'environnement — référence** — tableau exhaustif (~30 vars).

### Phase 6 — Validation end-to-end
**Durée** : 30 min de tests.

Sur une VM cible (ou en local avec `HOST_DOMAIN_NAME=ekylibre.localhost` + override Caddy `tls internal`) :

1. `docker compose -f docker/prod/docker-compose.yml build` → succès.
2. `docker compose -f docker/prod/docker-compose.yml up -d` → tous services `healthy`.
3. Suivre `logs -f app` jusqu'à voir `==START PUMA==`.
4. `curl -I https://$HOST_DOMAIN_NAME/health` → 200.
5. `./scripts/tenant-init.sh test admin@test.com 'Test1234!'` → succès.
6. `curl -I https://test.$HOST_DOMAIN_NAME/` → 302 vers `/users/sign_in`.
7. Login via navigateur, naviguer 2-3 pages backend.
8. `docker compose ... down && docker compose ... up -d` → redémarrage sans relancer lexicon (vérification idempotence).
9. Vérifier que le port DB n'est pas exposé : `nc -zv $SERVER_IP 5431` → refusé.

### Phase 7 — Nettoyage et commit
**Durée** : 10 min.

1. Supprimer les anciens fichiers `docker/prod/` devenus obsolètes : `nginx.conf`, `unicorn.rb` (sauf décision Unicorn), `letsencrypt/`, `tenants.yml` (vide → inutile).
2. Vérifier `.gitignore` : `docker/prod/.env` doit être ignoré (probablement déjà couvert par un pattern générique `docker/**/.env`, à vérifier).
3. Commit séparé en 3 logical units :
   - `chore(docker/prod): retrait du stack nginx+certbot+unicorn obsolète`
   - `feat(docker/prod): nouvelle stack Caddy + Puma + scripts admin`
   - `docs(docker/prod): procédure de déploiement complète`

---

## 5. Dépendances entre phases

```
Phase 0 (décisions) ──► Phase 1 (squelette) ──► Phase 2 (compat) ──► Phase 3 (Puma+health) ──► Phase 4 (TLS)
                                                                                                     │
                                                                                                     ▼
                                                              Phase 4.5 (Duke) ──► Phase 5 (docs) ──► Phase 6 (test E2E) ──► Phase 7 (commit)
```

Phase 4.5 est **parallélisable** avec Phase 5 (la doc Duke peut être écrite en même temps que les services Duke sont configurés), mais doit terminer avant la validation E2E (Phase 6).

---

## 6. Risques & points d'attention

| Risque | Impact | Mitigation |
|---|---|---|
| Gem `unicorn` absent du Gemfile mais référencé par l'ancien `startup.sh` | App crashe au démarrage prod | Trancher Puma vs Unicorn en phase 0 ; si Unicorn → ajouter `gem 'unicorn'`. |
| `SECRET_KEY_BASE` régénéré à chaque restart | Sessions invalidées, logout massif | Fail-fast si vide, ne JAMAIS regénérer automatiquement. Doc explicite. |
| Let's Encrypt rate-limit (50 certs/semaine/domaine) | Création de tenants bloquée temporairement | Privilégier DNS-01 wildcard dès qu'on dépasse ~30 tenants prévus. |
| Lexicon load (5-10 min) timeout le healthcheck | Caddy renvoie 502 au premier démarrage | `start_period: 600s` sur le healthcheck `app` ; doc explicite "premier démarrage long". |
| Exposition du port 5432 héritée de l'ancien compose | Surface d'attaque inutile | Retirer `ports: 5431:5432` du service `db`. |
| Modification de `docker/startup.sh` (partagé) casse le dev | Régression locale | Dupliquer dans `docker/prod/startup.sh` pour découpler. |
| `Gemfile.lock` déjà `M` sur la branche courante | Risque de mélange de modifs hors-scope | Vérifier ce que contient le diff en cours avant phase 3, demander à l'utilisateur. |
| Image `ghcr.io/ekylibre/docker-base-images/ruby2.6:latest` non pinned | Reproducibilité des builds compromise | Pin sur un digest SHA explicite en phase 1.3. |
| Plugins (Gemfile.local) hébergés en SSH privé | Build prod échoue sans clé SSH | Soit baker les plugins dans une image custom, soit transmettre une clé deploy via BuildKit secret (`--secret id=ssh,src=$SSH_AUTH_SOCK`). À documenter. |
| Image `ghcr.io/ekylibre/duke/duke-api` non publique ou tag manquant | `docker compose pull` échoue (`unauthorized` ou `manifest unknown`) | **À vérifier avec l'équipe Duke avant la phase 4.5** : la visibilité du package GHCR (public ou nécessite `docker login`) et l'existence des tags `latest` / `latest-stt`. Si privé, documenter `docker login ghcr.io` avec un PAT en pré-requis. |
| Duke démarre avant que `duke_reader` existe | Connexion refusée (`role "duke_reader" does not exist`) | `depends_on: db: { condition: service_healthy }` ne garantit pas l'exécution complète de `init-duke-role.sh`. **Mitigation** : le code Duke gère déjà les retries asyncpg côté `init_db_pool` — vérifier. Sinon, healthcheck custom sur `db` qui vérifie l'existence du rôle (`SELECT 1 FROM pg_roles WHERE rolname='duke_reader'`). |
| `HASH_SECRET` non défini en prod | Duke démarre mais journal d'audit non hashé (violation RGPD) | Fail-fast côté Duke (`pydantic-settings` lève `ValidationError` si vide → uvicorn refuse de démarrer) ; doc README explicite. |
| Clés LLM exposées dans `.env` partagé Ekylibre + Duke | Surface d'exposition élargie | `.env` reste gitignored ; permissions `chmod 600`. Variante : `.env.duke` séparé chargé uniquement par `duke-api` via `env_file: [.env, .env.duke]`. **À envisager si scope sécurité critique**. |
| Tag `latest` mutable → drift entre releases | Mise à jour involontaire au prochain `pull` | Recommander dans la doc le pinning d'un tag versionné (`DUKE_IMAGE_TAG=v0.2.3`) pour les déploiements stables. `latest` réservé aux environnements de staging. |
| Ollama profile activé sans GPU | Inférence très lente sur CPU (`mistral-nemo` ~12B) | Documenter le besoin GPU dans le README. Pour les déploiements CPU, recommander Claude/Mistral API. |

---

## 7. Hors-scope explicite

- **CI/CD** (GitLab CI, GitHub Actions) : non demandé.
- **Monitoring/APM** (Scout, Skylight, Sentry) : variables prévues dans `.env.dist`, mais pas d'instanciation.
- **Haute dispo** (multi-node, load-balancer externe, DB répliquée) : single-host volontaire.
- **Migration depuis l'ancien `docker/prod/`** : pas de production existante connue à migrer ; si c'était le cas, un guide dédié serait nécessaire.

---

## 8. Critères d'acceptation

L'environnement est considéré comme livré quand, à partir d'un serveur Ubuntu 22.04 vierge avec Docker installé :

1. ✅ `cp docker/prod/.env.dist docker/prod/.env` puis 5 minutes d'édition suffisent (10 min si Duke activé).
2. ✅ `docker compose -f docker/prod/docker-compose.yml up -d` fait tout le reste, sans intervention manuelle (build, DB, lexicon, TLS, app).
3. ✅ Le premier tenant est créé en une commande : `./docker/prod/scripts/tenant-init.sh <nom> <email> <pwd>`.
4. ✅ Le `README.md` permet à un opérateur non-Ekylibre de tout faire seul, **y compris l'activation Duke**.
5. ✅ Un redémarrage (`down && up -d`) ne reload pas le lexicon ni ne perd les données.
6. ✅ TLS valide délivré par Let's Encrypt sur le domaine + sous-domaines (incluant `duke.<domaine>` si profile actif).
7. ✅ Aucun port DB exposé sur l'hôte (ni `db:5432`, ni `postgres-duke:5432`, ni `ollama:11434`).
8. ✅ Activation Duke en une commande : `./docker/prod/scripts/duke-up.sh` (ou `--with-local-llm`).
9. ✅ Sans `--profile duke`, le stack Ekylibre reste léger (5 services) — Duke n'impose rien aux déploiements qui n'en veulent pas.

---

## 9. Étape suivante

→ Lancer `/sc:implement` phase par phase, en commençant par la **Phase 0** (questions utilisateur). Ne pas implémenter en bloc — chaque phase produit des décisions qui peuvent influencer les suivantes (notamment Puma vs Unicorn, et HTTP-01 vs DNS-01).
