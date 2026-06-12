# Docker — Environnement de production

Déploiement Ekylibre en production sur un serveur unique avec HTTPS automatique (Let's Encrypt) et option d'activer l'assistant chatbot Duke.

## Prérequis

- Docker Engine ≥ 24 et Docker Compose v2
- Serveur Linux (Ubuntu 22.04+ recommandé), 4 vCPU, 8 GB RAM minimum
- Ports `80` et `443` ouverts vers Internet (challenge HTTP-01 Let's Encrypt)
- Un nom de domaine avec un wildcard DNS pointant vers le serveur :
  ```
  example.com       A    <IP_serveur>
  *.example.com     A    <IP_serveur>
  ```

---

## 1. Configurer le fichier `.env`

```bash
cp docker/prod/.env.dist docker/prod/.env
```

Éditer `docker/prod/.env` et renseigner au minimum :

| Variable | Description |
|---|---|
| `HOST_DOMAIN_NAME` | Nom de domaine (sans protocole ni sous-domaine), ex: `ekylibre.example.com` |
| `LETSENCRYPT_EMAIL` | Email pour les notifications Let's Encrypt |
| `SECRET_KEY_BASE` | À générer : `openssl rand -hex 64` |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | Accès HTTP Basic à `/admin` |
| `DB_PASSWORD` | Mot de passe PostgreSQL fort |

> **Sécurité** : `chmod 600 docker/prod/.env` après édition. Ce fichier contient des secrets et est gitignored.

---

## 2. Récupérer les images

L'image Ekylibre est publiée automatiquement sur GHCR par le workflow `.github/workflows/build-prod-image.yml` à chaque push sur `main` ou `5.0-beta`. Aucun build local n'est nécessaire en production.

```bash
docker compose -f docker/prod/docker-compose.yml pull
```

Les images tirées :
- `ghcr.io/ekylibre/ekylibre/app:latest` (Rails + Sidekiq, image partagée)
- `caddy:2-alpine` (reverse-proxy)
- `kartoza/postgis:13` (PostgreSQL)
- `redis:7-alpine`

> Pour pinner une version stable, éditer `EKYLIBRE_IMAGE_TAG` dans `.env` (ex: `EKYLIBRE_IMAGE_TAG=v5.0.0`).

> **Plugins inclus** : l'image GHCR embarque les plugins publics listés dans `docker/prod/Gemfile.prod` (banking, qonto, baqio, ednotif, planning, samsys, traccar, weenat, sencrop, hve, idea, hajimari, viti, etc.). Pour ajouter / retirer un plugin, éditer ce fichier et déclencher un nouveau build.
>
> **Plugins privés ou path-local** : si votre déploiement nécessite des plugins non-publics, builder localement :
> ```bash
> docker build -f docker/prod/Dockerfile -t ghcr.io/ekylibre/ekylibre/app:local .
> EKYLIBRE_IMAGE_TAG=local docker compose -f docker/prod/docker-compose.yml up -d
> ```
> Pour ce cas, adapter `docker/prod/Dockerfile` (retirer le `rm -f Gemfile.local`) et ajouter votre `Gemfile.local`.

---

## 3. Premier démarrage

```bash
docker compose -f docker/prod/docker-compose.yml up -d
```

Suivre les logs du service `app` :

```bash
docker compose -f docker/prod/docker-compose.yml logs -f app
```

Au premier démarrage, le container `app` :

1. Crée la base de données (`db:create`)
2. Lance les migrations (`db:migrate`)
3. **Charge le lexicon** (`lexicon:load`) — cette étape prend **5 à 10 minutes**
4. Démarre Puma sur le port 3000

Attendre le message `==START PUMA==` avant de tester.

Caddy provisionne les certificats Let's Encrypt automatiquement au premier accès HTTPS sur le domaine.

---

## 4. Vérifier le déploiement

```bash
# Healthcheck applicatif
curl -I https://example.com/health
# → HTTP/2 200

# Page de connexion
curl -I https://example.com/
# → HTTP/2 302 (redirection vers /users/sign_in)
```

---

## 5. Créer un premier tenant

```bash
./docker/prod/scripts/tenant-init.sh acme admin@acme.com 'MotDePasseFort!'
```

Le tenant est accessible sur `https://acme.example.com` après quelques secondes (provisioning du cert TLS).

Charger des données de démo (optionnel) :

```bash
docker compose -f docker/prod/docker-compose.yml exec -e TENANT=acme app bundle exec rake first_run FOLDER=demo
```

---

## 6. Services et architecture

| Service | Image | Rôle |
|---|---|---|
| `app` | `ghcr.io/ekylibre/ekylibre/app:latest` | Serveur Rails (Puma), port 3000 interne |
| `sidekiq` | `ghcr.io/ekylibre/ekylibre/app:latest` | Worker de jobs (même image, command différente) |
| `caddy` | `caddy:2-alpine` | Reverse-proxy HTTPS, ports 80/443 publics |
| `db` | `kartoza/postgis:13` | PostgreSQL + PostGIS, port NON exposé |
| `redis` | `redis:7-alpine` | Cache + Sidekiq, port NON exposé |

Services optionnels (Duke, voir §11) :

| Service | Image | Profile |
|---|---|---|
| `duke-api` | `ghcr.io/ekylibre/duke/duke-api:latest` | `duke` |
| `postgres-duke` | `postgres:16-alpine` | `duke` |
| `ollama` | `ollama/ollama:latest` | `duke-llm-local` |
| `ollama-pull` | `ollama/ollama:latest` | `duke-llm-local` |

Aucun port DB n'est exposé sur l'hôte. Pour un accès direct à la DB depuis le serveur :

```bash
docker compose -f docker/prod/docker-compose.yml exec db psql -U ekylibre eky_production
```

---

## 7. Commandes utiles

```bash
# Arrêter
docker compose -f docker/prod/docker-compose.yml down

# Logs
docker compose -f docker/prod/docker-compose.yml logs -f app sidekiq

# Shell dans le container
docker compose -f docker/prod/docker-compose.yml exec app bash

# Console Rails
docker compose -f docker/prod/docker-compose.yml exec app bundle exec rails c
```

---

## 8. Mise à jour applicative

```bash
docker compose -f docker/prod/docker-compose.yml pull
docker compose -f docker/prod/docker-compose.yml up -d
```

L'image est tirée depuis GHCR (mise à jour automatique du tag `latest` à chaque merge sur `main`). Les migrations sont rejouées automatiquement par `startup.sh`. Le lexicon n'est rechargé que si `.lexicon-version` a changé.

Pour pinner une version stable, éditer `EKYLIBRE_IMAGE_TAG` dans `.env` (ex: `EKYLIBRE_IMAGE_TAG=v5.0.0`).

---

## 9. Backups PostgreSQL

Backup manuel :

```bash
docker compose -f docker/prod/docker-compose.yml exec db \
  pg_dump -U ekylibre eky_production > backup_$(date +%F).sql
```

Automatiser via cron sur l'hôte (exemple — backup quotidien, rotation 7 jours) :

```cron
0 3 * * * cd /path/to/ekylibre && docker compose -f docker/prod/docker-compose.yml exec -T db pg_dump -U ekylibre eky_production > backups/db_$(date +\%F).sql && find backups -name 'db_*.sql' -mtime +7 -delete
```

Restauration :

```bash
docker compose -f docker/prod/docker-compose.yml exec -T db psql -U ekylibre eky_production < backup_2026-06-12.sql
```

---

## 10. Activer Duke (assistant chatbot) — OPTIONNEL

Duke est un assistant chatbot agricole packagé en image publique GHCR. Activation en 3 étapes.

### a. Configurer les variables Duke dans `.env`

```bash
# Image (laisser sur 'latest' pour les MAJ auto, ou pinner sur une version)
DUKE_IMAGE_TAG=latest

# Rôle PostgreSQL lecture seule
DUKE_USER=duke_reader
DUKE_PASSWORD=<mot de passe fort>

# Base Duke (Postgres 16 dédié)
DUKE_DB_USER=duke
DUKE_DB_PASSWORD=<mot de passe fort>
DUKE_DB_NAME=duke

# DSN — répliquer les mots de passe ci-dessus
EKYLIBRE_DB_DSN=postgresql://duke_reader:<pwd>@db:5432/eky_production
DUKE_DB_DSN=postgresql+asyncpg://duke:<pwd>@postgres-duke:5432/duke

# Audit RGPD — OBLIGATOIRE
HASH_SECRET=<openssl rand -hex 32>

# Au moins une clé LLM
ANTHROPIC_API_KEY=sk-ant-...
# ou
MISTRAL_API_KEY=...

# Sécurité WebSocket
ALLOWED_WS_ORIGINS=https://example.com,https://*.example.com
```

### b. Recréer le service `db` pour activer le rôle `duke_reader`

Si le stack Ekylibre tourne déjà, les variables `DUKE_USER`/`DUKE_PASSWORD` n'ont pas été lues. Recréer le service `db` :

```bash
docker compose -f docker/prod/docker-compose.yml up -d --force-recreate db
```

> **Note** : le script `docker/db/init-duke-role.sh` ne s'exécute qu'au premier démarrage du volume. Si le rôle n'existe pas, le créer manuellement :
> ```bash
> docker compose -f docker/prod/docker-compose.yml exec db \
>   psql -U ekylibre eky_production -c "CREATE ROLE duke_reader LOGIN PASSWORD '<pwd>'; GRANT CONNECT ON DATABASE eky_production TO duke_reader; GRANT USAGE ON SCHEMA public, postgis, lexicon TO duke_reader; GRANT SELECT ON ALL TABLES IN SCHEMA public, postgis, lexicon TO duke_reader;"
> ```

### c. Démarrer Duke

```bash
./docker/prod/scripts/duke-up.sh
```

Pull l'image `ghcr.io/ekylibre/duke/duke-api:latest` depuis GHCR et démarre `duke-api` + `postgres-duke`.

Avec un LLM local (Ollama) :

```bash
./docker/prod/scripts/duke-up.sh --with-local-llm
```

> Ollama avec `mistral-nemo` (12B) est très lent sur CPU. Recommandé uniquement sur serveurs avec GPU NVIDIA + NVIDIA Container Toolkit installé.

### d. Vérifier

```bash
curl -I https://duke.example.com/healthz
# → HTTP/2 200
```

### e. Mise à jour de Duke

```bash
./docker/prod/scripts/duke-update.sh
```

Pull la dernière image et recreate le container `duke-api`.

### f. Arrêter Duke (sans toucher au stack Ekylibre)

```bash
docker compose -f docker/prod/docker-compose.yml --profile duke down
```

---

## 11. Sécurité opérationnelle

- `chmod 600 docker/prod/.env` après chaque édition
- `ADMIN_PASSWORD` et `DB_PASSWORD` : 20+ caractères, générés
- Vérifier que les ports `5432`, `6379`, `11434` ne sont **pas** exposés sur l'hôte (`netstat -tln`)
- Mises à jour mensuelles minimum :
  ```bash
  docker compose -f docker/prod/docker-compose.yml pull && \
  docker compose -f docker/prod/docker-compose.yml up -d
  ```
- Surveiller les logs : `docker compose ... logs --tail=100 -f`
- Backup régulier de la DB et des volumes `uploads`, `caddy-data` (certificats)

---

## 12. Résolution de problèmes

### `Caddy: failed to provision certificate`

- Vérifier que les ports 80/443 sont ouverts depuis Internet
- Vérifier la résolution DNS du domaine et du wildcard : `dig +short example.com` et `dig +short test.example.com`
- Let's Encrypt rate-limit : 50 certs/semaine/domaine. Pour > 30 tenants, envisager le mode DNS-01 wildcard (voir documentation Caddy).

### Lexicon n'est pas chargé

```bash
./docker/prod/scripts/lexicon-reload.sh
```

### `SECRET_KEY_BASE is empty` au démarrage

Générer un secret et l'ajouter au `.env` :

```bash
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" >> docker/prod/.env
```

### Duke renvoie 502

- Vérifier que le profile est actif : `docker compose -f docker/prod/docker-compose.yml ps`
- Logs Duke : `docker compose -f docker/prod/docker-compose.yml --profile duke logs -f duke-api`
- Vérifier `HASH_SECRET` non-vide et au moins une clé LLM renseignée

### App container redémarre en boucle

Le healthcheck a `start_period: 600s` (10 min) pour laisser le temps au lexicon de charger. Si l'app redémarre quand même, vérifier que la DB est joignable :

```bash
docker compose -f docker/prod/docker-compose.yml exec db pg_isready -U ekylibre
```

---

## 13. Désinstallation

```bash
# Arrêter tous les services (y compris Duke)
docker compose -f docker/prod/docker-compose.yml --profile duke --profile duke-llm-local down

# Supprimer les volumes (ATTENTION : perte de données irréversible)
docker compose -f docker/prod/docker-compose.yml down -v
```

---

## 14. Référence — variables `.env`

Voir `docker/prod/.env.dist` pour la liste exhaustive avec valeurs par défaut commentées.

Variables groupées en sections :
- Application (`RAILS_ENV`, `HOST_DOMAIN_NAME`, `ADMIN_*`, `SECRET_KEY_BASE`, Puma tuning)
- Database (`DB_*`)
- Redis (`REDIS_URL`)
- TLS (`LETSENCRYPT_EMAIL`)
- Object storage (`MINIO_*`, optionnel)
- Observability (`ELASTIC_APM_ACTIVE`, optionnel)
- Duke (`DUKE_*`, `EKYLIBRE_DB_DSN`, `HASH_SECRET`, clés LLM, `OLLAMA_*`)
