# Docker — Environnement de développement

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) et Docker Compose v2
- Accès au registry GitLab Ekylibre (`registry.gitlab.com`)
- Un Personal Access Token GitLab avec le scope `read_registry`

---

## 1. Authentification au registry GitLab

L'image de base est hébergée sur le registry privé GitLab :

```bash
docker login registry.gitlab.com -u <votre-username-gitlab> -p <votre-token>
```

---

## 2. Configurer le fichier `.env` et ajouter dnsmasq

Copier le fichier de configuration d'exemple :

```bash
cp docker/dev/.env.dist docker/dev/.env
```

Puis éditer `docker/dev/.env` et renseigner au minimum :

| Variable | Description |
|---|---|
| `RAILS_ENV` | Laisser à `development` |
| `DB_USERNAME` / `DB_PASSWORD` | Identifiants PostgreSQL |
| `REDIS_URL` | Doit valoir `redis://redis` |
| `UID` / `GID` | UID et GID de votre utilisateur hôte (`id` pour les connaître) |
| `GITLAB_REGISTRY_USER` | Votre username GitLab |
| `GITLAB_REGISTRY_TOKEN` | Personal Access Token GitLab (`read_registry`) |

> **Important :** si votre UID/GID n'est pas `1000`, il faut impérativement définir `UID` et `GID` dans le `.env` afin que le container puisse écrire dans le répertoire monté.

Ajouter la configuration pour dnsmasq (éviter de modifier le fichier host pour chaque tenant)
si vous avez changé la variable HOST_DOMAIN_NAME=ekylibre.lan, modifier votre doamine également dans la commande ci-dessous. 

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/ekylibre.conf << 'EOF'
[Resolve]
DNS=127.0.0.2
Domains=~ekylibre.lan
EOF
sudo systemctl restart systemd-resolved
```

---

## 3. Builder les images

Depuis la racine du projet :

```bash
docker compose -f docker/dev/docker-compose.yml build
```

Le premier build est long car il télécharge l'image de base Ruby depuis le registry GitLab.

---

## 4. Lancer l'environnement

```bash
docker compose -f docker/dev/docker-compose.yml up
```

A. Au **premier démarrage**, le container `app` va automatiquement :

1. Installer les gems (`bundle install`)
2. Installer les packages JS (`yarn install`)
3. Créer et migrer la base de données (`db:create`, `db:migrate`)
4. Charger le lexicon (`lexicon:load`) mentionné dans le fichier .lexicon-version — cette étape peut prendre plusieurs minutes
5. Démarrer le serveur Rails sur le port `3000`

L'interface d'administration est accessible sur [http://localhost:3000/admin](http://localhost:3000/admin).

En ligne de commande, vous pouvez également

Charger le lexicon

```bash
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake lexicon:load
```

Charger les données de démonstration

```bash
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake first_run
```

---

## 5. Services disponibles

| Service | Port hôte | Description |
|---|---|---|
| `app` | `3000` | Serveur Rails |
| `app` | `8808` | Rack Mini Profiler |
| `db` | `5431` | PostgreSQL 13 (PostGIS) |
| `redis` | — | Redis 7 (interne) |
| `sidekiq` | — | Worker de jobs en arrière-plan |
| `dnsmasq` | `5353/udp` | DNS wildcard `*.ekylibre.lan → 127.0.0.1` |
| `dnsmasq` | `5380` | Interface web dnsmasq (admin/admin) |

Connexion directe à la base depuis l'hôte :

```bash
psql -h localhost -p 5431 -U ekylibre eky_development
```

---

## 6. Commandes utiles

```bash
# Arrêter les containers
docker compose -f docker/dev/docker-compose.yml down

# Afficher les logs d'un service
docker compose -f docker/dev/docker-compose.yml logs -f app

# Ouvrir un shell dans le container app
docker compose -f docker/dev/docker-compose.yml exec app bash

# Lancer la console Rails
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rails c
```

---

## 7. Plugins Ekylibre

Les plugins sont déclarés dans `Gemfile.local` à la racine du projet. Ce fichier est chargé automatiquement par le `Gemfile` principal.

### Prérequis

Les plugins sont hébergés sur des dépôts GitHub privés et clonés via SSH lors du `bundle install`. La clé SSH de l'hôte est montée automatiquement dans les containers (`~/.ssh:/home/ekylibre/.ssh`).

S'assurer que la clé SSH est bien autorisée sur GitHub :

```bash
ssh -T git@github.com
# Hi <username>! You've successfully authenticated...
```

### Activation des plugins

Éditer `Gemfile.local` et décommenter ou ajouter les gems souhaitées :

```ruby
# Exemple : activer le plugin banking
gem 'ekylibre-banking', git: 'git@github.com:ekylibre/ekylibre-banking.git', branch: 'master'
```

Les plugins actifs au démarrage sont :

| Plugin | Dépôt |
|---|---|
| `ekylibre-baqio` | ekylibre/ekylibre-baqio |
| `ekylibre-ednotif` | ekylibre/ekylibre-ednotif |
| `ekylibre-banking` | ekylibre/ekylibre-banking |
| `ekylibre-qonto` | ekylibre/ekylibre-qonto |
| `hajimari` | ekylibre/ekylibre-hajimari |
| `idea` | ekylibre/ekylibre-idea |
| `planning` | ekylibre/ekylibre-planning |
| `ekylibre-samsys` | ekylibre/ekylibre-samsys |
| `ekylibre-traccar` | ekylibre/ekylibre-traccar |
| `ekylibre_ekyviti` | ekylibre/ekylibre-viti |
| `weenat` | ekylibre/ekylibre-weenat |
| `ekylibre-economic` | ekylibre/ekylibre-economic |
| `ekylibre-natuition` | ekylibre/ekylibre-natuition |

### Installation des gems après modification de Gemfile.local

Aucun rebuild d'image n'est nécessaire. Le `bundle install` est lancé automatiquement au démarrage du container. Pour le forcer manuellement :

```bash
docker compose -f docker/dev/docker-compose.yml exec app bundle install --path vendor/bundle
```

---

## 8. DNS wildcard pour l'accès multi-tenant

Chaque tenant est accessible via son sous-domaine : `http://{tenant}.ekylibre.lan:3000/`.  
Le service `dnsmasq` inclus dans le docker-compose résout automatiquement `*.ekylibre.lan → 127.0.0.2`.

Pour activer cette résolution **une seule fois** sur l'hôte Linux (Ubuntu 20.04+ avec systemd-resolved) :

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d/
sudo tee /etc/systemd/resolved.conf.d/ekylibre.conf << 'EOF'
[Resolve]
DNS=127.0.0.2
Domains=~ekylibre.lan
EOF
sudo systemctl restart systemd-resolved
```

Vérifier que la résolution fonctionne :

```bash
dig @127.0.0.2 -p 5353 demo.ekylibre.lan
# Doit retourner 127.0.0.2
```

Une fois configuré, **tous les tenants** créés dans l'interface admin sont automatiquement accessibles via leur URL, sans modifier `/etc/hosts`. L'interface admin affiche un lien direct `↗` pour chaque tenant (uniquement en environnement de développement).

> **Note :** Si le domaine utilisé est différent de `ekylibre.lan`, adapter `HOST_DOMAIN_NAME` dans `docker/dev/.env` et mettre à jour la config dnsmasq (`docker/dev/dnsmasq.conf`) en conséquence.

---

## 9. Résolution de problèmes

### Erreur de permissions sur `vendor/bundle` ou `/app`

Vérifier que `UID` et `GID` dans `docker/dev/.env` correspondent bien à ceux de votre utilisateur hôte :

```bash
id
# uid=1001(djoulin) gid=1001(djoulin) ...
```

Puis supprimer les volumes et rebuilder :

```bash
docker volume rm dev_bundle-volume dev_docker-dev
docker compose -f docker/dev/docker-compose.yml build --no-cache
```

### Warning Redis `Memory overcommit`

Appliquer sur l'hôte Linux :

```bash
sudo sysctl vm.overcommit_memory=1
# Pour persister après reboot, ajouter dans /etc/sysctl.conf :
# vm.overcommit_memory = 1
```

### Image de base inaccessible (`403 Forbidden`)

Le registry GitLab est privé. S'authentifier avant de builder :

```bash
docker login registry.gitlab.com
```
