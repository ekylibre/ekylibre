# Ekylibre V6 — Feuille de route opérationnelle

**Statut :** proposition — à valider
**Date :** 13 septembre 2026 — progression mise à jour le soir même (lot 0.1 clos)
**Complément de :** [v6-architecture.md](v6-architecture.md) (ADR-001 à ADR-012),
dont il reprend le découpage en phases. Là où l'architecture dit *pourquoi* et
*quoi*, ce document dit *ce qu'il faut écrire ou modifier*, dans quel ordre, et ce
qui est déjà fait.

**À lire avec :** [v6-etat-des-lieux.md](v6-etat-des-lieux.md) (état mesuré au
13 septembre), [v6-improvement-plan.md](v6-improvement-plan.md) (lots A à H et
efforts), [v6-dependency-audit.md](v6-dependency-audit.md),
[ui_ux_v6.md](ui_ux_v6.md) (écrans et parcours).

**Les lots 8 à 11 découlent du guide du § 12** et sont placés après lui, à la
suite ; les lots 0 à 7 en tiennent compte là où il les touche.

---

## 0. Quatre corrections au document d'architecture

Ces points sont vérifiés sur la branche `6.0-alpha` et changent des prémisses.

**0.1 — `apartment` passe Rails 8.1.** L'ADR-002 justifie le mono-schéma par
« `apartment` ne passe pas Rails 8.1 ». Le dépôt n'utilise pas `apartment` mais
son fork maintenu **`ros-apartment`, en 3.4.4, qui déclare `activerecord < 8.2`
et fonctionne** : six tenants listés sous Rails 8.1.3.1, suite à parité. Rien ne
presse techniquement.

La décision reste bonne, mais pour ses vraies raisons — migrations jouées une
fois au lieu de N, requêtes inter-tenants redevenues possibles, préparation de la
restauration d'archives v5 — et non par contrainte de compatibilité. La
conséquence pratique : **le calendrier du mono-schéma est un choix, pas une
échéance subie.**

**0.2 — La phase 0 est déjà à moitié faite.** « Migration Rails 5.2 → 8.1,
Ruby 2.6 → 3.4 » est **achevée** (quinze commits, parité de suite à chaque
palier). Restent, dans cette phase : la fusion des schémas, le RLS, les index, et
Propshaft.

**0.3 — PostgreSQL n'est plus plafonné par le client.** L'image de base
`ruby3.4.10` embarque désormais `psql`/`pg_dump` **17.11** ; le serveur de
développement et la CI sont en **13.4**. Le blocage documenté jusqu'ici (« le
client 13 refuse un serveur plus récent ») est donc repoussé de quatre versions :
monter le serveur en 15, 16 ou 17 ne demande plus que de changer l'image du
service.

**Il n'est pas levé pour autant, et la cible est justement au-delà.** `pg_dump`
refuse un serveur plus récent que lui quelle que soit sa version — mesuré le
14 septembre : un `pg_dump` 17.11 contre un serveur 18.6 s'arrête sur
« aborting because of server version mismatch ». Comme `uuidv7()` native
n'existe qu'en PostgreSQL 18, le point 0.17 commence par **monter
`postgresql-client` en 18 dans `ekylibre/docker-base-images`**, et seulement
ensuite le serveur.

Effet de bord à connaître : `db/structure.sql` versionné a été produit par
`pg_dump` 13.23. **Toute régénération avec le client 17 produit un diff de
~1400 lignes** (ordre et forme des contraintes). Il faut l'assumer une fois,
dans un commit dédié, et fixer la version de `pg_dump` employée.

**0.5 — « 100 % open source » : WhatsApp est écarté (tranché le 13 septembre
2026).** L'objectif à un an (§ 12.1) est de rénover la pile en conservant 100 %
de briques open source ; l'ADR-005 routait la saisie terrain par WhatsApp Cloud
API, donc par Meta. La contradiction est levée : **WhatsApp est abandonné**,
Telegram devient le canal de production et une messagerie auto-hébergeable
(Matrix) la cible de souveraineté. L'ADR-005 est révisé en ce sens.

Ce que cela ne règle pas, et qu'il faut garder en tête : **le serveur Telegram
reste propriétaire**. Seuls le client et le *Bot API server* sont ouverts, et ce
dernier dialogue de toute façon avec l'infrastructure Telegram. La chaîne n'est
donc pas encore « 100 % open source » — c'est le rôle du port `Channel::Adapter`
de rendre le passage à Matrix possible sans réécrire `voice-gateway`.

**0.4 — Solid Queue et Propshaft ne sont pas là.** L'ADR-012 les présente comme
adoptés. État réel : `sidekiq` 7.3.10 (la série 8 exige `rack >= 3.1`, que
`turnout` interdit), `sprockets` 3.7.5 et `webpacker` 4.3.0, `redis` 5.4.1,
aucun `propshaft` ni `solid_queue`. Ce sont des lots à écrire, chacun avec son
préalable.

---

## 1. Ce qui est fait

| Lot | État |
|---|---|
| Rails 5.2 → **8.1.3.1**, Ruby 2.6 → **3.4.10** | fait, valeurs par défaut 8.1 incluses |
| Paperclip → Active Storage | fait (lot A.3) |
| `state_machine` → `Transitionable` | fait |
| RGeo 2 → **3**, PROJ 9 | fait |
| `sidekiq` 4 → **7.3**, Action Cable fonctionnel | fait |
| CI GitHub Actions, CodeQL, plancher de couverture 55 % | fait (lot A.8) |
| RCE du restore de tenant | corrigée (lot P0) |
| RuboCop 1.11 → **1.91**, ESLint au vert | fait |
| **Lot 0.1 — les 32 cas rouges hérités des paliers** | fait, 13 septembre 2026 (8 commits, `57c26b9d0a` → `d0763167be`) |
| Découplage des modèles HVE du greffon qui les alimente | fait (préalable du 0.1) |
| `Devise.mappings` en exécution isolée (point 0.3) | fait — routes paresseuses depuis 7.1, le harnais les charge |
| Instabilité d'ordre du test d'achat (point 0.2), `Regexp.timeout` rétabli | fait, 14 septembre 2026 — un `find_by` sans ordre sur une colonne non unique |
| `db/structure.sql` réécrit à l'insu du développeur (point 0.4) | fait, 14 septembre 2026 — le dump ne suit plus `db:migrate` |
| CI restreinte à `6.0-alpha` ; `Lint` et `CodeQL` au vert | fait |

---

## 2. Lot 0 — Assainir avant d'ouvrir le schéma

*Rien de ce qui suit n'est nouveau fonctionnellement. Tout est un préalable pour
que le chantier de schéma soit lisible : sans suite verte, une régression de RLS
se perdra dans le bruit.*

### 2.0 — La suite verte, d'abord (**bloquant**)

| # | À faire | État |
|---|---|---|
| 0.1 | ~~Traiter les **17 échecs et 15 erreurs** de la suite~~ | **fait.** 3620 tests (−27 HVE partis au greffon, −3 de la page Exports supprimée). Dernière mesure CI : 0 échec, 1 erreur, corrigée par `d0763167be`. **Confirmé en local le 14 septembre**, après les points 0.2 et 0.4 : 3621 tests, 0 échec, 0 erreur, 4 ignorés |
| 0.2 | ~~Corriger le test d'achat aux montants inconciliables (99 € HT / 120 € TTC à 20 %), puis rétablir `Regexp.timeout`~~ | **fait.** La cause n'était pas les seuls montants : `PurchaseTest#simple creation` demandait `Tax.find_by(amount: 20)` **après** avoir créé une seconde taxe à 20 %, intracommunautaire. Sans ordre, la ligne rendue est celle que le plan veut bien donner, et une taxe intracommunautaire n'ajoute rien au HT — d'où les 21 € manquants et l'écriture déséquilibrée. Le test désigne désormais la taxe qu'il vise (`intracommunity: false`) et pose des montants qui se réconcilient (100 € HT → 120 € TTC). `Regexp.timeout` est rétabli : le réglage n'y était pour rien |
| 0.3 | ~~Stabiliser `Devise.mappings` en exécution isolée~~ | **fait.** Ce n'était pas une référence de classe périmée : les routes se chargent paresseusement depuis Rails 7.1, `devise_for` ne peuplait donc `Devise.mappings` qu'à leur premier accès. `test/test_helper.rb` appelle `reload_routes_unless_loaded` |
| 0.4 | ~~Empêcher la suite de réécrire `db/structure.sql`~~ | **fait.** Ce n'était pas la suite : `docker/startup.sh` lance `rake db:migrate` à chaque démarrage du conteneur, et `db:migrate` enchaînait sur `db:structure:dump`. Un `docker compose up` suffisait donc à salir l'arbre. `config.active_record.dump_schema_after_migration` est désormais faux, `DUMP_SCHEMA=1` rétablissant l'enchaînement le temps d'une commande ; la régénération reste celle de `CLAUDE.md` |
| 0.20 | Reprendre les **4 tests ignorés** : le manifeste de packs est vide en test, un gabarit appelant `javascript_pack_tag` ne se rend pas | à faire **avec le lot 7**, pas avant |

**Critère de sortie :** `bin/rails test` sort au vert, donc le job `Tests` de la
CI passe. Les points 0.2 et 0.4 étant traités, il ne reste plus d'instabilité
connue : le point 0.20 est le seul ouvert de cette section, et il attend le
lot 7.

Ce que le lot 0.1 a appris est consigné dans
[v6-etat-des-lieux.md](v6-etat-des-lieux.md) § 2 et dans `CLAUDE.md` : **la
moitié des 32 cas étaient de vrais défauts utilisateur** — la clôture d'exercice
ne produisait aucun document de journal depuis le passage à Ruby 3 — et trois
autres ne dépendaient pas du code mais de la machine (identité GPG, clé d'API
INSEE, identifiants de `lexicon` figés).

### 2.1 — Les six valeurs par défaut désactivées

Chacune est documentée dans `config/application.rb` — `Regexp.timeout`, la
septième, est rétablie depuis le point 0.2. Deux forment un lot cohérent
avec le point 0.1, parce qu'elles touchent les mêmes rappels comptables :

| # | À faire |
|---|---|
| 0.5 | `raise_on_assign_to_attr_readonly` : revoir les rappels et setters qui réaffectent `currency`, `nature`, `journal_id`, `state`, `listing_id`, `number`, `root_model` sans distinguer création et mise à jour. **325 tests concernés** ; ces écritures sont perdues en silence aujourd'hui |
| 0.6 | `has_many_inversing` + `automatic_scope_inversing` : casser la récursion mutuelle `PurchaseInvoice` ↔ `PurchaseItem` |
| 0.7 | `default_column_serializer` : sortir de `wice_grid` (4 contrôleurs) ou corriger son `serialize :query` nu en amont |
| 0.8 | `raise_on_missing_required_finder_order_columns` : donner une clé aux **14 tables du `lexicon`** qui n'en ont pas — *à faire dans le lot 1, C.2* |
| 0.9 | `active_storage.variant_processor` : libvips dans l'image de base |

### 2.2 — Dette d'outillage

| # | À faire |
|---|---|
| 0.10 | Résorber les **809 offenses** de `.rubocop_todo.yml` (542 auto-corrigeables) par lots thématiques |
| 0.11 | Les **39 avertissements TypeScript** (types `any`, retours manquants) |
| 0.12 | Décider du sort de `Ekylibre::Plugin` (≈300 lignes) : le mécanisme `plugins/` est mort, les 19 greffons sont des engines. Le retirer ou le documenter |
| 0.13 | Supprimer les constantes autochargées pendant l'initialisation (avertissement Rails ; 76 fichiers de `lib/` chargés avant la fin de l'initialisation) |
| 0.18 | **Faire tourner les tests des greffons.** La suite du cœur ne les ramasse pas et aucun des 19 greffons n'a de CI : leurs suites ne s'exécutent nulle part. Deux voies — une CI par greffon, ou un `Gemfile.ci` versionné qui les monte dans la CI du cœur (`docker/prod/Gemfile.prod` montre déjà comment les déclarer en git public) |
| 0.19 | Empêcher le retour du couplage inverse : un test du cœur ne doit pas dépendre d'un greffon. Contrôle mécanique possible — la suite du cœur, exécutée sans `Gemfile.local`, ne doit produire aucune erreur de constante |

### 2.3 — Mise en service du palier

| # | À faire |
|---|---|
| 0.14 | `docker/prod/Dockerfile` en Ruby 3.4 ; relever le plancher du `Gemfile` (`ruby '>= 3.4'`) |
| 0.15 | ~~Décider~~ — **tranché : le déploiement vient après le mono-schéma**, sur le staging `ekylibre.io` via Dokploy (lot 11). L'écart avec la production grandit d'autant : à surveiller, c'est le prix assumé de ce choix |
| 0.16 | Déclencher `build-prod-image` sur `6.0-alpha` le jour de cette décision, pas avant. **Essayé le 13 septembre, retiré aussitôt** : `docker/prod/Dockerfile` part de l'image `ruby2.6` alors que le `Gemfile` exige `>= 3.4.0`, donc le `bundle install` s'arrête avant la première gem — le job serait rouge à chaque commit. Le workflow ne suit plus aucune branche (étiquette `v*` ou à la demande) ; c'est le point 0.14 qui le débloque |
| 0.17 | ~~**Monter le serveur PostgreSQL de 13 à 18**~~ | **fait, 14 septembre 2026.** `uuidv7()` répond sur la pile réelle. Le point a commencé par le client, non par le serveur : `pg_dump` refuse un serveur plus récent que lui — mesuré, « server version: 18.6 ; pg_dump version: 17.11 » — et Apartment l'appelle à *chaque* création de tenant, si bien qu'un client en retard ne dégrade rien, il rend les tenants incréables. `docker-base-images@6281aea` porte donc le client 18 ; dev et CI passent ensuite sur `postgis/postgis:18-3.6`, l'image officielle remplaçant `kartoza/postgis`. Trois choses sont tombées en chemin, toutes réparées : l'ordre des scripts d'init (celui de l'image installe PostGIS dans le schéma courant), `--host=localhost` dans `init-duke-role.sh` (le serveur temporaire d'initialisation n'écoute que la socket), et le test du lexique de `docker/startup.sh`, qui regardait l'existence du schéma là où `structure.sql` le déclare vide. `structure.sql` est régénéré dans son commit dédié — 751 lignes de forme, dont les contraintes `NOT NULL` nommées que `pg_dump` 18 écrit, ce qui rend le fichier illisible par un serveur plus ancien |

---

## 3. Lot 1 — Mono-schéma et isolation (ADR-002, ADR-003)

*Reprend les lots C et D du plan v6. La décision ADR-003 est bloquante et doit
être prise avant la première migration.*

### 3.1 Préalables de décision

**Tranché le 13 septembre 2026 :** PostgreSQL **18**, donc `uuidv7()` native ;
**UUIDv7** pour les entités créées sur le terrain, forme compatible avec
l'application mobile et Duke ; `tenant_id` en **`uuid`**, la table `tenants`
conservant le nom actuel du tenant (`phaurigot`, `sci-chenes-verts`…) comme
`slug` lisible — l'UUID porte l'identité, le slug porte la lisibilité.

| # | Ce qu'il reste à faire avant la première migration | Pourquoi |
|---|---|---|
| 1.2 | **Audit préalable** : aucun greffon ni export réglementaire ne doit sérialiser des `id` numériques (EDI, `ednotif`, exports comptables, Isacompta, Telepac) | une dépendance invisible dans le schéma casse à la première déclaration — c'est le seul préalable qui reste, et il ne demande aucune décision |
| 1.3 | ~~Monter le serveur en 18 (cf. 0.17) et vérifier `uuidv7()` sur la pile réelle~~ | **fait le 14 septembre** : serveur 18.6, `select uuidv7()` répond `01a09faf-f85a-726f-…` sur le conteneur de développement. Le fondement du choix est constaté, non supposé |

### 3.2 Schéma

| # | À faire | Volume mesuré |
|---|---|---|
| 1.4 | ~~Prototype sur 3 tables~~ | **fait, 14 septembre 2026** — `db/prototypes/monoschema/`, dix-neuf mesures dans `test/prototypes/monoschema_test.rb`, rejouées par la CI. L'isolation tient et elle est fermée par défaut ; la FK composite refuse la référence inter-tenant ; l'index unique devient local au tenant. Quatre pièges mesurés, qu'aucune ADR ne mentionnait : `record.id` rend le couple et non la colonne, `query_constraints:` n'existe pas sur une association, le cache de requêtes ignore le tenant, et **sous RLS l'index spatial cesse de servir** faute de `LEAKPROOF`. Le compte rendu est dans [le README du prototype](../../db/prototypes/monoschema/README.md) |
| 1.5 | ~~Classifier les tables en trois plans~~ | **fait, 14 septembre 2026** — `db/monoschema/`, deux fichiers : `classification.yml` ne porte que les décisions, `plan.yml` est engendré de `db/structure.sql` et sera lu par le point 1.6. **316 tables** : 241 au plan de données, 2 au contrôle, 73 au référentiel. Sept restent à trancher, aucune pour une raison technique. `rake monoschema:check`, joué par la CI, échoue sur toute table non classée — la graine du point 1.7. **[Le questionnaire](v6-classification-questions.md) est revenu rempli le 15 septembre** : 234 tables au plan de données, **5 à déplacer vers le `lexicon`** (`districts`, `postal_zones`, `vegetative_stages`, `net_services`, et `units` à *fusionner* avec `master_units`), **2 supprimées** (`saas_subscriptions`, `user_tickets`), `users` en suppression conditionnelle jusqu'à Keycloak, et **40 clés en UUIDv7** au lieu de 25. Deux conséquences : le déplacement de `units` touche 10 colonnes dans 10 tables et retire aux fermes un écran de création, et les 8 seules clés étrangères qui franchissent désormais un plan visent toutes `units` |
| 1.6 | ~~Générateur de migrations piloté par 1.5~~ | **forme d'arrivée engendrée le 15 septembre 2026** : `rake monoschema:schema` écrit `db/monoschema/schema.sql` — 314 tables, 234 avec `tenant_id`, 1 000 clés étrangères composites, 35 index GiST — et elle se charge dans une base vide. Préalable levé : `rake monoschema:references` résout **1 047 colonnes** depuis les `belongs_to` des modèles (1 000 vers le plan de données, 15 vers le référentiel, 22 polymorphes) ; **10 seulement résistent**, et elles n'ont pas d'association parce qu'elles sont orphelines. **La recopie des données est écrite et vérifiée de bout en bout** (`monoschema:migrate`, `monoschema:migrate:check`) : deux fermes jetables, des identifiants volontairement identiques des deux côtés, 234 tables recopiées, remappage UUIDv7 cohérent, séquences replacées, politiques intactes. L'uuid engendré porte la date de la ligne — `uuidv7(created_at - now())` — et non celle de la migration, sans quoi l'historique s'entasserait au même endroit de l'index. Reste la déduplication des cinq tables qui passent au référentiel | ancien relevé : Mesuré au point 1.5 : PK composites **241** ; clés en UUIDv7 **25**, en `bigint` **216** ; index uniques à préfixer **38** ; FK déclarées à rendre composites **171**, aucune ne pointant hors du plan de données. **Et 896 références implicites** — des colonnes en `_id` entières sans contrainte, là où le schéma n'avoue que 171 clés étrangères. Le générateur ne peut pas en déduire la cible : il faut la tirer des modèles Ruby. C'est le vrai volume du lot |
| 1.7 | ~~**Linter de schéma en CI**~~ | **fait** — `rake monoschema:audit` vérifie les six invariants sur la base de sonde, pas sur le fichier, et la CI l'enchaîne après `monoschema:schema:build`. Les six tiennent sur les 234 tables |
| 1.8 | ~~Scan `pg_indexes`~~ | **fait**, c'est le cinquième invariant de `monoschema:audit`. Aucun des 38 index uniques du plan de données ne commence ailleurs qu'à `tenant_id` |
| 1.9 | Index **GiST composites** `btree_gist (tenant_id, shape)` — **35 colonnes géométriques sur 24 tables** du plan de données (mesuré au point 1.5 ; les autres sont au référentiel, sans `tenant_id`). **Insuffisant seul** : sous RLS, une condition non `LEAKPROOF` est évaluée après la politique et ne peut pas servir d'index — l'index existe alors sans servir. Mesuré au point 1.4 : coût estimé 63 380 contre 229 selon que l'opérateur spatial est marqué ou non. Marquer `geometry_overlaps` et `st_intersects` est une **décision de sécurité** à prendre explicitement | 35 colonnes |
| 1.10 | ~~Cas particuliers : vues matérialisées, HABTM, `WorkerTimeIndicator`~~ | **mesuré et tranché en partie.** HABTM : aucune table de jonction sans clé dans `public` — les onze « tables » de jonction sont des **vues**, déjà en lecture seule. Vues : une vue ordinaire **contourne la RLS** (mesuré : elle rend les lignes des deux fermes au rôle applicatif), elles sont donc engendrées `WITH (security_invoker = true)`, et deux invariants d'audit le vérifient. **Les trois vues matérialisées restent à réécrire à la main** : leur regroupement ne porte pas `tenant_id`, si bien que les heures des travailleurs n° 1 de deux fermes s'additionneraient dans la même ligne — un chiffre faux, pas une fuite. `worker_time_indicators` demande en outre de repenser son rafraîchissement, qui a lieu à chaque sauvegarde d'intervention et recalculerait toutes les fermes |
| 1.11 | ~~Séquences globales + `setval` au-dessus du `MAX(id)`~~ | **fait avec la recopie** : `monoschema:migrate` replace chaque séquence d'identité au-dessus du plus grand `id` recopié, et la vérification le contrôle. À noter, contre ce que le point supposait : **il n'y a rien à renuméroter**. La clé primaire composite `(tenant_id, id)` absorbe les collisions entre fermes, donc 194 tables sur 234 gardent leurs entiers tels quels ; seules les 40 tables à clé UUIDv7 et les 132 colonnes qui les désignent demandent un remappage |
| 1.12 | Schéma nommé `ekylibre`, `public` réservé aux extensions | — |
| 1.13 | ~~Rôle applicatif **non-propriétaire, sans `BYPASSRLS`, non-superuser**~~ | **fait et vérifié** : le schéma engendré crée `ekylibre_app` avec ces seules permissions, et un invariant d'audit échoue si le rôle devient superutilisateur, gagne `BYPASSRLS` ou se retrouve propriétaire d'une table. Reste à nommer le rôle de maintenance, qui n'a pas encore d'emploi |

### 3.3 Runtime

| # | À faire | Volume mesuré |
|---|---|---|
| 1.14 | Plan de contrôle : `users`, `tenants`, `user_tenants`. Le point 1.5 a laissé la table `users` actuelle au plan de données — Devise y est encore — : ces trois tables sont neuves, et le lot 2 réconciliera les deux avec Keycloak | 3 tables neuves |
| 1.15 | `TenantRecord` / `ApplicationRecord` / `LexiconRecord` ; reclasser les modèles | **244 modèles racines + 111 STI** |
| 1.16 | Déclarer les clés étrangères composites en **`foreign_key: %i[tenant_id …]`** — `query_constraints:` est refusé sur une association depuis Rails 8.1. **Mesuré le 15 septembre : 4 167 associations** sur 312 modèles, dont 3 532 annotables, 603 sans objet (513 `:through`, 90 hors tenant) et 32 manuelles (22 polymorphes, 10 HABTM). **Et l'annotation n'est pas ce qu'on croyait** : sous la RLS, une association non annotée produit du SQL juste — la politique filtre. Elle ne compte que sur les chemins qui traversent la politique (migrations, administration, `without_tenant`, inter-fermes du 1.22), où elle évite une fuite mesurée : 2 lignes rendues au lieu d'1 quand deux fermes partagent un `id`. C'est donc une **seconde ceinture**, à poser par domaine, et non un codemod bloquant. S'y ajoute la chasse aux `foo_id: bar.id`, que la clé composite rend faux en silence — c'est `id_value` qu'il faut | **4 167 associations** |
| 1.17 | ~~Contexte runtime~~ | **écrit et éprouvé** : `lib/ekylibre/tenancy.rb`, sept tests. Il pose `SET LOCAL app.tenant_id`, vide le cache de requêtes de part et d'autre, rétablit lui-même la valeur précédente — un savepoint ne la rendrait pas —, et ouvre une transaction quand il n'y en a pas, `SET LOCAL` étant sans effet hors transaction. Le cas des lectures hors transaction est donc tranché *pour l'instant* en faveur de la transaction ; l'autre voie, poser le réglage à la prise de connexion, reste ouverte si les transactions longues gênent. Rien n'est branché tant qu'Apartment est là |
| 1.18 | Propager le contexte aux chemins asynchrones | **commencé** : `Ekylibre::Tenancy::JobPropagation` fait voyager la ferme dans la sérialisation du job et rétablit le contexte à l'exécution, comme `apartment-sidekiq` le fait du nom de schéma ; un test le vérifie de bout en bout. Restent Action Cable, les tâches rake et les 112 exchangers |
| 1.19 | ~~Auditer le SQL brut~~ | **recensé et classé** (`rake monoschema:raw_sql`, `db/monoschema/raw-sql.yml`) : **190 sites**, dont 72 qui ne touchent aucune table du plan de données, 17 que la politique couvre, 97 à relire par précaution (écritures en masse, jointures littérales) et **4 à reprendre**. Correction de prémisse : **le SQL brut ne contourne pas la RLS** — une requête écrite à la main est filtrée comme les autres, jointures comprises. Ce qu'il risque est la rupture, et elle est bruyante : un `INSERT` sans `tenant_id` se fait refuser par la politique, un `ON CONFLICT (number)` ne trouve plus son index | 190 sites |
| 1.20 | ~~Tests d'isolation **générés**~~ | **fait** : `rake monoschema:isolation` sème une ligne par table et par ferme, puis relit tout avec le rôle applicatif. **234 tables sur 234** couvertes — aucune ne rend une ligne d'une autre ferme, aucune ne rend quoi que ce soit sans contexte. Une table qu'on ne saurait pas semer serait une affirmation non vérifiée : la tâche les signalerait nommément. La CI la rejoue après l'audit |
| 1.21 | Retirer Apartment (9 fichiers) et le schéma d'agrégation | — |
| 1.22 | Chemin inter-tenants **explicite et audité** (rôle dédié, bypass tracé) : tableau de bord CUMA, benchmark, vue coopérative | le gain fonctionnel du lot |

---

## 4. Lot 2 — Identité et API (ADR-004)

| # | À faire |
|---|---|
| 2.1 | Déployer Keycloak ; importer les comptes V5 une fois, puis Keycloak fait autorité |
| 2.2 | Claim `tenant_id` dans le JWT ; **tous les services le résolvent depuis le jeton**, jamais depuis le sous-domaine |
| 2.3 | Middleware de résolution côté Rails, raccordé au contexte 1.17 |
| 2.4 | Token exchange pour `duke` et `voice-gateway` (jeton délégué, isolation RLS héritée) |
| 2.5 | Retirer Devise du chemin nominal ; conserver le compte de secours `admin` hors tenant |
| 2.6 | Stabiliser et versionner l'API v1 ; décider du sort de l'API v2 existante |
| 2.7 | Device flow / Authorization Code + PKCE pour le mobile |
| 2.8 | **API « très bien documentée, simple et très interopérable » sur les données agricoles** (§ 12.2) : spécification publiée (OpenAPI), versionnée, avec un jeu d'exemples. C'est le contrat que Duke, Zero et les greffons hors Ruby consommeront — il précède leur écriture |

**Dépend de :** lot 1 (le claim n'a de sens qu'avec le contexte tenant).

---

## 5. Lot 3 — Saisie terrain conversationnelle (ADR-005, 006, 007)

| # | À faire |
|---|---|
| 3.1 | `voice-gateway` : port `Channel::Adapter` (`receive_media`, `receive_text`, `send_ack`), adaptateur **Telegram** d'abord |
| 3.2 | ASR asynchrone sur infrastructure propre |
| 3.3 | Repositionner `duke` en **extraction contrainte** : schéma JSON dérivé de `Intervention`, `Observation`, `Task` ; vocabulaires `onoma`/Lexicon en énumérations fermées |
| 3.4 | Pré-résolution d'entités (parcelle, intrant, culture) **avant** l'appel au modèle, sur le contexte du tenant |
| 3.5 | RAG documentaire sur les documents déposés par le client |
| 3.6 | `pending_records` : score de confiance, trace d'extraction, alternatives écartées |
| 3.7 | Écran de validation (mobile et web) ; validation par lot pour la confiance élevée |
| 3.8 | Test automatisé : **aucune écriture métier sans validation explicite** |
| 3.9 | **Adaptateur Matrix** (serveur Synapse auto-hébergé) : la cible de souveraineté. Le port existe pour ça — l'écrire prouve qu'il tient |
| 3.10 | Accusé de réception **unique et groupé** — ne pas répondre dans le fil. La raison n'est plus la facture mais l'ergonomie : un écran de validation vaut mieux qu'un échange de texte (cf. `ui_ux_v6.md`) |
| 3.11 | Documenter la position de souveraineté : le canal ne transporte que le média choisi par l'agriculteur ; transcription et extraction sur infrastructure propre ; rien ne repart chez le fournisseur du canal |
| 3.12 | Adaptateur de repli SMS/e-mail : **prévu dans le port, pas implémenté** |

**Dépend de :** lot 2 (jeton délégué). Mesure de sortie : corpus réel de 200 messages par filière.

---

## 6. Lot 4 — Mobile offline et interfaces par profil (ADR-008, 011)

*Les écrans, les parcours et l'ordre de construction sont détaillés dans
[ui_ux_v6.md](ui_ux_v6.md), qui répond au § 12.2 — concentrer la valeur dans le
moins d'écrans possible, pour les agriculteurs et les conseillers. Ce lot n'en
porte que la charpente technique.*

| # | À faire |
|---|---|
| 4.1 | **Écrire la spec `/sync/v1` avant toute ligne de code** |
| 4.2 | `updated_at` + `deleted_at` (tombstones) sur chaque table synchronisable |
| 4.3 | Politique de conflit **par entité** : dernier écrivain gagne au champ pour observations et tâches ; append-only pour tout objet comptable ou réglementaire |
| 4.4 | BFF : façonner la charge utile au périmètre du client (ses parcelles, sa campagne) |
| 4.5 | `zero-mobile` synchronisé de bout en bout |
| 4.6 | Contrainte de revue de code : toute table destinée au terrain respecte le contrat dès sa création |
| 4.7 | Manifestes d'écran par profil métier ; langage **volontairement pauvre** (liste de blocs typés) |
| 4.8 | Les greffons de niveau 2 injectent leurs blocs dans ces manifestes |

**Dépend de :** ADR-003b (identifiants générés côté client) — donc du lot 1.

---

## 7. Lot 5 — Facture électronique (ADR-009)

*La réception est obligatoire depuis le 1er septembre 2026 : **cette partie est
déjà en retard**. L'émission pour les PME et TPE tombe au 1er septembre 2027.*

| # | À faire | Échéance |
|---|---|---|
| 5.1 | `EInvoicing::Gateway` comme produit : Qonto redevient un adaptateur parmi N | — |
| 5.2 | **Réception** de bout en bout via une Plateforme Agréée, sur un tenant pilote | en retard |
| 5.3 | Choix de la PA **par tenant** (l'agriculteur arrive souvent déjà raccordé chez sa coopérative ou son centre de gestion) | — |
| 5.4 | Domaine émettant et consommant **Factur-X, UBL, CII** propres ; l'investissement va au format, pas aux SDK | — |
| 5.5 | **PDF/A-3** : le moteur de rapport produit du PDF simple. Trancher entre bibliothèque `factur-x` Python et post-traitement Ruby | avant l'émission 2027 |
| 5.6 | Émission conforme validée par **au moins deux PA distinctes** | 1ᵉʳ sept. 2027 |
| 5.7 | e-reporting (250 € par transmission manquante) | — |
| 5.8 | Renommer PDP → **Plateforme Agréée (PA)** dans les specs et le code | avant d'écrire du code |

**Ne pas construire :** comptabilité complète, paie MSA, caisse enregistreuse.
Interopérer (API ISAGRI, AGIRIS, centres de gestion).

---

## 8. Lot 6 — Infrastructure et écosystème (ADR-010, 012)

| # | À faire | Préalable |
|---|---|---|
| 6.1 | **Solid Queue** en remplacement de Sidekiq (décidé) | **plus de préalable** : `solid_queue` 1.7 ne dépend que d'`activejob`, `activerecord`, `railties`, `fugit`, `thor` — pas de `rack`. Le blocage `turnout` ne valait que pour `sidekiq` 8, qu'on n'atteindra jamais puisqu'on quitte sidekiq |
| 6.2 | Base ou rôle **dédié hors RLS** pour Solid Queue / Cache / Cable | lot 1 (sinon files vides ou jobs fantômes) |
| 6.3 | Solid Cache, Solid Cable ; retirer Redis | 6.1 |
| 6.4 | **Sprockets 3.7 + Webpacker 4 → Propshaft** : lot de travail dédié, non un effet de bord | `active_list` est **remplacé intégralement** (décidé) — le front change de toute façon. Le calendrier de Propshaft suit donc celui du lot 7 |
| 6.5 | Sortir de `liquid-rails` (épingle `kaminari` 1.1, paginateur repris à la main) ou le remplacer pour les gabarits d'e-mails | — |
| 6.6 | Manifeste de greffons **out-of-process** : scopes OAuth, webhooks, points d'extension UI | lot 2 |
| 6.7 | Table **outbox** + diffuseur léger — pas de Kafka | — |
| 6.8 | Un greffon de référence hors Ruby, écrit sans modifier le cœur | 6.6 |
| 6.9 | Frontières de modules explicites (Packwerk ou équivalent) **vérifiées en CI** | — |
| 6.10 | APM en production (Scout ou Skylight) et `log_min_duration_statement = 200ms` — aucun APM aujourd'hui | 0.15 |

---

## 9. Lot 7 — Front et API-only (lot G du plan)

| # | À faire |
|---|---|
| 7.1 | Décider du sort d'`active_list` (condamné par ADR-6.2) : ce qui le remplace commande 6.4 |
| 7.2 | Découpler le front ; API-only **après** parité fonctionnelle, pas avant |
| 7.3 | Reprendre les points chauds de performance déjà inventoriés : cascades de rappels sur `Intervention#save` (30-100 requêtes par sauvegarde), `Ekylibre::Record::Sums` en O(N²) à l'import, N+1 des 7 contrôleurs les plus chauds, mémoïsation des 183 appels `Onoma::*`, `insert_all` dans les 112 exchangers, `EXTRACT(YEAR FROM …)` non indexable |

---

## 10. Ordre recommandé

```
Lot 0.0–0.4  suite verte            ─┐
Lot 0.14–0.17 mise en service        ├─ en parallèle, sans dépendance mutuelle
Lot 0.5–0.9  défauts Rails          ─┘
                     │
             1.1–1.3 décisions ADR-003  ← bloquant
                     │
        ┌────────────┴────────────┐
   Lot 1 mono-schéma        Lot 8 Lexicon + onoma
   + isolation              (même reclassement des modèles)
        └────────────┬────────────┘
                     │
             Lot 2   Keycloak et API (dont 2.8 : l'API documentée)
                   ┌─┴─┐
           Lot 3 saisie   Lot 4 mobile + UI/UX
                   └─┬─┘
             Lot 9   restauration des archives v5
             Lot 11  staging Dokploy
             Lot 6   infrastructure
             Lot 10  plugins niveau A ─┐ se confond avec 4.7
             Lot 7   front            ─┘ (manifestes d'écran)

Lot 5  facture électronique  ← indépendant, calendrier réglementaire propre
```

Quatre remarques sur cet ordre.

**Le lot 5 ne dépend d'aucun autre** : sa contrainte est réglementaire, et la
réception est déjà en retard — il peut démarrer tout de suite, par l'adaptateur
d'une seule PA.

**Le lot 0 avant tout le reste** n'est pas une précaution de principe : un
chantier qui ajoute `tenant_id` à 240 tables et des politiques RLS partout
produira des régressions, et il faut qu'elles soient visibles.

**Les lots 1 et 8 vont ensemble.** Le mono-schéma reclasse les modèles en trois
plans, dont le référentiel ; sortir Lexicon dans sa propre base reclasse les
mêmes 53 modèles. Les séparer, c'est faire deux fois le même travail sur les
mêmes fichiers.

**Les lots 10 et 4.7 sont le même mécanisme.** Le manifeste d'écran par profil
métier (ADR-011) et le plugin déclaratif de niveau A demandent tous deux une
description de blocs typés rendue par le cœur. En spécifier deux serait en
inventer un de trop.

---

## 11. Décisions à trancher, par échéance

| Sujet | Échéance | Bloquant pour |
|---|---|---|
| ~~Type de `tenant_id`, périmètre UUIDv7, version PostgreSQL~~ — **tranché : PG 18, UUIDv7 terrain, `tenant_id` uuid + slug** | 13 septembre 2026 | lot 1 débloqué |
| ~~Déployer avant ou après le mono-schéma~~ — **tranché : après**, sur le staging `ekylibre.io` | 13 septembre 2026 | 0.15, lot 11 |
| Ordre de la dette du lot 0 | maintenant | lisibilité du lot 1 |
| ~~Sortie de `turnout`~~ — **sans objet pour la file** : Solid Queue ne dépend pas de `rack`. Reste un frein pour Rack 3 seul | — | — |
| ~~Remplacement d'`active_list`~~ — **tranché : remplacement intégral**, le front change | 13 septembre 2026 | 6.4, lot 7 |
| PDF/A-3 : Python ou Ruby | avant l'émission | 5.5 |
| Périmètre du langage de manifeste d'écran | lot 4 | 4.7 |
| Liste des PA prioritaires | lot 5 | 5.3 |
| Sort d'`Ekylibre::Plugin` | opportuniste | 0.12, 10.3 |
| ~~Canal de saisie terrain et « 100 % open source »~~ — **tranché** : WhatsApp écarté, Telegram en production, Matrix en cible | 13 septembre 2026 | ADR-005 révisé |
| Quand passer de Telegram à Matrix, et avec quel serveur | après 3.1 | 3.9 |
| **Comment faire tourner les tests des greffons** : une CI par dépôt, ou un `Gemfile.ci` dans celle du cœur | avant le lot 1 | 0.18, et toute reprise de greffon |
| **Périmètre de Lexicon** : ce qui part en base séparée et ce qui reste au cœur | avec le lot 1 | lot 8 entier |
| ~~Domaine du staging~~ — **tranché : `ekylibre.io`** | 13 septembre 2026 | 11.2, 11.3 |

---

## 12. Guide et régles ajoutées par le chef de projet historique (David)

### 12.1 Objectifs à 1 an

- Renover technologiquement la stack Ekylibre en conservant 100% de briques open source
- Developper une vrai communauté "utilisateurs" et "developpeurs" au travers d'OSFarm
- Rendre les interfaces user-friendly et très simple d'usage
- Permettre aux utilisateurs de faire évoluer la solution très simplement
- Faciliter la gestion des fonctionnalités supplémentaires (plugins)

### 12.2 Contraintes à respecter

- L'UI et L'UX vont fortement évoluer donc l'ensemble des vues et controlleurs aussi. Je te donnerais des exemples où nous allons chercher à concentrer la valeur et les fonctionnalités dans le moins d'ecran possible pour simplifier l'usage par les agriculteurs et les conseillers agricoles (comptable, technicien, ...) voir le fichier 'docs/planning/ui_ux_v6.md'

- un dump d'une ancienne version d'Ekylibre 5.0 doit être restaurable dans la version 6.0 (exemples present dans /home/djoulin/projects/ekylibre/tmp/archives notamment : closeriedesterres.zip, phaurigot.zip, sci-chenes-verts.zip). Il faudra prévoir d'adapter la méthode de restauration des tenants en conséquence (db + fichiers)

- le systeme de plugins doit évoluer vers un systeme plus simple permettant à des utilisateurs de décrire leur besoin et de le faire developper par Claude Code par exemple. En terme technique, il doit soit être independant (React via API Rails 8.1) ou au sein d Ekylibre via Hotwire et autres.
Je te laisse faire une analyse de l'existant pour me donner la meilleure solution sachant que les modèles et migrations necessaires aux plugins sont portées exclusivement par Ekylibre.

- les fonctionnalités "IA" seront portés par Duke (python) et pourront être appellées depuis Ekylibre ou Zero

- les fonctionnalités "Dictionnaires de références" ou "données de référence" seront portés par Lexicon

- Une API très bien documenté, simple et très interopérable sur les données agricoles sera necessaire.

### 12.3 Composants

- l'architecture globale integrant Ekylibre 6.0 comportera les elements suivants :

        1. Le projet **Lexicon** (https://github.com/osfarm/lexicon) qui pourra évoluer si besoin et qui sera accessible dans Ekylibre au sein d'une DB à part et non plus un schéma, il faudra donc adapter les méthodes de chargement (load et autres) et les modèles 'lexicon' pour pouvoir charger le lexicon dans une DB à part. Le lexicon comporte toutes les données de référence, open data et autres ainsi que des données vectorisées pour l'usage de l'IA plus tard. D'autres micro-services s'y connecterons. La gem onoma est déjà présente (https://github.com/osfarm/lexicon/blob/main/lib/datasources/open_nomenclature.rb) et ne sera donc plus necessaire dans Ekylibre 6.0 (item dans la roadmap à prévoir).

        2. Le projet **Duke** (https://github.com/ekylibre/duke) qui pourra évoluer si besoin comportera les traitements IA et pourra utiliser le lexicon et ekylibre.

        3. Le projet **Zero** (https://github.com/ekylibre/zero-mobile) qui pourra évoluer si besoin comportera les fonctionnalités orientées "Utilisateur Terrain" et se reposera sur Ekylibre, Lexicon et Duke

        4. Autres services necessaires si besoins au sein du meme reseau interne Docker

        L'ensemble de cette architecture doit être présente dans un Docker Compose déployable sur Dokploy pour une première version **staging** lié au domaine "ekylibre.org" ou "ekylibre.io"

---

## 13. Lot 8 — Lexicon en base séparée, et sortie d'`onoma` (§ 12.3.1)

*Le plus gros lot issu du guide, et le plus sous-estimé : `onoma` n'est pas une
dépendance de bordure, c'est le vocabulaire du domaine.*

### 13.1 Ce que pèse la sortie d'`onoma`

| Mesure | Volume |
|---|---:|
| Appels `Onoma::*` dans `app/` et `lib/` | **444**, répartis sur **148 fichiers** |
| Déclarations `refers_to` (attributs résolus contre une nomenclature) | **126** |
| Modèles du lexique (`Master*`, `Registered*`) | **53** |

Et une dépendance en travers, qui commande l'ordre : **`active_list` dépend de
la gem `onoma`** (`active_list 8.1.0 → onoma ~> 0.4`). Sortir `onoma` suppose
donc d'avoir traité `active_list`, déjà condamné par l'ADR-6.2 — les deux lots
se tiennent.

| # | À faire |
|---|---|
| 8.1 | Inventorier les 444 appels par nature : lecture d'item, résolution `refers_to`, énumération, traduction. Ce sont quatre besoins différents, et ils ne se remplacent pas de la même façon |
| 8.2 | Définir le contrat que Lexicon expose en remplacement — lecture d'item, liste, hiérarchie, libellés traduits — avant de toucher un appelant. **Le dépôt `osfarm/lexicon` n'est pas sur la machine de développement** : ce contrat s'écrit donc *à destination* de Lexicon, comme une spécification que le projet devra honorer, et se vérifie ensuite par accès distant |
| 8.3 | Remplacer les 126 `refers_to` : c'est le cœur du sujet, puisqu'ils portent la validation et les prédicats |
| 8.4 | Retirer la gem du `Gemfile` — après `active_list` |

### 13.2 Lexicon en base distincte

Aujourd'hui le lexique est un **schéma** dans le `schema_search_path`
(`public,postgis,lexicon`), ce qui autorise les jointures SQL avec les tables
applicatives. En base séparée, ActiveRecord ne joint plus entre connexions.

| # | À faire | Volume mesuré |
|---|---|---|
| 8.5 | `LexiconRecord` sur une connexion dédiée (`connects_to`, natif en Rails 8.1) | 53 modèles |
| 8.6 | **Convertir les associations qui traversent la frontière** en résolutions applicatives ou en appels d'API | **43 associations** vers `Master*`/`Registered*`, dont **5 `belongs_to`** directs |
| 8.7 | Adapter `lexicon:load` et l'écran d'administration : la cible n'est plus un schéma de la base applicative | `lib/tasks/lexicon.rake`, `Admin::LexiconController` |
| 8.8 | Retirer `lexicon` du `schema_search_path` et des dumps de tenant | `config/database.yml`, `Ekylibre::Tenant.dump` |
| 8.9 | Prévoir l'accès concurrent : Duke et Zero se connecteront au même lexique | — |

**Bonne nouvelle mesurée :** aucune jointure SQL brute vers `lexicon.` dans le
code applicatif. Le couplage est entièrement porté par ActiveRecord, donc
localisable et mécanisable.

**Ordre :** ce lot dépend du mono-schéma (lot 1), qui reclasse déjà les modèles
en trois plans dont le référentiel. Faire les deux d'un seul geste évite de
reclasser deux fois les mêmes 53 modèles.

---

## 14. Lot 9 — Restauration des archives v5 (§ 12.2)

*Contrainte : « un dump d'une ancienne version d'Ekylibre 5.0 doit être
restaurable dans la version 6.0 », base **et** fichiers.*

Archives de référence présentes dans `tmp/archives/` :

| Archive | Taille |
|---|---:|
| `closeriedesterres.zip` | 62 Mo |
| `sci-chenes-verts.zip` | — |
| `phaurigot.zip` | — |
| *(pour mémoire)* `domainedes5autels.zip` | **9,9 Go** |
| *(pour mémoire)* `entredeuxterres.zip` | 1,5 Go |

| # | À faire |
|---|---|
| 9.1 | Restaurer une archive v5 **telle quelle** sur la 6.0 : c'est le test d'acceptation du lot, à écrire en premier |
| 9.2 | Injection de `tenant_id` à l'import, **en conservant les `id` d'origine** (les archives en dépendent) |
| 9.3 | Recalage automatique des séquences globales — jamais une étape manuelle |
| 9.4 | Reprise des fichiers joints : la v5 a connu Paperclip puis Active Storage, une archive ancienne porte l'ancienne arborescence |
| 9.5 | Contrôles d'intégrité : comptes par table, FK composites intra-tenant, validation géométrique PostGIS |
| 9.6 | Idempotence : un import interrompu se reprend |
| 9.7 | Tenir l'échelle : 9,9 Go pour une seule exploitation, l'import ne peut pas tout charger en mémoire |

**Rappel de sécurité :** la restauration était une RCE ouverte (nom de fichier
d'archive passé à `psql`), corrigée par `validate_name!`. Toute réécriture de ce
chemin doit conserver cette validation.

---

## 15. Lot 10 — Système de plugins : analyse et recommandation (§ 12.2)

**Ce que l'existant dit**, mesuré :

- **19 greffons**, tous des Rails engines in-process, montés par `Gemfile.local` ;
- `Ekylibre::Plugin` — le registre maison, ~300 lignes — **est mort** : le
  répertoire `plugins/` est vide, `registered_plugins` rend `[]`. Ce que font
  réellement les greffons, ce sont des engines que Rails indexe seul ;
- **aucun n'a de CI**, et la suite du cœur ne ramasse pas leurs tests ;
- le couplage part dans les deux sens : le cœur portait jusqu'ici des tests et
  des constantes d'un greffon (corrigé pour `hve`, à surveiller ailleurs) ;
- contrainte du guide : **les modèles et migrations restent portés par
  Ekylibre**.

**Recommandation.** Ne pas introduire un second runtime tant que rien ne
l'exige. La contrainte « les modèles et migrations sont au cœur » ferme d'ailleurs
la porte au plugin hors-processus autonome : un greffon qui ne peut ni créer de
table ni déclarer de modèle n'a plus besoin d'un processus à lui — il a besoin
d'**un manifeste et de points d'extension**.

Trois niveaux, du moins coûteux au plus coûteux, à ouvrir dans cet ordre :

| Niveau | Ce qu'il permet | Ce qu'il coûte |
|---|---|---|
| **A — déclaratif** | un manifeste décrit des écrans, des blocs de tableau de bord, des champs supplémentaires, des exports. Rendu par Hotwire côté cœur. C'est ce qu'un utilisateur peut faire décrire à un assistant sans écrire de Ruby | le langage de manifeste (ADR-011), à garder pauvre |
| **B — engine** | ce qui touche au modèle, aux migrations, au métier : les 19 greffons actuels | l'existant, plus une CI (lot 0.18) |
| **C — hors-processus** | un service tiers qui consomme l'API avec un jeton délégué et reçoit des webhooks | Keycloak (lot 2), l'outbox, l'API documentée (2.8) |

**Le niveau A est le seul qui réponde à l'objectif « permettre aux utilisateurs
de faire évoluer la solution très simplement »** ; B et C existent déjà ou
découlent d'autres lots. C'est donc lui qu'il faut spécifier en premier, et il
se confond largement avec les manifestes d'écran de l'ADR-011 — un seul mécanisme
sert les deux besoins, ce qui est un argument pour ne pas en inventer un second.

| # | À faire |
|---|---|
| 10.1 | Spécifier le manifeste de niveau A : blocs typés, points d'ancrage, champs supplémentaires. **Volontairement pauvre** |
| 10.2 | Un greffon de référence écrit en niveau A seul, sans Ruby, comme preuve |
| 10.3 | Trancher le sort d'`Ekylibre::Plugin` (retirer ou documenter) — cf. 0.12 |
| 10.4 | Documenter la frontière : ce qu'un greffon peut faire sans toucher au cœur, et ce qui impose un engine |

---

## 16. Lot 11 — Déploiement staging (§ 12.3.4)

*Cible : un Docker Compose déployable sur Dokploy, lié à `ekylibre.org` ou
`ekylibre.io`.*

| # | À faire |
|---|---|
| 11.1 | Un `docker-compose` de staging réunissant `eky-core`, Lexicon (base séparée, lot 8), Duke, Zero et les services d'appui, sur un même réseau interne |
| 11.1b | **Y déclarer le service Keycloak** — l'instance est en cours de création côté infrastructure ; le compose doit la porter, pas la découvrir |
| 11.2 | Reverse proxy et certificats (Traefik selon l'architecture) ; nommage des services aligné sur l'architecture |
| 11.3 | ~~Choisir le domaine~~ — **tranché : `ekylibre.io`**, Dokploy est disponible |
| 11.4 | Sauvegardes et restauration éprouvées **avant** d'y mettre une exploitation réelle ; le lot 9 en fournit le mécanisme |
| 11.5 | Observabilité minimale : journaux centralisés et APM (cf. 6.10) |
| 11.6 | Faire de ce staging la cible de `build-prod-image` (cf. 0.16), au lieu d'un déploiement manuel |

**Dépend de :** rien techniquement, mais un staging n'a d'intérêt qu'avec de
quoi le peupler — donc après le lot 9.
