# Docker — Vue d'ensemble

Ce répertoire contient les configurations Docker pour les trois environnements d'Ekylibre.

---

## Environnements

### Développement (`dev/`)

Environnement local pour le développement. Le code source est monté en volume, les gems sont installées au démarrage.

**Services :** Rails (3000), Sidekiq, PostgreSQL/PostGIS (5431), Redis

```bash
docker compose -f docker/dev/docker-compose.yml up
```

→ [Documentation complète](dev/README.md)

---

### Test (`test/`)

Image de build pour la CI/CD (GitLab CI). Utilise le même `Dockerfile` que la production (`docker/prod/Dockerfile`), publiée sur le registry GitLab sous le tag `test-ci`.

**Services :** Rails, Sidekiq, PostgreSQL/PostGIS, Redis

```bash
docker compose -f docker/test/docker-compose.yml up
```

---

### Production (`prod/`)

Environnement de production avec Caddy (reverse-proxy) et certificats Let's Encrypt provisionnés à la volée (`on_demand_tls`).

**Services de base (toujours actifs) :** `app` (Rails Puma), `sidekiq`, `db` (PostgreSQL/PostGIS), `redis`, `caddy` (80/443).

**Services optionnels (activés via `--profile` Compose) :**

| Profile | Services | Rôle |
|---|---|---|
| `duke` | `duke-api`, `postgres-duke` | Assistant chatbot agricole |
| `duke-llm-local` (ou `ollama`) | `ollama`, `ollama-pull` | LLM local pour Duke (GPU recommandé) |
| `nanoclaw` | `nanoclaw` | Pont Telegram ↔ Duke (dépend de `duke`) |

Sans profile, `docker compose up -d` ne démarre que le stack de base — aucune image optionnelle n'est tirée.

```bash
# Stack de base
docker compose -f docker/prod/docker-compose.yml up -d

# + Duke
docker compose -f docker/prod/docker-compose.yml --profile duke up -d

# + Duke + NanoClaw
docker compose -f docker/prod/docker-compose.yml --profile duke --profile nanoclaw up -d
```

Variante Dokploy : `docker-compose.dokploy.yml` (sans Caddy exposé, routing via Traefik managé par Dokploy). Voir [`prod/DOKPLOY.md`](prod/DOKPLOY.md).

→ [Documentation complète](prod/README.md) — installation §1-5, services optionnels §10 (Duke) / §10c (NanoClaw).

---

## Comparatif

| | dev | test | prod |
|---|---|---|---|
| Image base | `ruby2.6` (GitLab) | `prod/Dockerfile` | `prod/Dockerfile` |
| Code source | Volume monté | Copié dans l'image | Copié dans l'image |
| Reverse-proxy | Non | Non | Caddy (80/443, TLS auto) |
| Port Rails | 3000 (host) | 3000 (host) | 3000 (interne, non exposé) |
| Port PostgreSQL | 5431 (host) | 5431 (host) | Non exposé (accès via `docker exec`) |
| Restart auto | Non | Non | `unless-stopped` |
| Services optionnels | — | — | Duke, NanoClaw, Ollama (profiles) |
