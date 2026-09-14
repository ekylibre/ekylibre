# Ekylibre v6 — État des lieux au 14 septembre 2026

> Document de reprise. Il dit où en est le chantier, ce que la montée de version a
> laissé derrière elle, et ce qu'il faut avoir tranché avant d'ouvrir le lot
> suivant. Les efforts et le détail des actions restent dans
> [v6-improvement-plan.md](v6-improvement-plan.md) ; l'inventaire des dépendances
> dans [v6-dependency-audit.md](v6-dependency-audit.md).

**Branche** : `6.0-alpha` (anciennement `ekylibre-6.0`, `-7.0`, `-7.1`, renommée à
l'arrivée en 8.1 ; les branches de paliers sont supprimées, chacune étant un
ancêtre de celle-ci).

---

## 1. Où l'on en est

| | Avant le chantier | Aujourd'hui |
|---|---|---|
| Rails | 5.2 (EOL) | **8.1.3.1**, valeurs par défaut 8.1 |
| Ruby | 2.6 | **3.4.10** (dev et CI) |
| PostgreSQL | 13 (serveur et client) | **18.6 / PostGIS 3.6** en dev et CI, client 18 dans l'image de base — `uuidv7()` native disponible |
| Production | Ruby 2.6, Rails 5.2, PostgreSQL 13 | **inchangée** — rien n'est déployé |
| Suite | 3650 tests, 17 échecs, 15 erreurs | **3621 tests, 0 échec, 0 erreur, 4 ignorés** — mesuré en local le 14 septembre, suite entière, 26 min |
| Job `Tests` de la CI | rouge depuis toujours | vert au prochain passage |
| RuboCop | 1.11, plantait sous Ruby 3.4 | **1.91, sort au vert** (809 offenses au todo) |
| ESLint | 1657 erreurs | **0 erreur** |
| CodeQL | n'analysait aucune branche active | vert sur `6.0-alpha` |

Le lot B est achevé : **la cible du plan est atteinte**. Le critère de sortie
retenu à chaque palier était la parité de la suite, jamais le simple démarrage de
l'application — et il a été tenu huit fois de suite, framework puis valeurs par
défaut.

**Le lot 0.1 est achevé à son tour** : les 32 cas rouges hérités des paliers sont
traités. La référence n'est donc plus la parité mais zéro — un rouge est
désormais une régression à expliquer. Le compte de tests passe de 3650 à 3620
sans qu'aucun n'ait été perdu de vue : 27 tests HVE sont partis avec le
découplage cœur/greffon, et 3 couvraient la page Exports supprimée en A.4.

## 2. Ce que la montée a appris

**Les gems coûtent plus que le code.** Cinq montées bloquantes
(`activerecord-postgis-adapter` 9→11, `paranoia`, `validates_timeliness`,
`bullet`, `sidekiq` 4→7.3), et trois gems qui retiennent encore le reste :
`wice_grid` (bloque `default_column_serializer`), `turnout` (retient `rack` sous
la 3, donc `sidekiq` sous la 8), `liquid-rails` (épingle `kaminari` 1.1, dont le
paginateur est repris à la main).

**Les ruptures du cadriciel révèlent surtout des défauts applicatifs.** Sur huit
natures de rupture, la plupart ont mis au jour du code faux, pas des caprices de
version : deux `alias_attribute` pointaient vers des cibles inexistantes depuis
toujours ; une route `resources :affairs, only: [:unroll]` ne produisait rien
alors que son contrôleur existe ; un cycle de production démarrant un 29 février
faisait lever la validation d'`Activity` ; un parseur XML avalait `Exception`,
donc un Ctrl-C ; la clé `errors.messages.unbalanced` manquait à toutes les
locales, si bien qu'une écriture comptable déséquilibrée affichait
« Translation missing ».

**Mesurer avant de conclure.** Quatre diagnostics se sont révélés faux en cours
de route, et chaque fois c'est une mesure qui a tranché, pas un raisonnement :
`add_autoload_paths_to_load_path` ne casse rien ici (Rails garde `lib` dans le
`$LOAD_PATH` par `paths["lib"]`) — cent vingt chargements réécrits pour rien,
puis annulés ; `Regexp.timeout` n'explique pas l'instabilité qu'on lui
imputait sur une seule exécution (5 sur 5 avec le réglage, 1 sur 5 sans, sur
quatorze exécutions tabulées) — la cause était un `find_by` sans ordre, et le
réglage est rétabli ; les « montants inconciliables » de ce même test n'étaient
pas la cause non plus, seulement ce qui la rendait visible ; et la réécriture de
`db/structure.sql`, imputée à la suite, venait du `rake db:migrate` que le
conteneur de développement lance à chaque démarrage.

**Le lot 0.1 confirme la leçon précédente : la moitié des 32 cas rouges étaient
de vrais défauts utilisateur**, pas des assertions périmées. Par ordre de gravité :

- `Printers::JournalLedgerPrinter.new(full_params)` sans double étoile. **La
  clôture d'exercice ne pouvait produire aucun document de journal** depuis le
  passage à Ruby 3, alors que ses deux voisines immédiates, dans le même fichier,
  écrivent bien `**`. Le même motif frappait les deux rapports d'erreurs FEC :
  trois fonctions comptables inopérantes ;
- deux pages `show` plantaient (écarts de vente et d'achat) ; l'import Socleo
  était inutilisable en anglais ; les archives comptables partaient au mauvais
  type MIME ; deux tableaux de bord fantômes existaient dans le cœur ; trois
  modèles n'avaient pas de libellé en anglais ; deux messages de validation
  étaient illisibles.

**Trois tests ne dépendaient pas du code mais de la machine**, et c'est le motif
le plus coûteux à diagnostiquer :

- la signature GPG lisait `GPG_EMAIL` dans l'environnement ambiant — vide en CI,
  pointant une identité de production dans le `docker/dev/.env` du poste. Trois
  fonctions tombaient avec (clôture, archivage, impression signée). L'identité
  est désormais fixée par `config/environments/test.rb`, ce qui interdit aussi à
  la suite de signer avec une vraie clé ;
- `CompanyInformationsServiceTest` appelait vraiment l'API Sirene de l'INSEE,
  donc ne passait que là où la clé d'API est renseignée. Il rejoue une cassette
  VCR, clé et cookies filtrés à l'enregistrement ;
- deux tests phytosanitaires et une fixture désignaient une ligne du `lexicon`
  par son identifiant, renuméroté par une livraison du référentiel. Ils
  sélectionnent la ligne par la propriété qu'ils mettent en jeu.

**Et une correction qui change le confort de travail** : l'« instabilité Devise »
n'en était pas une. Les routes se chargent paresseusement depuis Rails 7.1,
`devise_for` ne peuplant `Devise.mappings` qu'à leur premier accès, tout test
appelant `sign_in` avant d'émettre une requête échouait. Le harnais charge
maintenant les routes explicitement : **un fichier de test isolé est redevenu une
unité de travail fiable**, ce qui rend la règle « ne jouer que les tests touchés »
praticable.

## 3. La dette que le lot B laisse

### 3.1 Six valeurs par défaut désactivées

Toutes documentées dans `config/application.rb`, avec ce qu'elles révèlent et le
travail que leur levée demande. Par poids décroissant :

| Réglage | Ce qu'il faut faire pour le lever |
|---|---|
| `raise_on_assign_to_attr_readonly` | 325 tests. Des rappels et des setters réaffectent `currency`, `nature`, `journal_id`, `state`… sans distinguer création et mise à jour ; ces écritures sont **perdues en silence** aujourd'hui. Chantier de rappels comptables |
| `raise_on_missing_required_finder_order_columns` | 14 tables du `lexicon` sans clé ni index unique : `first` y rend une ligne arbitraire. **Recoupe le lot C** |
| `default_column_serializer` | sortir de `wice_grid` ou corriger son `serialize :query` nu en amont |
| `has_many_inversing`, `automatic_scope_inversing` | casser la récursion mutuelle `PurchaseInvoice` ↔ `PurchaseItem` |
| `active_storage.variant_processor` | libvips dans l'image de base |

La septième, `Regexp.timeout`, est rétablie depuis le 14 septembre : le test
d'achat qu'elle semblait faire tomber tenait à un `find_by` sans ordre, pas au
réglage (§ 4).

### 3.2 Qualité

- ~~la suite n'est pas verte~~ — **traité.** Les 32 cas rouges sont corrigés ; la
  dernière mesure de CI donne 3620 tests, 0 échec, 1 erreur, et cette erreur est
  corrigée depuis. **Les trois instabilités sont réglées à la racine** : celle de
  `Devise.mappings` en juillet, celle de l'ordre des tests et celle de
  `db/structure.sql` le 14 septembre (points 0.2 et 0.4, § 4) ;
- **4 tests ignorés** : le manifeste de packs est vide en test, si bien qu'un
  gabarit appelant `javascript_pack_tag` ne se rend pas. À reprendre avec la
  bascule du front (lot 7), pas avant ;
- **809 offenses RuboCop** consignées dans `.rubocop_todo.yml` à la montée en
  1.91, dont 542 auto-corrigeables : dette de style, à résorber par lots ;
- **39 avertissements TypeScript** (types `any`, retours manquants).

### 3.3 Infrastructure

- la **production reste en Ruby 2.6 / Rails 5.2** : `docker/prod/Dockerfile` n'a
  pas bougé, et `build-prod-image` ne se déclenche pas sur cette branche,
  délibérément ;
- **la base est en PostgreSQL 18.6 / PostGIS 3.6** en développement comme en CI
  (`postgis/postgis:18-3.6`), et l'image de base porte le client 18. L'ordre
  compte et n'est pas celui qu'on croit : le client d'abord, le serveur ensuite.
  `pg_dump` refuse un serveur plus récent que lui, et Apartment l'appelle à
  chaque création de tenant — un client en retard ne dégrade pas, il rend les
  tenants incréables. Deux corollaires : **un répertoire de données 13 ne se
  relit pas en 18** (volume neuf obligatoire, `docker/startup.sh` sait
  reconstruire à partir de là), et **`db/structure.sql` est désormais en syntaxe
  18** — `pg_dump` 18 nomme les contraintes `NOT NULL`, qu'un serveur plus
  ancien refuse. La production, restée en 13, ne peut donc pas charger ce
  fichier ;
- la **production reste sur `kartoza/postgis:13`**, avec le piège de
  réexécution de `docker/db/init.sql` que documente `CLAUDE.md` ; dev et CI n'y
  sont plus exposés, l'image officielle ne rejouant ses scripts d'init que sur
  un `PGDATA` vide ;
- le conteneur `sidekiq` de développement doit être reconstruit quand l'image de
  base change — il a tourné des semaines sous Ruby 2.6 en boucle de redémarrage
  sans que rien ne le signale ;
- la CI ne se déclenche plus que sur **`6.0-alpha`** : `main` et `5.0-beta` ne
  bougent plus, et les y laisser n'ajoutait que du bruit. Corollaire à ne pas
  oublier — **renommer la branche éteint la CI** si l'on n'y touche pas ;
- **`build-prod-image` ne suit aucune branche.** Le brancher sur `6.0-alpha`
  l'aurait mis en échec à chaque commit : `docker/prod/Dockerfile` part encore de
  l'image `ruby2.6` alors que le `Gemfile` exige `>= 3.4.0`, donc son
  `bundle install` s'arrête avant la première gem. L'image se construit sur une
  étiquette `v*` ou à la demande, et le job `deploy` reste neutralisé ;
- `stale.yml` (fermeture automatique des tickets inactifs) a été supprimé.

## 4. Ce qui vient ensuite

La feuille de route opérationnelle, lot par lot, est dans
[v6-roadmap.md](v6-roadmap.md) — c'est elle qui fait autorité sur l'ordre et le
découpage depuis qu'elle intègre le guide du chef de projet (§ 12). Ce qui suit
n'en est que le sommet.

**Le lot 0 ne sépare plus du lot 1.** Les trois points qui restaient — 0.2, 0.4
et 0.17 — ont été traités le 14 septembre, et les trois ont désigné autre chose
que ce que l'on croyait :

- **0.2 — l'instabilité d'ordre ne tenait pas aux montants, mais à un `find_by`
  sans ordre.** `PurchaseTest#simple creation` demandait `Tax.find_by(amount: 20)`
  *après* avoir créé une seconde taxe à 20 %, intracommunautaire celle-là. Sans
  `ORDER BY`, la ligne rendue est celle que le plan d'exécution veut bien donner,
  et il suffit qu'une mise à jour déplace le tuple vivant de la première pour que
  le choix bascule — mesuré. Or une taxe intracommunautaire n'ajoute rien au
  hors-taxe : le montant TTC imposé de la ligne laissait alors 21 € de trou, et
  l'écriture comptable entière déséquilibrée. Le test désigne maintenant la taxe
  qu'il vise et pose des montants qui se réconcilient. `Regexp.timeout` est
  rétabli du même coup — le réglage n'était qu'un révélateur ;
- **0.4 — ce n'était pas la suite qui réécrivait `db/structure.sql`**, mais
  `docker/startup.sh` : il lance `rake db:migrate` à chaque démarrage du
  conteneur, et `db:migrate` enchaînait sur `db:structure:dump`. Un
  `docker compose up` suffisait donc à salir un fichier versionné, qu'Apartment
  clone dans chaque nouveau tenant. `dump_schema_after_migration` est désormais
  faux ; `DUMP_SCHEMA=1` rétablit l'enchaînement le temps d'une commande ;
- **0.17 — monter le serveur en 18 commence par le client, pas par le serveur.**
  `pg_dump` refuse un serveur plus récent que lui, et Apartment l'appelle à
  chaque création de tenant : le client 17.11 de l'image de base n'aurait pas
  seulement empêché de dumper, il aurait rendu tout tenant incréable. L'image de
  base porte donc le client 18 d'abord ; dev et CI passent ensuite sur
  `postgis/postgis:18-3.6`. Trois cailloux en chemin, tous documentés là où on
  les rencontrera : l'image officielle installe PostGIS dans le schéma courant
  (nos scripts d'init sont montés après elle), son serveur temporaire
  d'initialisation n'écoute que la socket Unix (`--host=localhost` faisait
  sortir le conteneur en code 2), et le test du lexique de `docker/startup.sh`
  regardait l'existence du schéma `lexicon` là où `structure.sql` le déclare
  vide — sur base neuve, le lexique n'était jamais chargé.

`uuidv7()` répond sur la pile réelle, ce qui était le point 1.3 de la feuille de
route. **Le lot 1 peut s'ouvrir.**

Les points 0.5 à 0.9 (les six valeurs par défaut) et 0.10 à 0.13 (dette
d'outillage) ne bloquent pas le lot 1 ; `raise_on_assign_to_attr_readonly` et
`raise_on_missing_required_finder_order_columns` s'y rattachent naturellement,
le premier par les rappels comptables, le second par la classification des
tables du `lexicon`.

**Lot 1 — mono-schéma et isolation (ADR-002, ADR-003).** Passer des schémas
PostgreSQL par ferme à une base unique avec `tenant_id` uuid, PK composites et
RLS `FORCE`, puis le runtime qui va avec — `TenantRecord`, contexte `set_config`
en transaction, propagation aux chemins asynchrones, tests d'isolation générés,
retrait d'Apartment.

**Le prototype à trois tables est fait** (point 1.4, 14 septembre) :
`db/prototypes/monoschema/`, dix-neuf mesures que la CI rejoue. L'isolation
tient, elle est fermée par défaut, la clé étrangère composite refuse la
référence inter-tenant et l'index unique devient local au tenant. Il a surtout
sorti quatre pièges qu'aucune ADR ne mentionnait, et qui changent le contenu des
points suivants :

- sous clé composite, **`record.id` rend le couple** et non la colonne — tout
  `foo_id: bar.id` du code existant devient faux en silence ;
- **`query_constraints:` n'existe pas sur une association** en Rails 8.1 : la clé
  étrangère composite se déclare en `foreign_key: %i[tenant_id …]`. Le point 1.16
  portait sur la mauvaise annotation, pour 1 413 associations ;
- **le cache de requêtes ignore le tenant.** Une lecture faite sous A est
  resservie hors contexte, là où la politique aurait rendu zéro ligne : la
  fermeture par défaut est contournée avant même d'atteindre la base ;
- **sous RLS, l'index spatial cesse de servir.** Une condition non `LEAKPROOF`
  est évaluée après la politique, donc jamais en condition d'index : la même
  requête parcellaire passe d'un coût estimé de 229 à 63 380. L'ADR-002
  recommande l'index GiST composite sans dire qu'il faut, en plus, marquer les
  opérateurs de PostGIS — ce qui est une décision de sécurité.

**La classification des tables est faite aussi** (point 1.5) : `db/monoschema/`,
**316 tables** — 241 au plan de données, 2 au contrôle, 73 au référentiel —, avec
un fichier de décisions tenu à la main et un plan engendré que lira le générateur
de migrations. La CI échoue désormais sur toute table non classée. Sept questions
restent ouvertes, et aucune n'est technique : cinq référentiels dupliqués dans
chaque ferme (`districts`, `postal_zones`, `vegetative_stages`, `net_services`,
`units`), la table `saas_subscriptions` qui désigne une autre ferme par son nom,
et le sort de `users` avant Keycloak.

La mesure a surtout corrigé le volume du lot : le schéma déclare **171 clés
étrangères** là où **896 colonnes en `_id` désignent une ligne sans aucune
contrainte**. Le générateur du point 1.6 ne peut pas en déduire la cible — il
faudra la tirer des modèles Ruby.

Reste la suite du lot : engendrer les migrations, `TenantRecord` et le contexte,
les 206 sites de SQL brut, et le retrait d'Apartment.

## 5. Ce qui est tranché, et ce qui ne l'est pas

Décisions prises le 13 septembre 2026 et inscrites dans la feuille de route :

- **PostgreSQL 18**, pour `uuidv7()` native ;
- **`tenant_id` en uuid, avec un slug** à côté pour rester lisible
  (`phaurigot`) ; l'uuid est compatible avec l'application mobile et Duke ;
- **remplacement complet d'`active_list`** — la technologie du front change de
  toute façon ;
- **déploiement du palier 8.1 sur le staging `ekylibre.io`** via Dokploy,
  **après** le mono-schéma ;
- **Solid Queue, Solid Cable et Solid Cache** ;
- un canal de saisie terrain **Telegram ou équivalent**, pas WhatsApp.

Reste ouvert :

1. **`turnout` et le mode maintenance.** Il retient `rack` sous la 3 et plafonne
   `sidekiq` à la série 7. La question se tranche au passage à Solid Queue, pas
   avant.
2. **La CI des greffons** (point 0.18). Aucun des 19 greffons n'a de CI : leurs
   suites ne s'exécutent nulle part. Deux voies — une CI par greffon, ou un
   `Gemfile.ci` versionné qui les monte dans la CI du cœur. À décider avant que
   le mono-schéma ne les touche, sans quoi leurs régressions seront invisibles.
3. **Le sort d'`Ekylibre::Plugin`** (point 0.12) : le mécanisme `plugins/` est
   mort, les greffons sont des engines. Le retirer ou le documenter.

---

## Annexe — Les quinze commits du lot B (7.1 → 8.1)

```
90db5bed91  Déclarer le codeur des colonnes sérialisées
c9d39035ba  Passer aux valeurs par défaut de Rails 7.1
eefb2506b1  Monter l'application en Rails 7.2
34c8cc6c22  Passer aux valeurs par défaut de Rails 7.2
32361ecebd  Monter l'application en Rails 8.0
78be18678b  Passer aux valeurs par défaut de Rails 8.0
c2253c5d52  Monter l'application en Rails 8.1
6468b5cbd9  Passer aux valeurs par défaut de Rails 8.1
b954dfb027  Consigner l'arrivée en 8.1 et ce qu'elle laisse derrière
4ae253fe08  Épingler le greffon baqio sur son correctif d'initialiseur
72e5547618  Rendre lisible l'écriture déséquilibrée, et corriger ce que j'en disais
8602864cb6  Renommer la branche en 6.0-alpha et y ramener la CI
e97c59e3e1  Réparer l'étape de base de données de la CI
5b21c74546  Ramener le lint au vert, RuboCop et ESLint
73eafab56d  Monter RuboCop en 1.91, seule façon de le faire tourner sous Ruby 3.4
```

Côté greffons : `ekylibre-viti` `9b312aa85e` (`:patch` retiré des actions d'une
ressource) et `ekylibre-baqio` `2dc98cd` (initialiseur dupliqué), tous deux
poussés sur leur branche `6.0`.

## Annexe — Les commits du lot 0.1 (32 cas rouges)

```
57c26b9d0a  Découpler les modèles HVE du greffon qui les alimente
52e7b9c3e5  Reprendre dix-neuf tests rouges, dont onze défauts réels
fd5b876e6a  Reprendre sept tests rouges, dont trois défauts réels
1c522b39cd  Fixer l'identité de signature de la suite, et le dernier identifiant figé
e35327d044  Actualiser la mesure de référence : le lot 0.1 est au vert
0b9bab20b4  Engendrer les actions de tableau de bord sans eval
8593fd6245  Restreindre la CI à 6.0-alpha, et sortir l'image de prod des pushes
d0763167be  Sortir le dernier test rouge du réseau, et taire le bruit de VCR
```

## Annexe — Les commits du 14 septembre (points 0.2 et 0.4)

La suite entière, jouée en local après ces deux corrections et avec
`Regexp.timeout` actif : **3621 tests, 15717 assertions, 0 échec, 0 erreur,
4 ignorés**, en 26 minutes — et `git status` propre au sortir, ce qui valide le
point 0.4 de bout en bout. La CI comptait 3620 tests : le test d'écart reste à
identifier au prochain passage, il n'est ni rouge ni ignoré.

## Annexe — Le point 0.17 (PostgreSQL 13 → 18)

Hors de ce dépôt : `ekylibre/docker-base-images@6281aea`, qui remplace
`postgresql-client-13` par le 18 dans `ruby/3.4.10/Dockerfile.prod`. La CI de ce
dépôt-là reconstruit et republie `ruby3.4.10:latest`, dont dépendent l'image de
développement et le conteneur de la CI d'Ekylibre.

Ici : l'image du service `db` (dev et CI), l'ordre et le contenu des scripts
d'initialisation, `docker/startup.sh`, puis `db/structure.sql` dans son propre
commit.

**Ce qu'il faut savoir avant de refaire le chemin sur un autre poste** : le
volume de données doit être neuf (`docker volume rm dev_database-volume`), et
tout repart de `docker compose up` — chargement de `structure.sql`, migrations,
lexique. Les tenants de développement sont perdus ; `config/tenants.yml` n'est
pas versionné et se repeuple à la création.

## Annexe — Où reprendre

1. **Lire la mesure de CI**, qui tourne pour la première fois sur PostgreSQL 18.
   Deux choses à y vérifier : que le job `Tests` sort à zéro, et que l'étape de
   préparation des extensions passe bien sur l'image officielle.
2. Le lot 0 n'a plus de point bloquant : restent les valeurs par défaut (0.5 à
   0.9) et la dette d'outillage (0.10 à 0.13), aucun ne séparant du lot 1.
3. Le lot 1 s'ouvre sur le prototype de mono-schéma à trois tables — sur une
   base qui porte désormais `uuidv7()`.
