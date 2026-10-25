# Exposer un tenant local avec ngrok

Ce guide explique comment exposer une instance Ekylibre qui tourne en local
(Docker) sur une URL publique HTTPS via [ngrok](https://ngrok.com/), tout en
respectant le système multi-tenant.

On prend comme exemple le tenant **`demo`**, accessible en local à l'adresse
`https://demo.ekylibre.localhost`.

## Le problème : ngrok casse la résolution par sous-domaine

En local, le tenant est résolu **par sous-domaine**. Caddy route
`*.ekylibre.localhost` vers Rails (`docker/dev/Caddyfile`), et l'elevator
Apartment extrait le premier segment de l'hôte comme nom de tenant :

| URL locale                          | Hôte                       | Tenant résolu |
|-------------------------------------|----------------------------|---------------|
| `https://demo.ekylibre.localhost`   | `demo.ekylibre.localhost`  | `demo`        |
| `https://closeriedesterres.ekylibre.localhost` | `closeriedesterres.ekylibre.localhost` | `closeriedesterres` |

Voir `config/initializers/apartment.rb:51-61` (`SecuredSubdomain`).

Avec ngrok (offre gratuite), votre instance est exposée derrière **un seul
domaine aléatoire** sans préfixe de tenant, par exemple :

```
https://intimate-firefly-top.ngrok-free.app
```

L'hôte est alors `intimate-firefly-top.ngrok-free.app`. L'elevator par
sous-domaine en extrait `intimate-firefly-top`, qui ne correspond à aucun schéma
PostgreSQL → `Apartment::TenantNotFound` → **404** (`apartment.rb:56-60`).

Il faut donc **forcer le tenant** par un autre moyen que le sous-domaine.

## Pré-requis

1. Installer ngrok et enregistrer votre authtoken :
   ```bash
   ngrok config add-authtoken <VOTRE_AUTHTOKEN>
   ```
2. La stack Docker dev tourne (`docker compose -f docker/dev/docker-compose.yml up`).
   Rails est exposé directement sur le port **3000** de l'hôte
   (`docker-compose.yml:14`).
3. Le tenant `demo` existe. Sinon, le créer :
   ```bash
   docker compose -f docker/dev/docker-compose.yml exec app \
     env TENANT=demo bundle exec rake tenant:init EMAIL=admin@example.com PASSWORD=secret
   # puis éventuellement un jeu de données de démonstration
   docker compose -f docker/dev/docker-compose.yml exec app \
     env TENANT=demo bundle exec rake first_run FOLDER=demo
   ```

> **Rails 5.2** n'a pas de liste blanche `config.hosts` (introduite en Rails 6).
> Aucun réglage d'allowlist n'est donc nécessaire pour accepter le domaine ngrok.

## Méthode recommandée (offre gratuite) : header `X-Tenant`

L'elevator `Header` (`apartment.rb:44-49`) lit le header HTTP **`X-Tenant`** et
ne retombe sur le sous-domaine que s'il est absent. Il est activé par la variable
`ELEVATOR=header`, **déjà positionnée** dans `docker/dev/.env:55`.

On demande à ngrok d'injecter ce header sur chaque requête entrante et de
pointer directement sur Rails (`:3000`) :

```bash
ngrok http 3000 --request-header-add "X-Tenant: demo" --url=https://intimate-firefly-top.ngrok-free.app
```

Résultat :

- ngrok termine le HTTPS et transmet à `localhost:3000` (il ajoute lui-même
  `X-Forwarded-Proto: https`, donc Rails se considère en HTTPS).
- Chaque requête porte `X-Tenant: demo` → l'elevator `Header` sélectionne le
  schéma `demo`, **quel que soit l'hôte ngrok**.
- L'hôte public reste le domaine ngrok, donc Rails génère des liens absolus
  corrects (redirections, e-mails, assets) qui repassent par le tunnel.

L'URL publique affichée par ngrok (`https://xxxx.ngrok-free.app`) sert alors le
tenant `demo`. On peut la mémoriser dans `docker/dev/.env` :

```dotenv
NGROK_HTTPS_URL=https://xxxx.ngrok-free.app
```

> **Page d'avertissement ngrok.** L'offre gratuite affiche une interstitielle au
> premier accès navigateur. Pour les appels API/mobile, ajoutez aussi le header
> `--request-header-add "ngrok-skip-browser-warning: true"`.

### Forcer un autre tenant

Remplacez simplement la valeur du header. Pour exposer plusieurs tenants en
parallèle, lancez plusieurs tunnels (chacun avec son propre `X-Tenant`).

```bash
ngrok http 3000 --request-header-add "X-Tenant: closeriedesterres"
```

## Méthode alternative (offre payante) : domaine wildcard réservé

Si vous disposez d'un **domaine wildcard réservé** chez ngrok
(ex. `*.eky.ngrok.app`), la résolution par sous-domaine fonctionne sans header.
L'elevator par défaut extrait le premier segment :

```bash
ngrok http 3000 --domain demo.eky.ngrok.app
```

L'hôte `demo.eky.ngrok.app` → tenant `demo`. Pour un autre tenant, exposez
`closeriedesterres.eky.ngrok.app`, etc. Cette méthode conserve l'elevator
`SecuredSubdomain` et n'a pas besoin de `ELEVATOR=header`.

## Passer par Caddy plutôt que directement par Rails

Pointer ngrok sur Rails `:3000` est le plus simple. Si vous voulez reproduire
exactement le chemin du navigateur (TLS Caddy + routage par hôte), faites pointer
ngrok sur Caddy. Caddy utilise un certificat **auto-signé** (`tls internal`), il
faut donc autoriser ngrok à l'accepter et réécrire l'hôte attendu :

```bash
ngrok http https://localhost:443 \
  --host-header demo.ekylibre.localhost \
  --request-header-add "X-Tenant: demo"
```

Dans la pratique, le passage direct par `:3000` avec le header `X-Tenant` couvre
la grande majorité des besoins (démo client, webhook, test mobile).

## Récapitulatif

| Besoin                                   | Commande ngrok                                                        | Elevator           |
|------------------------------------------|-----------------------------------------------------------------------|--------------------|
| Exposer `demo` (offre gratuite)          | `ngrok http 3000 --request-header-add "X-Tenant: demo"`               | `Header` (par défaut dans `.env`) |
| Exposer `demo` (domaine wildcard payant) | `ngrok http 3000 --domain demo.eky.ngrok.app`                        | `SecuredSubdomain` |
| API mobile / éviter l'interstitielle     | ajouter `--request-header-add "ngrok-skip-browser-warning: true"`     | —                  |

## Voir aussi

- `config/initializers/apartment.rb` — elevators `Header`, `SecuredSubdomain`, `Generic`.
- `docker/dev/Caddyfile` — routage local `*.ekylibre.localhost`.
- [Database schema](./db.md) — configuration Docker / PostgreSQL.
