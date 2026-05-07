# Base de données

## Configuration Docker

La base PostgreSQL/PostGIS tourne dans le service `db` du docker-compose (`docker/dev/docker-compose.yml`).

Les paramètres de connexion sont définis dans `docker/dev/.env` :

| Variable       | Description                    |
|---------------|--------------------------------|
| `DB_USERNAME` | Utilisateur principal PostgreSQL |
| `DB_PASSWORD` | Mot de passe principal          |
| `DB_HOST`     | Hôte (`db` en Docker)           |
| `DB_PORT`     | Port (`5432` interne, `5431` exposé) |
| `DB_DEV_NAME` | Nom de la base de dev           |

## Scripts d'initialisation

Les scripts dans `docker/db/` sont montés dans `docker-entrypoint-initdb.d/` et exécutés dans l'ordre alphabétique **uniquement lors de la première création du volume** :

1. `init.sql` — Crée le schéma PostGIS et les extensions (uuid-ossp, pgcrypto, unaccent, pg_trgm)
2. `init-duke-role.sh` — Crée un rôle en lecture seule pour l'application Duke

## Rôle Duke (lecture seule)

Le script `docker/db/init-duke-role.sh` crée un utilisateur PostgreSQL en lecture seule sur l'ensemble des schémas de la base. Il utilise les variables d'environnement :

| Variable        | Description                    |
|----------------|--------------------------------|
| `DUKE_USER`    | Nom du rôle lecture seule       |
| `DUKE_PASSWORD`| Mot de passe du rôle            |

Le rôle obtient :
- `CONNECT` sur la base de données
- `USAGE` sur tous les schémas existants
- `SELECT` sur toutes les tables existantes
- `DEFAULT PRIVILEGES` en SELECT sur les futures tables

### Exécution manuelle

Si la base existe déjà (le volume n'est pas recréé), exécuter le script manuellement :

```bash
docker compose -f docker/dev/docker-compose.yml exec db bash /docker-entrypoint-initdb.d/02-init-duke-role.sh
```

### Connexion depuis Duke

Duke se connecte via le réseau Docker partagé `ekylibre` :

| Paramètre | Valeur       |
|-----------|-------------|
| Host      | `db`         |
| Port      | `5432`       |
| Database  | `eky_development` |
| User      | `duke`       |
| Password  | `duke`       |

## Réseau Docker

Le docker-compose ekylibre déclare un réseau nommé `ekylibre`. Les autres projets (Duke) peuvent s'y connecter en le déclarant comme réseau externe :

```yaml
networks:
  ekylibre:
    external: true
```
