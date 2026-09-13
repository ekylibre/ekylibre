# Ekylibre v6 — État des lieux au 13 septembre 2026 (soir)

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
| Production | Ruby 2.6, Rails 5.2 | **inchangée** — rien n'est déployé |
| Suite | 3650 tests, 17 échecs, 15 erreurs | **3620 tests, 0 échec, 0 erreur** attendu ; dernière mesure CI 1 erreur, corrigée depuis |
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

**Mesurer avant de conclure.** Deux diagnostics se sont révélés faux en cours de
route, et les deux fois c'est une mesure qui a tranché, pas un raisonnement :
`add_autoload_paths_to_load_path` ne casse rien ici (Rails garde `lib` dans le
`$LOAD_PATH` par `paths["lib"]`) — cent vingt chargements réécrits pour rien,
puis annulés ; et `Regexp.timeout` n'explique pas l'instabilité qu'on lui
imputait sur une seule exécution (5 sur 5 avec le réglage, 1 sur 5 sans, sur
quatorze exécutions tabulées).

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

### 3.1 Sept valeurs par défaut désactivées

Toutes documentées dans `config/application.rb`, avec ce qu'elles révèlent et le
travail que leur levée demande. Par poids décroissant :

| Réglage | Ce qu'il faut faire pour le lever |
|---|---|
| `raise_on_assign_to_attr_readonly` | 325 tests. Des rappels et des setters réaffectent `currency`, `nature`, `journal_id`, `state`… sans distinguer création et mise à jour ; ces écritures sont **perdues en silence** aujourd'hui. Chantier de rappels comptables |
| `raise_on_missing_required_finder_order_columns` | 14 tables du `lexicon` sans clé ni index unique : `first` y rend une ligne arbitraire. **Recoupe le lot C** |
| `default_column_serializer` | sortir de `wice_grid` ou corriger son `serialize :query` nu en amont |
| `has_many_inversing`, `automatic_scope_inversing` | casser la récursion mutuelle `PurchaseInvoice` ↔ `PurchaseItem` |
| `Regexp.timeout` | corriger le test d'achat aux montants inconciliables (99 € HT pour 120 € TTC à 20 %) |
| `active_storage.variant_processor` | libvips dans l'image de base |

### 3.2 Qualité

- ~~la suite n'est pas verte~~ — **traité.** Les 32 cas rouges sont corrigés ; la
  dernière mesure de CI donne 3620 tests, 0 échec, 1 erreur, et cette erreur est
  corrigée depuis. Deux instabilités subsistent sur les trois : l'ordre des tests
  (le test d'achat aux montants inconciliables, point 0.2 de la feuille de route)
  et la réécriture de `db/structure.sql` par la suite (point 0.4). Celle de
  `Devise.mappings` est réglée à la racine — voir `CLAUDE.md` ;
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
- `postgresql-client` est en 13 dans l'image de base, ce qui **plafonne
  PostgreSQL à 13** : `pg_dump` refuse un serveur plus récent, et c'est lui qui
  fait `db:structure:dump` comme `Ekylibre::Tenant.dump` ;
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

**Le reste du lot 0 est désormais la seule chose qui sépare du lot 1.** Trois
points y restent ouverts et sont de nature différente :

| Point | Nature |
|---|---|
| 0.2 — corriger le test d'achat aux montants inconciliables (99 € HT pour 120 € TTC à 20 %), puis rétablir `Regexp.timeout` | une heure, et la dernière instabilité d'ordre disparaît |
| 0.4 — empêcher la suite de réécrire `db/structure.sql` | un piège à commit, à traiter avant d'écrire des migrations en série |
| 0.17 — **monter le serveur PostgreSQL de 13 à 18** | préalable de `uuidv7()` native, donc du lot 1 lui-même |

Les points 0.5 à 0.9 (les sept valeurs par défaut) et 0.10 à 0.13 (dette
d'outillage) ne bloquent pas le lot 1 ; `raise_on_assign_to_attr_readonly` et
`raise_on_missing_required_finder_order_columns` s'y rattachent naturellement,
le premier par les rappels comptables, le second par la classification des
tables du `lexicon`.

**Lot 1 — mono-schéma et isolation (ADR-002, ADR-003).** Passer des schémas
PostgreSQL par ferme à une base unique avec `tenant_id` uuid, PK composites et
RLS `FORCE`, puis le runtime qui va avec — `TenantRecord`, contexte `set_config`
en transaction, propagation aux chemins asynchrones, tests d'isolation générés,
retrait d'Apartment. Le palier 7.1 a livré ce qui manquait côté ORM :
`query_constraints` et les PK composites natives. Porte d'entrée : le prototype
sur trois tables, qui couvre à lui seul PK/FK composites, STI et colonne
géométrique.

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

## Annexe — Où reprendre

1. **Lire la mesure de CI du commit `d0763167be`.** Si elle sort à zéro, le job
   `Tests` est vert pour la première fois et le lot 0.1 est clos.
2. Puis, dans cet ordre : point 0.2 (montants d'achat inconciliables, puis
   rétablir `Regexp.timeout`), point 0.4 (`db/structure.sql`), point 0.17
   (PostgreSQL 13 → 18 et régénération de `structure.sql` dans un commit dédié).
3. Le lot 1 s'ouvre sur le prototype de mono-schéma à trois tables.
