# Classification des tables en trois plans

> Point 1.5 de [la feuille de route](../../docs/planning/v6-roadmap.md). Ce que
> le générateur de migrations du point 1.6 lira, et ce sur quoi le linter de
> schéma du point 1.7 s'appuiera.

## Les trois plans

| Plan | Ce qui y entre | Ce que ça implique |
|---|---|---|
| **données** | la ligne appartient à une ferme | `tenant_id`, PK composite `(tenant_id, id)`, index préfixés, RLS `FORCE` |
| **contrôle** | la ligne n'appartient à personne, ou à tout le monde | pas de `tenant_id`, hors RLS |
| **référentiel** | le schéma `lexicon` en entier | partagé, lu seulement, jamais de `tenant_id` |

Le plan de données est le **défaut**, mais un défaut choisi : chaque table y
figure nommément dans `classification.yml`, et `rake monoschema:check` échoue sur
une table qui n'apparaîtrait nulle part. La CI le joue à chaque passage — une
table oubliée est une table sans `tenant_id`, et personne ne le voit avant qu'un
client ne voie les données d'un autre.

## Deux fichiers, et un seul se modifie

- **`classification.yml`** ne porte que des décisions : les exceptions au plan
  de données, le choix de clé de l'ADR-003, et les questions restées ouvertes.
  C'est le seul fichier à modifier à la main.
- **`plan.yml`** est engendré par `rake monoschema:classify` à partir de
  `db/structure.sql` et du précédent. Tout ce qu'il contient se mesure :
  colonnes, index, clés étrangères, géométries, STI.

```bash
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake monoschema:classify
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake monoschema:check
```

## Ce que la mesure donne

316 tables, au 14 septembre 2026 :

| | |
|---|---:|
| plan de données | **241** |
| plan de contrôle | 2 |
| référentiel (`lexicon`) | 73 |
| clés en UUIDv7 (ADR-003) | 25 |
| clés en `bigint` | 216 |
| PK composites à poser | 241 |
| index uniques à préfixer par `tenant_id` | 38 |
| clés étrangères déclarées, cible au plan de données | 171 |
| clés étrangères déclarées, cible hors tenant | 0 |
| **références implicites** (colonne en `_id` entière, sans contrainte) | **896** |
| références par code vers le référentiel | 16 |
| colonnes géométriques (index GiST composites) | 35, sur 24 tables |
| tables en STI | 16 |
| tables sans clé primaire | 14 |

Trois chiffres méritent qu'on s'y arrête.

**896 références implicites.** Le schéma déclare 171 clés étrangères là où plus
de mille colonnes en `_id` désignent une ligne :
`intervention_parameters.intervention_id` n'a aucune contrainte aujourd'hui. Le
générateur du point 1.6 travaille donc surtout à l'aveugle — il ne peut pas
déduire la cible d'une colonne, il faut la lui dire ou la déduire du modèle
Ruby. C'est le vrai volume du lot, et il est cinq fois supérieur à ce que le
schéma avoue.

**Aucune clé étrangère ne pointe hors du plan de données.** Le référentiel est
désigné par des codes (`usage_id` est une chaîne, pas un entier), jamais par une
clé étrangère — ce qui simplifie le lot : aucune FK à *ne pas* rendre composite.

**Les 14 tables sans clé primaire sont toutes du `lexicon`.** Ce sont celles qui
retiennent `raise_on_missing_required_finder_order_columns` (point 0.8) : leur
donner une clé, c'est décider ce qui identifie une ligne dans chaque référentiel
importé. Le lot 1 les rencontre de nouveau ici.

## Le questionnaire

Les décisions se prennent plus facilement sur un document que dans un fichier
YAML. `rake monoschema:questionnaire` engendre
[`docs/planning/v6-classification-questions.md`](../../docs/planning/v6-classification-questions.md) :
les 241 tables du plan de données, chacune avec ses faits mesurés — colonnes,
clés, mentions dans le code, fixtures, présence d'un écran, dernière migration —
et une colonne *Décision* à remplir : `conserver`, `lexicon`, `supprimer`,
`contrôle` ou `discuter`.

Elles y sont rangées par signal, pour qu'on n'ait pas à lire les 241 : les
tables sans modèle, celles que presque rien ne mentionne, celles qu'aucun écran
ne modifie — la question du référentiel partagé —, puis le reste. Une fois le
document rempli, ses réponses se reportent dans `classification.yml`, qui fait
foi. **Le régénérer écrase les réponses.**

## Les sept questions ouvertes

`classify` les rappelle à chaque exécution. Aucune n'est technique — chacune
demande de savoir comment la donnée est employée, ce que le code seul ne dit
pas :

- `districts`, `postal_zones`, `vegetative_stages`, `net_services`, `units` —
  du référentiel dupliqué dans chaque ferme. Les passer au plan partagé
  suppose qu'aucune ferme ne les édite ; `units` recoupe `master_units` du
  `lexicon` ;
- `saas_subscriptions` porte un `tenant_name` : une ligne d'une ferme y désigne
  une *autre* ferme par son nom. C'est le lien inter-tenant que le point 1.22
  doit rendre explicite, pas une chaîne de caractères ;
- `users` reste au plan de données pour le lot 1 — Devise y est encore. Le trio
  du point 1.14 (`tenants`, `users`, `user_tenants`) est neuf, et le lot 2 le
  réconciliera avec Keycloak. Cette décision-là est datée : elle vaut jusqu'à
  ce que l'identité passe à Keycloak, pas au-delà.

## Le choix de clé, qui est le seul irréversible

25 tables prennent une clé UUIDv7. Le critère n'est pas l'importance de la
table, c'est **« le mobile peut-il en créer une ligne sans réseau ? »** — une
intervention et tout ce qui naît du même geste, une observation, un incident
signalé depuis la parcelle, une trace GPS, un comptage, un pointage, une
photo. Le reste garde une clé entière, y compris ce que le serveur seul
engendre : écritures comptables, mouvements de stock, lignes de TVA.

La liste est dans `classification.yml`, chaque table avec sa raison. Elle peut
grandir tant que les migrations ne sont pas écrites ; après, plus.
