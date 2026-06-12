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

### Configuration sysctl du serveur

À faire **une fois** sur l'hôte avant le premier déploiement (en SSH root) :

```bash
# vm.overcommit_memory=1 : recommandé par Redis pour eviter les echecs de BGSAVE
# sous pression memoire. Sans, Redis logue "WARNING Memory overcommit must be enabled".
echo "vm.overcommit_memory = 1" > /etc/sysctl.d/99-redis-overcommit.conf
sysctl --system

# Verification
sysctl vm.overcommit_memory
# vm.overcommit_memory = 1
```

Non-bloquant : Redis fonctionne sans, mais le warning persiste dans les logs et un BGSAVE peut échouer en cas de forte pression mémoire (rare avec 8 GB RAM et Redis < 100 MB).

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

## 4. Architecture du routing et des certificats

Le compose Dokploy utilise une **architecture à 2 couches** pour ne pas avoir à modifier Dokploy/Traefik :

```
                ┌─ Host(example.com) ──────────► app:3000       (UI Dokploy : cert LE)
Traefik :443 ───┤
                └─ HostSNI(*.example.com) ─TCP passthrough─► Caddy :443
                                                              │ (termine TLS avec ses propres certs LE)
                                                              ├─► duke.example.com  → duke-api:8000
                                                              └─► *.example.com     → app:3000

Traefik :80 ─── HostRegexp(*.example.com) ─HTTP forward─► Caddy :80 (challenge ACME)
```

**Pourquoi cette architecture** :
- Dokploy/Traefik gère uniquement le domaine racine via son UI (zero config Traefik supplémentaire)
- Pour les sous-domaines (`HostRegexp` non supporté par l'UI Dokploy + limitations cert wildcard HTTP-01), un **Caddy embarqué** dans le compose Ekylibre prend le relais
- Caddy provisionne automatiquement un cert LE par sous-domaine (`on_demand_tls`)
- Aucune var DNS-01, aucun token API, aucune modif de `traefik.yml`

### 4.1 Configurer le domaine racine dans Dokploy UI

Onglet **Domains** de la compose app → bouton **Add Domain** :

| Champ | Valeur |
|---|---|
| Host | `example.com` |
| Service Name | `app` |
| Container Port | `3000` |
| HTTPS | ✅ |
| Certificate Provider | Let's Encrypt |
| Path | `/` |

⚠️ **NE PAS ajouter d'entrée pour les sous-domaines** (ni `duke.example.com`, ni `phaurigot.example.com`, etc.). Le `HostSNI(*.example.com)` du compose va catcher tout ça et le router vers Caddy.

### 4.2 Sous-domaines (gérés automatiquement par Caddy)

Une fois la compose déployée, Caddy provisionne un cert LE au premier accès à chaque sous-domaine :

| URL | Comportement |
|---|---|
| `https://phaurigot.example.com/` (1er accès) | Caddy demande un cert HTTP-01 à LE → délai ~10-30s → cert valide → 302 sign-in |
| `https://phaurigot.example.com/` (accès suivants) | Cert cache → réponse instantanée |
| `https://duke.example.com/` | Idem, routé vers `duke-api:8000` |

### 4.3 Filtre anti-DoS sur le provisioning à la demande

Le Caddyfile contient :
```caddyfile
on_demand_tls {
    ask http://app:3000/health
}
```

Caddy n'émettra de cert que si l'app Rails répond à `/health`. Ce filtre est minimal mais suffit à bloquer les bots qui taperaient des hostnames bidons (rate-limit LE = 50 certs/semaine/domaine racine).

**V2 (optionnel)** : remplacer `/health` par un endpoint type `/admin/tenants/exists?host={host}` qui valide que le sous-domaine correspond à un vrai tenant en DB.

### 4.4 Limites Let's Encrypt

- **50 certs/semaine/domaine racine** côté LE staging
- En cas de dépassement, basculer vers une stratégie DNS-01 wildcard (un seul cert pour tous). Demande l'ajout d'un resolver DNS-01 dans Traefik côté Dokploy (procédure dans la doc Traefik).

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

### Redis : `WARNING Memory overcommit must be enabled`

Non-bloquant. Fix permanente sur l'hôte :
```bash
echo "vm.overcommit_memory = 1" > /etc/sysctl.d/99-redis-overcommit.conf
sysctl --system
```
Voir section "Prérequis" → "Configuration sysctl du serveur".

### Sidekiq ne traite pas les jobs

- Vérifier que `redis` est healthy
- Logs Sidekiq dans l'UI

---

## 12. Références

- [Dokploy — Docs Docker Compose](https://docs.dokploy.com/docs/core/docker-compose)
- [Dokploy — Domains](https://docs.dokploy.com/docs/core/domains)
- [Dokploy — Wildcard SSL setup (DNS-01)](https://www.naps62.com/posts/wildcard-ssl-in-dokploy)
- [Traefik — HostRegexp matcher (v3)](https://doc.traefik.io/traefik/routing/routers/#rule)
