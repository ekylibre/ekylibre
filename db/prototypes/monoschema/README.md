# Prototype de mono-schéma — trois tables

> Point 1.4 de [la feuille de route](../../../docs/planning/v6-roadmap.md), porte
> d'entrée du lot 1. Il ne change rien à l'application : celle-ci reste sous
> Apartment, un schéma PostgreSQL par ferme. Tout ce qui suit vit dans une base
> à part, `ekylibre_monoschema`, montée à la demande.

## Ce qu'il fait

`interventions`, `intervention_parameters` et `products` sont transposées du
schéma-par-tenant vers une base unique à colonne `tenant_id`. Ces trois-là
couvrent à elles seules ce que la transformation générale rencontrera : deux
types de clé primaire (`uuidv7()` pour ce que le terrain crée, `bigint` pour le
reste), du STI sur deux tables, une colonne géométrique, un index unique global
à rendre local au tenant, et des références croisées entre les trois.

```bash
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake monoschema:generate monoschema:build
docker compose -f docker/dev/docker-compose.yml exec -e RAILS_ENV=test app bundle exec ruby -Itest test/prototypes/monoschema_test.rb
```

`monoschema:generate` lit `db/structure.sql` et écrit `schema.sql` — c'est la
répétition en petit du générateur de migrations du point 1.6, et son résultat
est versionné pour être relu. `monoschema:build` crée la base, le rôle
applicatif, et charge le schéma. Sans cette base, les tests sont **ignorés**, pas
en échec.

## Ce que le prototype établit

Dix-neuf mesures, toutes dans `test/prototypes/monoschema_test.rb`.

**L'isolation tient, et elle est fermée par défaut.** Sans contexte, la base ne
rend aucune ligne — `NULLIF(current_setting('app.tenant_id', true), '')::uuid`
vaut NULL, et `tenant_id = NULL` ne rend rien. Sous le tenant A, une ligne de B
reste introuvable même désignée par sa clé. `WITH CHECK` refuse aussi bien
d'écrire chez le voisin que d'y déplacer une ligne existante. Le rôle applicatif
ne peut pas désactiver la politique : il n'est pas propriétaire.

**La clé étrangère composite fait ce qu'on attend d'elle.** Une ligne du tenant A
qui désigne une intervention de B est refusée — non par la politique, mais par
la clé : `(tenant_id, intervention_id) → (tenant_id, id)`.

**L'index unique devient local au tenant.** Deux fermes peuvent porter le même
numéro de produit ; la même ferme deux fois, non.

## Les cinq pièges mesurés

Ce sont eux qui justifient le prototype : aucun ne se lit dans les ADR.

### 1. `id` ne rend plus l'identifiant

Rails 8.1 déduit seul la clé composite du schéma — `Product.primary_key` rend
`["tenant_id", "id"]`, sans annotation. Conséquence immédiate : **`record.id`
rend le couple**, pas la colonne. La colonne se lit par `record.id_value`.

Tout `foo_id: bar.id` du code existant devient faux en silence : l'affectation
passe, et la base rejette un tableau là où elle attend un entier. Le point 1.16
doit chercher ce motif, pas seulement annoter des associations.

### 2. `query_constraints:` n'existe pas sur une association

La feuille de route parlait d'« annoter les associations en `query_constraints` ».
Rails 8.1 le refuse explicitement — *« Setting `query_constraints:` option on
`has_many` is not allowed. To get the same behavior, use the `foreign_key`
option instead »*. La clé étrangère composite se déclare en tableau :

```ruby
has_many :parameters, foreign_key: %i[tenant_id intervention_id]
belongs_to :product,  foreign_key: %i[tenant_id product_id]
```

`query_constraints` reste une notion de *modèle*, pas d'association. À corriger
dans le point 1.16, qui porte sur 1 413 associations.

### 3. Le cache de requêtes ignore le tenant

Le cache de requêtes de Rails est indexé sur le seul texte SQL. Une lecture
faite sous le tenant A est resservie telle quelle plus tard — **y compris hors
de tout contexte**, là où la politique aurait rendu zéro ligne. La fermeture par
défaut est contournée non par la base, mais par le cache qui la précède.

Le cache vit le temps d'une requête HTTP ou d'un job ; le danger est donc pour
tout ce qui change de tenant à l'intérieur de l'un ou de l'autre — le tableau de
bord CUMA du point 1.22, les tâches qui bouclent sur les fermes, les tests
d'isolation eux-mêmes. Le prototype vide le cache à l'entrée et à la sortie de
`with_tenant` ; le futur `TenantRecord` doit faire de même, et le point 1.20 doit
en tenir compte, sans quoi ses tests se prouveront l'un l'autre.

### 4. `SET LOCAL` porte sur la transaction, pas sur le bloc

`SET LOCAL` meurt avec la transaction — c'est la propriété recherchée, et elle
tient : après le `COMMIT`, la base ne rend plus rien. Mais **une transaction
imbriquée est un savepoint**, et un savepoint relâché ne défait pas le réglage :
il contamine le reste de la transaction englobante. Un savepoint *annulé*, lui,
le défait — mesuré dans les deux sens.

Le cas n'est pas théorique : une suite de tests enveloppe chaque test dans une
transaction, et tout code applicatif qui ouvre une transaction avant de choisir
son tenant est dans la même situation. `with_tenant` relève donc la valeur
précédente et la restaure lui-même, au lieu de compter sur la fin de
transaction. Le futur `TenantRecord` devra faire de même — et c'est aussi ce qui
permet d'imbriquer deux contextes sans que le second détruise le premier.

### 5. Sous RLS, l'index spatial cesse de servir

C'est la mesure la plus coûteuse du lot, et elle contredit l'ADR-002 telle
qu'elle est écrite. PostgreSQL n'évalue une condition **avant** la politique que
si elle est `LEAKPROOF`. Les opérateurs de PostGIS ne le sont pas : sous RLS,
`ST_Intersects` reste un filtre appliqué *après* la politique, et l'index GiST
composite `(tenant_id, initial_shape)` ne sert plus à rien.

Sur le jeu du prototype — 5 000 produits, deux tenants, statistiques à jour :

| Requête parcellaire d'un tenant | Coût estimé | Chemin |
|---|---:|---|
| sans marquage, `ST_Intersects` | 63 380 | btree sur `(tenant_id, …)`, géométrie en filtre |
| `geometry_overlaps` LEAKPROOF, opérateur `&&` | **229** | GiST composite |
| `geometry_overlaps` + `st_intersects` LEAKPROOF | 1 167 | GiST composite, recheck en filtre |

Un facteur 275 entre la première ligne et la deuxième. `monoschema:build`
applique donc le marquage — mais **c'est une décision de sécurité, pas un
réglage** : marquer une fonction `LEAKPROOF`, c'est affirmer qu'elle ne peut pas
divulguer la valeur de ses arguments par un message d'erreur. Pour un
recouvrement de rectangles englobants c'est défendable ; la décision revient au
lot 1, et elle doit être prise en connaissance de cause.

Deux choses valent d'être notées au passage : il faut **avoir analysé la table**
(sans statistiques, le planificateur estime la sélectivité spatiale au jugé et
choisit n'importe quel btree préfixé par `tenant_id`), et il faut **laisser le
parcours par bitmap disponible**, puisque c'est par lui que passe un index GiST.

## Ce qui marche sans rien demander

- `uuidv7()` est engendré par la base, les identifiants se suivent dans l'ordre
  de création, et la version est bien 7 ;
- le STI survit à la clé composite : `Plant.all` ajoute son `type` à la clause,
  et `find_by` rend bien une instance de la sous-classe ;
- le verrou optimiste (`lock_version`) fonctionne sous clé composite ;
- les associations traversent la clé composite dès lors qu'elles sont déclarées
  en `foreign_key: [..]`, et le SQL engendré porte `tenant_id`.

## Ce que le prototype ne dit pas

- **l'échelle.** Deux tenants et 5 000 lignes : les coûts ci-dessus comparent des
  chemins, ils ne prédisent pas le comportement à 1 000 fermes. La mesure
  d'échelle appartient au point 1.9 ;
- **le contexte hors transaction.** L'application lit beaucoup hors transaction ;
  le point 1.17 devra trancher : ouvrir une transaction pour toute requête, ou
  poser le contexte à la prise de connexion et le nettoyer au retour au pool ;
- **les 310 autres tables**, les vues matérialisées, les HABTM, les séquences
  globales — points 1.5, 1.10 et 1.11.
