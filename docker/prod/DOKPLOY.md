# Déploiement Ekylibre via Dokploy

Guide pas-à-pas pour déployer Ekylibre sur un serveur géré par [Dokploy](https://dokploy.com/) (PaaS open-source basé sur Traefik).

Ce mode est une **alternative** au déploiement standalone documenté dans `README.md`. Choisir selon le contexte :

| Mode | Quand l'utiliser |
|---|---|
| **Standalone** (`docker-compose.yml`) | Une seule app sur le serveur, contrôle total, Caddy auto-TLS |
| **Dokploy** (`docker-compose.dokploy.yml`) | Plusieurs apps sur le serveur, UI de gestion, monitoring intégré, déploiement Git push-to-deploy |

---

## Prérequis

- Une instance Dokploy installée (`curl -sSL https://dokploy.com/install.sh | sh`)
- Un serveur Linux dédié, 4 vCPU / 8 GB RAM minimum
- Ports 80/443 ouverts vers Internet (gérés par Traefik)
- Un nom de domaine avec wildcard DNS pointant vers le serveur :
  ```
  example.com       A    <IP_serveur>
  *.example.com     A    <IP_serveur>
  ```

---

## 1. Créer le projet Dokploy

Dans l'UI Dokploy :

1. **Projects** → **Create Project** → nommer `ekylibre`
2. Dans le projet, **Create Service** → **Compose**
3. Nommer la compose app : `ekylibre-prod`

---

## 2. Configurer la source

Onglet **General** de la compose app :

- **Source Type** : `Git`
- **Repository URL** : `https://github.com/ekylibre/ekylibre.git`
- **Branch** : `main` (ou `5.0-beta` selon votre cible)
- **Compose Path** : `docker/prod/docker-compose.dokploy.yml`

Dokploy clonera le repo à chaque déploiement.

---

## 3. Renseigner les variables d'environnement

Onglet **Environment** de la compose app — coller le contenu adapté de `docker/prod/.env.dist` :

```dotenv
# === Application ===
RAILS_ENV=production
EKYLIBRE_IMAGE_TAG=latest
HOST_DOMAIN_NAME=example.com
ADMIN_USERNAME=admin
ADMIN_PASSWORD=<mot de passe fort>
SECRET_KEY_BASE=<openssl rand -hex 64>
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
WEB_CONCURRENCY=2
RAILS_MAX_THREADS=5

# === Database ===
DB_HOST=db
DB_PROD_NAME=eky_production
DB_USERNAME=ekylibre
DB_PASSWORD=<mot de passe fort>

# === Redis ===
REDIS_URL=redis://redis

# Pas de variable LETSENCRYPT_EMAIL ici — Traefik est déjà configuré côté Dokploy.

# === Duke (optionnel) ===
DUKE_IMAGE_TAG=latest
DUKE_USER=duke_reader
DUKE_PASSWORD=<mot de passe fort>
DUKE_DB_USER=duke
DUKE_DB_PASSWORD=<mot de passe fort>
DUKE_DB_NAME=duke
EKYLIBRE_API_BASE_URL=http://app:3000
EKYLIBRE_DB_DSN=postgresql://duke_reader:<pwd>@db:5432/eky_production
DUKE_DB_DSN=postgresql+asyncpg://duke:<pwd>@postgres-duke:5432/duke
HASH_SECRET=<openssl rand -hex 32>
ANTHROPIC_API_KEY=
MISTRAL_API_KEY=
ALLOWED_WS_ORIGINS=https://example.com,https://*.example.com
```

> Dokploy chiffre ces variables au repos. Pas besoin de fichier `.env` sur disque.

---

## 4. Configurer le TLS multi-tenant

Le compose `docker-compose.dokploy.yml` embarque des labels Traefik pour router :
- `Host(example.com)` → app (landing)
- `HostRegexp(^[a-z0-9-]+.example.com$)` → app (tenants)
- `Host(duke.example.com)` → duke-api (si profile `duke` activé)

Deux stratégies de cert TLS, à choisir selon l'échelle prévue.

### Option A — HTTP-01 par sous-domaine (recommandé < 30 tenants)

**Aucune configuration supplémentaire**. Le resolver `letsencrypt` est livré par défaut avec Dokploy. Chaque sous-domaine déclenche un challenge HTTP-01 au premier accès, Traefik issue un cert dédié.

⚠️ Limite Let's Encrypt : **50 certs/semaine/domaine racine**. Si vous créez beaucoup de tenants en lot, passer en Option B.

### Option B — DNS-01 wildcard (recommandé > 30 tenants)

Un seul cert `*.example.com` couvre tous les sous-domaines.

1. **Configurer un resolver DNS dans Traefik** (côté Dokploy, pas dans le compose) :

   Settings → Traefik → **Configuration** → ajouter au static `traefik.yml` :
   ```yaml
   certificatesResolvers:
     letsencrypt-dns:
       acme:
         email: admin@example.com
         storage: /etc/dokploy/traefik/dynamic/acme-dns.json
         dnsChallenge:
           provider: cloudflare      # ou ovh, gandi, route53, etc.
           resolvers:
             - "1.1.1.1:53"
             - "8.8.8.8:53"
   ```

2. **Ajouter le token DNS** dans les env vars Traefik (UI Dokploy → Settings → Traefik → Environment) :
   ```
   CF_DNS_API_TOKEN=<token Cloudflare avec scope Zone:DNS:Edit>
   ```

3. **Modifier les labels du service `app`** dans `docker-compose.dokploy.yml` :
   ```yaml
   # Remplacer "letsencrypt" par "letsencrypt-dns" + ajouter les domaines wildcard
   - "traefik.http.routers.ekylibre-tenants.tls.certresolver=letsencrypt-dns"
   - "traefik.http.routers.ekylibre-tenants.tls.domains[0].main=${HOST_DOMAIN_NAME}"
   - "traefik.http.routers.ekylibre-tenants.tls.domains[0].sans=*.${HOST_DOMAIN_NAME}"
   ```

4. Redeploy.

---

## 5. Déployer

Onglet **Deployments** → **Deploy**.

Dokploy va :
1. Cloner le repo depuis Git
2. Pull les images (`ghcr.io/ekylibre/ekylibre/app`, `kartoza/postgis:13`, etc.)
3. Créer les volumes
4. Démarrer les containers
5. Enregistrer les routes Traefik

**Premier démarrage** : ~10 min (lexicon load). Suivre les logs dans l'onglet **Logs** de l'app `ekylibre-prod`.

---

## 6. Créer un premier tenant

Onglet **Terminal** de la compose app → sélectionner le container `app` → :

```bash
TENANT=acme EMAIL=admin@acme.com PASSWORD='MotDePasseFort!' \
  bundle exec rake tenant:init
```

Accessible sur `https://acme.example.com` après quelques secondes (provisioning cert HTTP-01).

---

## 7. Activer Duke (optionnel)

Dans l'onglet **General** de la compose app, ajouter le profile :

- **Compose Profiles** : `duke` (ou `duke,duke-llm-local` pour activer Ollama)

Renseigner les vars Duke dans **Environment** (cf. §3). Redeploy.

Duke accessible sur `https://duke.example.com/healthz`.

---

## 8. Mise à jour

Push sur la branche tracking déclenche un redeploy auto si **Auto Deploy** est activé. Sinon, bouton **Redeploy** dans l'UI.

Pour pinner une version stable de l'image, changer `EKYLIBRE_IMAGE_TAG` dans **Environment** :
```
EKYLIBRE_IMAGE_TAG=v5.0.0
```

---

## 9. Backups

Dokploy propose des backups managés via **Settings** → **Backups**. Configurer :
- **Service** : `db` (PostgreSQL)
- **Schedule** : cron (ex: `0 3 * * *`)
- **Destination** : S3, MinIO, ou volume local

Pour Duke : ajouter un second backup pointant sur `postgres-duke`.

---

## 10. Différences vs déploiement standalone

| Élement | Standalone (`docker-compose.yml`) | Dokploy (`docker-compose.dokploy.yml`) |
|---|---|---|
| Reverse-proxy | Caddy (service interne) | Traefik (Dokploy core) |
| TLS | Caddy auto Let's Encrypt | Traefik auto Let's Encrypt |
| Ports publics | `80`, `443` exposés par `caddy` | Gérés par Traefik Dokploy |
| Network | `default` nommé `ekylibre` | `default` interne + `dokploy-network` external |
| Wildcard tenants | Caddy `*.domain` natif | Traefik `HostRegexp` (HTTP-01) ou DNS-01 |
| `.env` | Fichier sur disque | UI Dokploy (chiffré au repos) |
| Création tenant | `./scripts/tenant-init.sh` | Terminal Dokploy + `rake tenant:init` |
| Backups | Manuel ou cron | Géré par Dokploy |
| Monitoring | Aucun | Inclus (Logs, Stats, Healthchecks UI) |

---

## 11. Troubleshooting

### Le wildcard renvoie 404

- Vérifier que la regex Traefik correspond bien à votre domaine (échappement des `.` requis dans le compose : `\\.`)
- Tester avec un sous-domaine valide : `curl -I https://test.example.com`
- Logs Traefik : Settings → Traefik → Logs

### Cert non délivré (HTTP-01)

- Vérifier que les ports 80/443 sont ouverts et que le DNS résout correctement
- Limite LE atteinte ? Passer en Option B (DNS-01)

### Cert non délivré (DNS-01)

- Vérifier que `CF_DNS_API_TOKEN` est défini dans l'env Traefik (pas dans l'app)
- Vérifier les permissions du token (Cloudflare : Zone → DNS → Edit)

### App container redémarre en boucle

- Vérifier que `SECRET_KEY_BASE` est défini et non-vide
- Lexicon load timeout : healthcheck `start_period: 600s` devrait suffire

### Duke renvoie 502

- Vérifier que le profile `duke` est activé
- Vérifier que `HASH_SECRET` et au moins une clé LLM sont renseignés
- Logs : Terminal → sélectionner `duke-api`

### Sidekiq ne traite pas les jobs

- Vérifier que `redis` est healthy
- Logs Sidekiq dans l'UI

---

## 12. Références

- [Dokploy — Docs Docker Compose](https://docs.dokploy.com/docs/core/docker-compose)
- [Dokploy — Domains](https://docs.dokploy.com/docs/core/domains)
- [Dokploy — Wildcard SSL setup (DNS-01)](https://www.naps62.com/posts/wildcard-ssl-in-dokploy)
- [Traefik — HostRegexp matcher (v3)](https://doc.traefik.io/traefik/routing/routers/#rule)
