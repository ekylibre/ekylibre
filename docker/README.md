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

Environnement de production avec Nginx et certificats Let's Encrypt (Certbot).

**Services :** Rails, Sidekiq, PostgreSQL/PostGIS, Redis, Nginx (80/443), Certbot

```bash
docker compose -f docker/prod/docker-compose.yml up -d
```

→ [Documentation complète](prod/README.md)

---

## Comparatif

| | dev | test | prod |
|---|---|---|---|
| Image base | `ruby2.6` (GitLab) | `prod/Dockerfile` | `prod/Dockerfile` |
| Code source | Volume monté | Copié dans l'image | Copié dans l'image |
| Nginx | Non | Non | Oui |
| SSL / Certbot | Non | Non | Oui |
| Port Rails | 3000 | 3000 | 80 / 443 |
| Port PostgreSQL | 5431 | 5431 | 5431 |
| Restart auto | Non | Non | Oui |
