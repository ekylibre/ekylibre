# Ekylibre API

## API v2

Le fichier [openapi-v2.yaml](openapi-v2.yaml) décrit l'API v2 d'Ekylibre au format **OpenAPI 3.0**. Il peut être visualisé/utilisé avec :

- **Swagger UI** : `npx swagger-ui-watcher docs/api/openapi-v2.yaml`
- **Redoc** : `npx redocly preview-docs docs/api/openapi-v2.yaml`
- **Postman / Insomnia** : importer directement le fichier YAML
- **Codegen** (clients SDK) :
  ```bash
  npx @openapitools/openapi-generator-cli generate \
    -i docs/api/openapi-v2.yaml \
    -g typescript-axios \
    -o tmp/api-client
  ```

## Authentification

1. **Obtenir un token** :
   ```bash
   curl -X POST https://<tenant>.ekylibre.com/api/v2/tokens \
     -H "Content-Type: application/json" \
     -d '{"email":"user@example.com","password":"…"}'
   ```

2. **Utiliser le token** :
   - Header (recommandé) :
     ```
     Authorization: simple-token user@example.com <token>
     ```
   - Query string :
     ```
     ?access_email=user@example.com&access_token=<token>
     ```

3. **Révoquer un token** :
   ```bash
   curl -X DELETE https://<tenant>.ekylibre.com/api/v2/tokens/<token> \
     -H "Authorization: simple-token user@example.com <token>"
   ```

## Multi-tenant

Chaque ferme correspond à un schema PostgreSQL distinct. Le tenant est sélectionné via :
- Le **sous-domaine** (`<tenant>.ekylibre.com`) en production
- L'en-tête HTTP `X-Tenant: <name>` (configurable)

## Endpoints (v2)

| Méthode | Chemin                                                    | Description                                    |
|--------|-----------------------------------------------------------|------------------------------------------------|
| POST   | /tokens                                                    | Authentification                                |
| DELETE | /tokens/{id}                                               | Déconnexion                                     |
| GET    | /profile                                                   | Profil complet de l'utilisateur courant         |
| PUT    | /profile                                                   | Mettre à jour son profil                        |
| GET    | /users/me                                                  | Profil minimal (clients externes type Duke)     |
| GET    | /cultivable_zones                                          | Lister les parcelles                            |
| POST   | /cultivable_zones                                          | Créer une parcelle                              |
| PUT    | /cultivable_zones/{uuid}                                   | Modifier une parcelle                           |
| GET    | /products(/{product_type})                                 | Lister les produits (optionnellement par type)  |
| GET    | /variants                                                  | Lister les variantes catalogue                  |
| GET    | /interventions                                             | Lister les interventions                        |
| POST   | /interventions                                             | Créer une intervention enregistrée              |
| PUT    | /interventions/{id}                                        | Modifier une intervention                       |
| GET    | /procedures                                                | Lister les procédures (config/procedures/*.xml) |
| GET    | /procedures/{name}                                         | Détail d'une procédure                          |
| GET    | /farm_profiles/{harvest_year}                              | Profil agrégé de l'exploitation pour une année  |
| GET    | /farm_accountancy/{harvest_year}                           | Comptabilité agrégée pour une année             |
| GET    | /lexicon/registered_phytosanitary_cropsets                 | Lexique : groupes de cultures phytosanitaires   |
| POST   | /lexicon/registered_phytosanitary_cropsets                 | Diff de synchronisation                         |
| GET    | /lexicon/registered_phytosanitary_products                 | Lexique : produits phytosanitaires              |
| POST   | /lexicon/registered_phytosanitary_products                 | Diff de synchronisation                         |
| GET    | /lexicon/registered_phytosanitary_risks                    | Lexique : risques phytosanitaires               |
| POST   | /lexicon/registered_phytosanitary_risks                    | Diff de synchronisation                         |
| GET    | /lexicon/registered_phytosanitary_usages                   | Lexique : usages phytosanitaires                |
| POST   | /lexicon/registered_phytosanitary_usages                   | Diff de synchronisation                         |

## Réponses d'erreur

- `400 Bad Request` : paramètres invalides (réponse `{ "errors": [...] }` ou `{ "message": "..." }`)
- `401 Unauthorized` : authentification manquante ou invalide
- `403 Forbidden` : violation de validation (ActiveRecord)
- `404 Not Found` : ressource introuvable
- `412 Precondition Required` : prérequis métier non satisfait (ex : worker non lié à un email)
- `422 Unprocessable Entity` : entité invalide

Tous les contrôleurs renvoient un en-tête personnalisé `X-Ekylibre-Media-Type: ekylibre.V2`.
