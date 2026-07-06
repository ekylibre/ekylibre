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
                ┌─ Host(example.com) ────────────────────────► app:3000       (UI Dokploy : cert LE HTTP-01)
Traefik :443 ───┤
                └─ HostSNIRegexp(^[a-z0-9-]+\.example\.com$) ─ TCP passthrough ──► Caddy :443
                                                                                  │ (termine TLS avec ses propres certs LE)
                                                                                  ├─► duke.example.com  → duke-api:8000
                                                                                  └─► *.example.com     → app:3000

Traefik :80 ──── HostRegexp(^[a-z0-9-]+\.example\.com$) ──── HTTP forward ──► Caddy :80 (fallback ACME HTTP-01)
```

**Pourquoi cette architecture** :
- Dokploy/Traefik gère **uniquement le domaine racine** via son UI (zero config Traefik supplémentaire)
- Pour les sous-domaines (HTTP wildcard non supporté par l'UI Dokploy + limitations cert wildcard HTTP-01), un **Caddy embarqué** dans le compose Ekylibre prend le relais
- Caddy provisionne automatiquement un cert LE par sous-domaine au premier accès (`on_demand_tls`)
- Aucune var DNS-01, aucun token API, aucune modif de `traefik.yml`

### 4.1 Points techniques à retenir (gotchas vécus)

| Point | Détail |
|---|---|
| **`HostSNIRegexp`, pas `HostSNI`** | `HostSNI(\`*.example.com\`)` est invalide en Traefik v3 (n'accepte que des hostnames littéraux ou `*` catch-all). Pour matcher un wildcard de sous-domaines en TCP, il faut `HostSNIRegexp(\`^[a-z0-9-]+\.example\.com$\`)`. Sinon le router est silencieusement rejeté. |
| **`traefik.docker.network=dokploy-network`** | Caddy est sur 2 réseaux (default + dokploy-network). Sans ce label explicite, Traefik peut router vers le mauvais réseau et ne pas trouver Caddy. |
| **Challenge ACME utilisé : TLS-ALPN-01** | Caddy choisit automatiquement TLS-ALPN-01 (port 443) plutôt que HTTP-01. Comme Traefik fait du TCP passthrough sur 443 vers Caddy, le challenge est résolu transparentement. Le label HTTP forward sur port 80 sert de filet de sécurité si TLS-ALPN-01 est refusé par LE. |
| **Filtre `on_demand_tls.ask`** | Caddy interroge `http://app:3000/health` avant chaque émission de cert. Bloque les bots qui taperaient des hostnames inexistants → protège contre le rate-limit LE. |

### 4.2 Configurer le domaine racine dans Dokploy UI

Onglet **Domains** de la compose app → bouton **Add Domain** :

| Champ | Valeur |
|---|---|
| Host | `example.com` |
| Service Name | `app` |
| Container Port | `3000` |
| HTTPS | ✅ |
| Certificate Provider | Let's Encrypt |
| Path | `/` |

⚠️ **NE PAS ajouter d'entrée pour les sous-domaines** (ni `duke.example.com`, ni `phaurigot.example.com`, etc.). Le `HostSNIRegexp` du compose va catcher tout ça et le router vers Caddy.

### 4.3 Sous-domaines (gérés automatiquement par Caddy)

Une fois la compose déployée, Caddy provisionne un cert LE au premier accès à chaque sous-domaine :

| URL | Comportement |
|---|---|
| `https://phaurigot.example.com/` (1er accès) | Caddy demande un cert via TLS-ALPN-01 → ~5-10s → cert valide → 302 /sign-in |
| `https://phaurigot.example.com/` (accès suivants) | Cert en cache local → réponse instantanée |
| `https://duke.example.com/` | Routé vers `duke-api:8000` (même mécanisme) |
| `https://acme.example.com/` (nouveau tenant) | Idem — aucune action manuelle requise |

### 4.4 Filtre anti-DoS sur le provisioning à la demande

Le `Caddyfile.dokploy` contient :

```caddyfile
on_demand_tls {
    ask http://app:3000/health
}
```

Caddy n'émet un cert que si l'app Rails répond 200 à `/health`. Suffit pour bloquer les bots qui taperaient des hostnames bidons.

**V2 (optionnel)** : remplacer `/health` par `/admin/tenants/exists?host={host}` qui validerait en DB que le sous-domaine correspond à un vrai tenant. Plus précis mais nécessite un endpoint Rails dédié.

### 4.5 Vérifications post-déploiement

```bash
# 1. Caddy a bien démarré et écoute 443
docker ps --filter "name=caddy-tls"
docker logs $(docker ps -qf "name=caddy-tls") 2>&1 | grep "serving initial configuration"

# 2. Traefik a chargé le TCP router (NE doit PAS retourner [])
docker exec dokploy-traefik wget -qO- http://localhost:8080/api/tcp/routers
# Attendu : objet avec rule="HostSNIRegexp(...)", status="enabled"

# 3. Cert présenté pour un tenant (au 1er hit, prendre ~10s puis revérifier)
curl -I https://<tenant>.example.com/
echo | openssl s_client -connect <tenant>.example.com:443 -servername <tenant>.example.com 2>/dev/null \
  | openssl x509 -noout -subject -issuer
# Attendu :
#   subject=CN = <tenant>.example.com
#   issuer=... Let's Encrypt

# 4. Caddy a obtenu le cert avec succès
docker logs $(docker ps -qf "name=caddy-tls") 2>&1 | grep -iE "certificate obtained" | tail -5

# 5. Lister les certs déjà obtenus
docker exec $(docker ps -qf "name=caddy-tls") \
  ls /data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/
```

### 4.6 Limites Let's Encrypt

- **50 certs/semaine/domaine racine** côté LE
- En cas de dépassement (cas extrême : > 50 nouveaux tenants/semaine), basculer vers DNS-01 wildcard. Procédure complexe (requires un token API DNS) — voir [Wildcard SSL Dokploy](https://www.naps62.com/posts/wildcard-ssl-in-dokploy).

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

## 7. Activer Duke / Ollama / NanoClaw (optionnel)

Sans profile, seul le stack de base (`app`, `sidekiq`, `caddy-tls`, `db`, `redis`) est démarré.

Dans l'onglet **General** de la compose app, saisir la liste des profiles à activer dans **Compose Profiles** :

| Besoin | Profiles à cocher |
|---|---|
| Duke (LLM cloud : Anthropic/Mistral) | `duke` |
| Duke + LLM local Ollama | `duke,duke-llm-local` |
| Duke + NanoClaw (bot Telegram) | `duke,nanoclaw` |
| Tout | `duke,duke-llm-local,nanoclaw` |

> NanoClaw dépend de Duke — activer `nanoclaw` sans `duke` échoue au boot (WS `duke-api` inaccessible).

Renseigner les vars correspondantes dans **Environment** (Duke : cf. §3 ; NanoClaw : `ANTHROPIC_AUTH_TOKEN`, `ONECLI_API_KEY`, `NANOCLAW_TENANTS_PATH`). Redeploy.

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
| Reverse-proxy | Caddy unique (service interne) | Traefik Dokploy + Caddy intermédiaire (TCP passthrough) |
| TLS racine | Caddy auto LE (HTTP-01) | Traefik auto LE via UI Dokploy |
| TLS sous-domaines | Caddy `*.domain` natif + `on_demand_tls` | Caddy embarqué (idem standalone) + Traefik TCP passthrough `HostSNIRegexp` |
| Challenge ACME | HTTP-01 (port 80) | TLS-ALPN-01 (port 443, via passthrough) |
| Ports publics | `80`, `443` exposés par Caddy | Gérés par Traefik Dokploy |
| Network | `default` nommé `ekylibre` | `default` interne + `dokploy-network` external |
| `.env` | Fichier sur disque | UI Dokploy (chiffré au repos) |
| Création tenant | `./scripts/tenant-init.sh` | Terminal Dokploy + `rake tenant:init` |
| Backups | Manuel ou cron | Géré par Dokploy |
| Monitoring | Aucun | Inclus (Logs, Stats, Healthchecks UI) |

> **Note** : la logique Caddy (`on_demand_tls`, `ask`, routing tenants/duke) est **identique** dans les deux modes. Seul le contexte d'écoute change : exposition directe en standalone, derrière Traefik en mode Dokploy.

---

## 11. Troubleshooting

### Sous-domaine renvoie `TRAEFIK DEFAULT CERT` au lieu du cert Let's Encrypt

C'est le symptôme principal d'un problème de routing entre Traefik et Caddy. Diagnostic par étapes :

**1. Vérifier que Traefik a chargé le TCP router** :
```bash
docker exec dokploy-traefik wget -qO- http://localhost:8080/api/tcp/routers
# Si retourne `[]` : le label TCP n'a pas été pris en compte
# Si retourne l'objet avec status="enabled" : le router est OK, problème ailleurs
```

**2. Si TCP routers vide** : la rule TCP est probablement invalide. Vérifier que le compose utilise bien `HostSNIRegexp` (et NON `HostSNI` qui ne supporte pas les wildcards partiels) :
```bash
docker inspect $(docker ps -qf "name=caddy-tls") --format '{{json .Config.Labels}}' \
  | jq -r 'to_entries[] | select(.key | contains("ekylibre-tls-pass.rule")) | .value'
# Attendu : HostSNIRegexp(`^[a-z0-9-]+\.example.com$`)
# Si HostSNI(...) → push le fix HostSNIRegexp + redeploy
```

**3. Si TCP router OK mais Caddy ne reçoit pas de trafic** : `traefik.docker.network` manquant. Caddy est sur 2 réseaux, Traefik doit savoir lequel utiliser :
```bash
docker inspect $(docker ps -qf "name=caddy-tls") --format '{{json .Config.Labels}}' \
  | jq -r 'to_entries[] | select(.key == "traefik.docker.network") | .value'
# Attendu : dokploy-network
```

**4. Si tout est OK** : c'est probablement juste un cache TLS. Refaire le test 30s après le premier hit.

### Caddy ne provisionne pas de cert (logs Caddy montrent erreur ACME)

Si tu vois `error solving challenge` ou `failed to obtain certificate` dans les logs Caddy :

```bash
docker logs $(docker ps -qf "name=caddy-tls") 2>&1 | grep -iE "obtain|challenge|error" | tail -20
```

Causes possibles :
- **`ask` endpoint inaccessible** : Caddy ne peut pas joindre `app:3000/health`. Vérifier qu'app est `healthy` et que les deux containers sont sur le même réseau interne :
  ```bash
  docker exec $(docker ps -qf "name=caddy-tls") wget -O- http://app:3000/health
  ```
- **Rate-limit LE atteint** : 50 certs/semaine/domaine racine. Attendre ou basculer en DNS-01 wildcard.
- **DNS pas propagé** : le sous-domaine doit résoudre vers l'IP du serveur. Si tu crées un tenant à la volée, vérifier que le wildcard DNS est bien configuré.

### Rate-limit LE atteint

Si tu vois `urn:ietf:params:acme:error:rateLimited` dans les logs Caddy, tu as dépassé les 50 certs/semaine. Solutions :
1. Attendre que la fenêtre glissante de 7 jours libère du quota
2. Basculer vers DNS-01 wildcard (un seul cert couvre tout) — voir [doc Traefik DNS-01](https://doc.traefik.io/traefik/https/acme/#dnschallenge)
3. Renforcer le filtre `on_demand_tls.ask` (cf. §4.4 V2) pour éviter les requêtes de tenants inexistants

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
