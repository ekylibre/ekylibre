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

316 tables, au 15 septembre 2026, questionnaire dépouillé :

| | |
|---|---:|
| plan de données | **234** |
| plan de contrôle | 2 |
| référentiel | 78, dont **5 à déplacer** depuis `public` |
| à supprimer | 2, plus une suppression conditionnelle |
| clés en UUIDv7 (ADR-003) | 40 |
| clés en `bigint` | 194 |
| PK composites à poser | 234 |
| index uniques à préfixer par `tenant_id` | 38 |
| clés étrangères déclarées, cible au plan de données | 159 |
| clés étrangères déclarées, cible hors tenant | 8 |
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

**Huit clés étrangères pointent hors du plan de données, et toutes vers
`units`.** Avant le dépouillement il n'y en avait aucune : le référentiel était
désigné par des codes (`usage_id` est une chaîne), jamais par une clé. C'est la
décision de déplacer `units` vers le `lexicon` qui les crée. Ces huit-là ne
deviennent pas composites — leur cible n'aura pas de `tenant_id` — et c'est
précisément ce que le plan doit dire au générateur du point 1.6.

**Les 14 tables sans clé primaire sont toutes du `lexicon`.** Ce sont celles qui
retiennent `raise_on_missing_required_finder_order_columns` (point 0.8) : leur
donner une clé, c'est décider ce qui identifie une ligne dans chaque référentiel
importé. Le lot 1 les rencontre de nouveau ici.

## Du plan au schéma (points 1.6 à 1.8)

Le plan n'est pas un document : il est exécutable. Trois tâches l'emploient, et
la CI les rejoue à chaque passage.

```bash
rake monoschema:references     # -> references.yml : ce que chaque colonne désigne
rake monoschema:schema         # -> schema.sql : la forme d'arrivée, 314 tables
rake monoschema:schema:build   # la charge dans une base neuve
rake monoschema:audit          # six invariants d'isolation, sur la base
```

**Les références se résolvent dans les modèles, pas dans le schéma.** Le schéma
ne déclare que 159 clés étrangères ; les `belongs_to` en savent bien plus. Sur
les 1 047 colonnes de référence du plan de données :

| | |
|---|---:|
| résolues vers le plan de données — clé composite | **1 000** |
| résolues vers le référentiel — clé simple | 15 |
| polymorphes — aucune contrainte possible | 22 |
| qu'aucun modèle ne résout | **10** |

Les dix dernières n'ont pas de `belongs_to` parce qu'elles n'ont pas
d'association : `products.fixed_asset_id` existe alors que le lien va dans
l'autre sens (`fixed_assets.product_id`), `sales.subscription_id` alors que
l'association passe par les lignes de vente, `interventions.parent_id` alors que
le code ne s'en sert que comme d'un drapeau. Ce sont des colonnes orphelines :
le générateur les porte telles quelles, sans contrainte, en attendant qu'on
décide de les retirer.

**Le schéma d'arrivée se charge.** `schema.sql` fait 314 tables — les 316 moins
les deux supprimées — et s'est chargé sans une erreur dans une base vide dès la
première tentative. La base de sonde porte alors :

| | |
|---|---:|
| tables dans `ekylibre` | 237 (234 de données, 2 de contrôle, `tenants`) |
| tables dans `lexicon` | 78 |
| colonnes `tenant_id` | 234 |
| politiques RLS, activées **et** forcées | 234 |
| clés primaires composites | 246 |
| **clés étrangères composites** | **1 000** |
| clés étrangères simples (vers le référentiel) | 15 |
| index GiST composites | 35 |

**Les six invariants tiennent.** `monoschema:audit` les vérifie sur la base, pas
sur le fichier — c'est le linter du point 1.7 et le scan de `pg_indexes` du
point 1.8 réunis :

1. toute table du plan de données porte `tenant_id NOT NULL` ;
2. sa clé primaire est composite et commence par `tenant_id` ;
3. la RLS y est activée *et* forcée ;
4. sa politique filtre la lecture (`USING`) comme l'écriture (`WITH CHECK`) ;
5. aucun index unique ne commence ailleurs qu'à `tenant_id` ;
6. toute clé étrangère entre deux tables du plan de données est composite.

## Les vues, et ce qu'elles cachent (point 1.10)

**Une vue ordinaire contourne la Row Level Security.** Elle s'exécute avec les
droits de son propriétaire, et le propriétaire n'est pas soumis aux politiques
de ses propres tables. Mesuré sur la sonde, deux vues sur la même table, lues
par le rôle applicatif sous le contexte d'une seule ferme :

| | Lignes rendues |
|---|---|
| vue ordinaire | **les deux fermes** |
| vue `WITH (security_invoker = true)` | une seule |
| table interrogée directement | une seule |

Les onze vues de l'application sont donc engendrées avec `security_invoker`, et
un invariant de `monoschema:audit` échoue sur toute vue qui n'en porterait pas.
Le piège est d'autant plus sournois que plusieurs de ces vues servent de tables
de jonction à Rails — `activities_interventions`, `campaigns_interventions` —
et sont donc sur des chemins chauds.

**Les trois vues matérialisées ne sont pas reprises, et pour une raison plus
grave que l'isolation.** PostgreSQL n'applique pas la RLS à une vue
matérialisée : ses lignes sont calculées une fois, toutes fermes confondues. On
pourrait s'en protéger par une vue de filtrage. Mais le vrai problème est
ailleurs : **leur regroupement ne porte pas `tenant_id`**.
`worker_time_indicators` regroupe par `worker_id` ; en mono-base, deux fermes
ont chacune leur travailleur n° 1, et leurs heures se retrouveraient
*additionnées dans la même ligne*. Ce n'est plus une fuite, c'est un chiffre
faux — et un chiffre faux sur des heures de travail.

Les trois demandent d'être réécrites à la main pour porter et regrouper par
`tenant_id`, ce qu'aucune réécriture mécanique ne peut faire sur des requêtes
de cinquante à cent lignes. `worker_time_indicators` pose en plus une question
de coût : elle est rafraîchie à **chaque sauvegarde d'intervention**, et un
`REFRESH` en mono-base recalcule toutes les fermes. Elle est déjà signalée comme
point chaud dans `CLAUDE.md` ; le mono-schéma transforme ce point chaud en
problème d'échelle.

## La recopie des données

```bash
SCOPE=inplace rake monoschema:schema   # -> schema-inplace.sql, sans le lexicon existant
rake monoschema:migrate TENANTS=alpha,beta
rake monoschema:migrate:check          # deux fermes jetables, de bout en bout
```

La migration se mène **dans la base du client**, à côté des schémas par ferme :
le schéma `ekylibre` est créé, les lignes y sont recopiées ferme par ferme, puis
les anciens schémas peuvent partir. Trois choses la rendent plus simple qu'on ne
le craignait, et une la complique.

**Les clés entières ne bougent pas.** Deux fermes ont toutes deux un
`products.id = 1` : la clé primaire composite `(tenant_id, id)` l'accepte. Il
n'y a donc **rien à renuméroter sur 194 des 234 tables** — la « renumérotation
des PK » que la feuille de route annonçait n'a pas lieu d'être.

**Les 40 tables à clé UUIDv7 en demandent une, elle.** Avec elles, les **132
colonnes qui les désignent**, réparties dans 73 tables. Une table de
correspondance par table et par ferme porte l'ancien entier et le nouvel uuid ;
la recopie joint dessus.

**L'uuid engendré porte la date de la ligne, pas celle de la migration.**
PostgreSQL 18 accepte un décalage : `uuidv7(created_at - now())` produit un
identifiant dont le préfixe temporel est celui de la création. Sans cela, dix
ans d'historique s'entasseraient au même endroit de l'index — l'argument même
qui a fait préférer UUIDv7 à UUIDv4 serait perdu à la migration.

**Ce qui la complique** : elle contourne la RLS. Elle s'exécute avec un rôle qui
la traverse — superutilisateur, ou propriétaire après `DISABLE ROW LEVEL
SECURITY` — et met les contraintes en sommeil (`session_replication_role =
replica`) le temps de la recopie, le graphe des références ayant des cycles.
C'est une raison de plus pour que l'application, elle, ne se connecte jamais
ainsi.

`monoschema:migrate:check` monte deux fermes jetables, y sème des lignes aux
identifiants volontairement identiques, migre, puis vérifie huit choses : les
deux fermes sont enregistrées, les quatre produits sont là, les identifiants
entiers sont conservés collisions comprises, les interventions ont des uuid
distincts, **l'uuid porte la date de création**, chaque paramètre pointe une
intervention de sa propre ferme, les séquences repartent au-dessus du plus grand
`id`, et les politiques sont intactes. La CI le rejoue.

Ce que la recopie ne fait **pas** encore : dédupliquer les cinq tables qui
passent au référentiel, ni reprendre les onze vues et trois vues matérialisées
— c'est le point 1.10. Elle n'a par ailleurs été mesurée que sur des fermes
jetables : le volume réel, lui, se mesurera sur une copie de production.

## Le contexte de ferme (points 1.17 et 1.18)

`lib/ekylibre/tenancy.rb` est le pendant applicatif de la Row Level Security :
la base refuse de rendre quoi que ce soit tant que `app.tenant_id` n'est pas
posé, et c'est là qu'il se pose.

```ruby
Ekylibre::Tenancy.with(tenant_id) { Product.count }
Ekylibre::Tenancy.without_tenant { ... }   # le chemin explicite, et cherchable
Ekylibre::Tenancy.current!                 # lève plutôt que de rendre nil
```

Rien n'en est branché sur l'application tant qu'Apartment est en place : ce
fichier vit à côté, et sept tests l'éprouvent (`test/lib/ekylibre/tenancy_test.rb`).
Quatre précautions y sont inscrites, toutes apprises en mesurant :

1. **`SET LOCAL` porte sur la transaction, pas sur le bloc Ruby.** Dans un
   savepoint, le réglage survivrait à la sortie du bloc ; le contexte rétablit
   donc lui-même la valeur précédente, ce qui rend au passage deux contextes
   imbricables ;
2. **le cache de requêtes ignore le tenant** : il est indexé sur le seul texte
   SQL, et resservirait sous B une lecture faite sous A. Il est vidé de part et
   d'autre ;
3. **hors transaction, `SET LOCAL` n'a aucun effet** — PostgreSQL le dit dans un
   avertissement. Le contexte en ouvre donc une, et c'est elle qui le fait
   mourir à la sortie. C'est le choix le plus sûr ; l'autre — poser le réglage
   sur la connexion et le nettoyer à son retour au pool — évite des transactions
   longues mais confie l'isolation à un `ensure` de plus ;
4. **une exception ne laisse rien derrière elle.**

**Les jobs emportent leur ferme** (`Ekylibre::Tenancy::JobPropagation`) : le
tenant voyage dans la sérialisation, comme `apartment-sidekiq` le fait
aujourd'hui du nom de schéma, et le job rétablit le contexte le temps de son
exécution. Un job enfilé sans ferme — une tâche d'administration — s'exécute
sans contexte plutôt qu'avec un contexte inventé.

## Les associations, et ce que l'annotation achète vraiment (point 1.16)

`rake monoschema:associations` inventorie ce que devient chaque association des
312 modèles du plan de données. **4 167 associations** — la feuille de route en
annonçait 1 413, elle comptait plus étroitement :

| | |
|---|---:|
| à annoter en `foreign_key: %i[tenant_id …]` | **3 532** |
| rien à faire — `:through` (513) ou cible hors tenant (90) | 603 |
| à reprendre à la main — 22 polymorphes, 10 HABTM | **32** |

**Mais l'annotation n'est pas ce qu'on croyait.** Mesuré sur la sonde, avec deux
fermes portant le même `products.id = 999` :

| `produit.parametres` | Sous la RLS (l'application) | Sans la RLS (migration, administration) |
|---|---|---|
| sans annotation | 1 ligne — la bonne | **2 lignes — celles des deux fermes** |
| avec `foreign_key: %i[tenant_id product_id]` | 1 ligne | 1 ligne |

Autrement dit : **la RLS fait déjà le travail sur les chemins ordinaires**. Une
association non annotée y produit du SQL juste, parce que la politique filtre.
L'annotation compte ailleurs — sur tout ce qui traverse la politique : les
migrations, les tâches d'administration, `without_tenant`, et les requêtes
inter-fermes du point 1.22.

Cela change la manière de mener le point 1.16 : ce n'est pas un codemod qui doit
atterrir d'un bloc avant que quoi que ce soit ne fonctionne, mais une **seconde
ceinture**, à poser par domaine, en commençant par les modèles qu'empruntent les
chemins qui contournent la RLS. Et c'est aussi ce qui rend la RLS non
négociable : sans elle, 3 532 associations deviennent autant de fuites
possibles.

Les 32 cas manuels se répartissent en deux familles, et aucune ne demande
d'annotation : les **polymorphes** (`Attachment#resource`,
`JournalEntry#resource`, `Issue#target`…) ne peuvent pas porter de clé composite
puisque leur cible change d'une ligne à l'autre — la RLS les couvre des deux
côtés ; les **HABTM** passent par les onze vues de jonction, elles-mêmes filtrées
par `security_invoker`. Les uns et les autres sont à vérifier, pas à réécrire.

## Le SQL écrit à la main (point 1.19)

`rake monoschema:raw_sql` recense **190 sites** et les classe par ce qui leur
arrive — pas par la syntaxe qu'ils emploient.

| | |
|---|---:|
| sans objet : ne touchent aucune table du plan de données | 72 |
| sans objet sous RLS : la politique filtre aussi le SQL brut | 17 |
| à relire : écritures en masse et jointures écrites à la main | 97 |
| **à reprendre** : elles échouent | **4** |

**Le SQL brut n'est pas un trou dans l'isolation.** Une requête écrite à la main
et posée sous un contexte de ferme est filtrée comme les autres, jointures
comprises : deux tables filtrées chacune sur la même ferme ne peuvent pas se
joindre entre fermes. C'est tout l'intérêt d'avoir mis l'isolation dans la base
plutôt que dans un `default_scope`. Ce que le SQL brut risque, c'est la
*rupture*.

Et les deux ruptures sont bruyantes, ce qui est la bonne nouvelle. Mesurées :

| Ce qu'on écrivait avant | Ce que PostgreSQL répond maintenant |
|---|---|
| `INSERT INTO products (id, …)` sans `tenant_id` | `new row violates row-level security policy for table "products"` |
| `… ON CONFLICT (number)` | `there is no unique or exclusion constraint matching the ON CONFLICT specification` |

La première surprend : c'est la politique qui refuse, pas la contrainte `NOT
NULL`, parce que `WITH CHECK` est évaluée d'abord. Peu importe — dans les deux
cas, rien ne passe en silence.

Les 97 « à relire » sont une précaution, pas un diagnostic : ce sont les
`update_all`, `delete_all` et jointures littérales qui touchent une table du
plan de données. La RLS les couvre ; ce qu'il faut y vérifier est la clé
composite et, pour les `update_all` joints, la compilation en `UPDATE … FROM`
que Rails 8.1 emploie — `CLAUDE.md` en documente déjà deux victimes.

## Les tests d'isolation (point 1.20)

Deux affirmations, pour *chacune* des 234 tables du plan de données : sans
contexte de ferme, elle ne rend aucune ligne ; sous la ferme A, elle n'en rend
jamais une de la ferme B. Elles ne se démontrent pas en lisant le schéma — il
faut des lignes, et il faut les lire avec le rôle applicatif.

```bash
rake monoschema:isolation
```

La tâche sème une ligne par table et par ferme, en ne remplissant que les
colonnes obligatoires avec des valeurs quelconques du bon type, puis relit tout
sous chaque contexte. Au 15 septembre 2026 :

| | |
|---|---:|
| tables semées dans deux fermes et relues | **234 sur 234** |
| qui rendent une ligne d'une autre ferme | 0 |
| qui rendent quoi que ce soit sans contexte | 0 |

La couverture est totale, et c'est ce qui compte : une table qu'on n'aurait pas
su semer serait une affirmation non vérifiée, et la tâche les signale nommément
plutôt que de les passer sous silence. La CI la rejoue après l'audit.

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

## Les sept questions, tranchées le 15 septembre 2026

Le questionnaire est revenu rempli. Aucune des sept n'était technique, et les
réponses ouvrent chacune un travail :

**Cinq tables passent au référentiel partagé** — `districts`, `postal_zones`,
`vegetative_stages`, `net_services`, `units`. Elles n'y sont pas encore : elles
vivent dans `public` et portent les lignes de *chaque* ferme. Les y porter, ce
n'est pas déplacer une table, c'est **dédupliquer N jeux de lignes en un seul**,
puis réécrire les colonnes qui les désignent. Le volume est mesuré :

| Table | Colonnes qui la désignent | Ce que le déplacement coûte |
|---|---:|---|
| `postal_zones` | 0 | rien à réécrire |
| `districts` | 1 | `postal_zones.district_id`, qui part avec elle |
| `net_services` | 1 | `identifiers.net_service_id` |
| `vegetative_stages` | 2 | `yield_observations`, `products_yield_observations` |
| **`units`** | **10, dans 10 tables** | à **fusionner** avec `master_units`, pas seulement à déplacer |

`units` est le vrai morceau, et pas seulement par le nombre : la table est en
STI (`Unit`, `ReferenceUnit`, `Conditioning`), elle est mentionnée 298 fois, et
**une ferme peut aujourd'hui créer une unité depuis un écran** — ce qu'elle ne
pourra plus. C'est une décision fonctionnelle autant que technique ; elle mérite
d'être confirmée avant que la migration ne soit écrite.

**Deux tables sont supprimées** : `saas_subscriptions`, l'ancienne gestion des
abonnements — c'est elle qui portait le `tenant_name`, ce lien inter-tenant en
chaîne de caractères —, et `user_tickets`, que trois lignes de code mentionnent.
Les supprimer n'est pas qu'une migration : un écran, des routes et des vues
partent avec elles.

**`users` est une suppression conditionnelle.** La table historique des
utilisateurs d'une ferme disparaît *si* le trio du point 1.14 porte les accès et
les droits. Devise s'en sert encore : elle reste au plan de données, et la
décision se solde au lot 2, avec Keycloak.

## Le choix de clé, qui est le seul irréversible

**40 tables** prennent une clé UUIDv7 — 25 à la première passe, quinze ajoutées
au dépouillement : le parcellaire (`activity_productions`, `cultivable_zones`,
les quatre tables PAC, `georeadings`), le CVI en entier, la traçabilité
(`trackings`), les apports de récolte, les observations de rendement, les
trajets d'engins et les lignes d'inventaire. Toutes se créent ou se corrigent
sur le terrain. Le critère n'est pas l'importance de la
table, c'est **« le mobile peut-il en créer une ligne sans réseau ? »** — une
intervention et tout ce qui naît du même geste, une observation, un incident
signalé depuis la parcelle, une trace GPS, un comptage, un pointage, une
photo. Le reste garde une clé entière, y compris ce que le serveur seul
engendre : écritures comptables, mouvements de stock, lignes de TVA.

La liste est dans `classification.yml`, chaque table avec sa raison. Elle peut
grandir tant que les migrations ne sont pas écrites ; après, plus.
