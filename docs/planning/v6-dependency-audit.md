# Ekylibre 6.0 — Audit des dépendances (lot A.6)

> **Branche** : `ekylibre-6.0`
> **Date** : 2026-09-09
> **Objet** : livrable du lot A.6 du [plan d'amélioration](v6-improvement-plan.md). Établit ce qui bloque réellement la montée de Rails, et pour chaque blocage la décision *porter / relâcher / remplacer / abandonner*.

---

## 1. Méthode

La liste des bloquants n'est pas déduite par lecture : elle est **produite par Bundler**. Une copie jetable du `Gemfile` a été passée à `rails ~> 6.0.0`, puis `bundle lock` a été relancé en retirant à chaque tour la gem que le résolveur désignait, jusqu'à convergence.

C'est important : l'analyse statique seule avait manqué quatre bloquants (`wice_grid`, `bootstrap-slider-rails`, `deep_cloneable`, `activerecord-postgis-adapter`), tous des gems publiques épinglées à une version ancienne.

Les métadonnées par dépôt (dernier commit, contraintes, LOC, couplage) proviennent des checkouts montés dans `/ekylibre-plugins/` du conteneur de développement.

---

## 2. Les 9 bloquants de Rails 6

Ordre de découverte par Bundler, à versions épinglées inchangées :

| # | Gem | Contrainte qui bloque | Nature |
|---|---|---|---|
| 1 | `planning` (fork) | `rails ~> 5.2` | fork Ekylibre, **en production** |
| 2 | `active_list` (fork) | `rails >= 3.2, < 6` | fork Ekylibre |
| 3 | `wice_grid` | `rails >= 5.0, < 5.3` | épinglage ancien |
| 4 | `agric` (fork) | `railties >= 3.2, < 6` | fork Ekylibre |
| 5 | `bootstrap-slider-rails` | `railties >= 3.2, < 6.0` | amont mort |
| 6 | `charta` (fork) | `activesupport ~> 5.0` | fork Ekylibre |
| 7 | `apartment` | non maintenue | remplacement connu |
| 8 | `deep_cloneable` | épinglé `~> 2.4.0` | épinglage ancien |
| 9 | `activerecord-postgis-adapter` | épinglé `~> 5.0` | épinglage ancien |

### 2.1 Trois d'entre eux ne sont que des épinglages périmés

Une version compatible existe déjà sur RubyGems ; il suffit de relâcher la contrainte du `Gemfile`.

| Gem | Épinglé | Dernière publiée | Action |
|---|---|---|---|
| `activerecord-postgis-adapter` | `~> 5.0` (5.2.3) | **11.1.1** | relâcher vers la version correspondant au palier Rails visé |
| `wice_grid` | `~> 4.0` | **7.1.4** | relâcher |
| `deep_cloneable` | `~> 2.4.0` | **3.2.2** | relâcher |

### 2.2 Un amont réellement mort

`bootstrap-slider-rails` déclare `railties >= 3.2, < 6.0` et **9.8.0 est déjà la dernière version publiée**. C'est une gem d'assets (CSS/JS) : elle disparaît avec le front au lot G. D'ici là, vendorer le composant ou relâcher via un fork minimal.

### 2.3 Trois remplacements

`apartment` → **`ros-apartment 2.11`** (lot A.5, fait) · `state_machine` (1.2.0, amont figé depuis 2014) → `aasm` **6.0.0** (lot A.2) · `paperclip` → Active Storage (lot A.3).

Le choix de la série 2.11 plutôt que de la dernière (3.4.4) est délibéré : elle accepte `activerecord >= 5.0.0, < 7.1`, donc elle fonctionne **dès aujourd'hui sur Rails 5.2** et couvre les paliers 6.0, 6.1 et 7.0 sans nouvelle bascule. La 3.0 exige AR >= 6.1, la 3.4 exige AR >= 7.0 : elles ne seront installables qu'aux derniers paliers.

`state_machine` et `paperclip` ne figurent pas dans la liste des 9 parce qu'ils ne déclarent pas de borne sur Rails — ils cassent à l'exécution, pas à la résolution.

### 2.4 Sidekiq n'est pas verrouillé par Apartment

L'audit de mai (`docs/analysis/`) affirme qu'`apartment` verrouille `apartment-sidekiq` et donc Sidekiq. **C'est faux** : `apartment-sidekiq 1.2.0` déclare `sidekiq >= 2.11`, sans borne supérieure. Le blocage à Sidekiq 4.2.10 vient du `Gemfile` lui-même (`gem 'sidekiq', '~> 4.0'`, et `gem 'sidekiq-unique-jobs', '~> 4.0'` qui doit être relevé de concert). La montée de Sidekiq est donc **indépendante** d'A.5 et réalisable quand on veut.

---

## 3. Les 23 dépôts Ekylibre

### 3.1 Vue d'ensemble

`AR-int` = références aux internes d'ActiveRecord · `AV-int` = internes d'ActionView/ActionController. Un chiffre faible signifie que la contrainte déclarée est **déclarative**, pas structurelle.

| Dépôt | Dernier commit | Contrainte Rails déclarée | LOC | AR-int | AV-int | Décision |
|---|---|---|---:|---:|---:|---|
| `active_list` | 2026-03-28 | `rails >= 3.2, < 6` | 2 823 | 4 | 5 | **Remplacer** (ADR-6.2) — compat minimale d'ici le lot G |
| `agric` | 2026-03-28 | `railties >= 3.2, < 6` | 119 | 0 | 0 | **Relâcher** — aucun couplage |
| `charta` | 2026-03-28 | `activesupport ~> 5.0` | 2 282 | 0 | 0 | **Relâcher** — aucun couplage |
| `ekylibre-planning` | **2023-03-20** | `rails ~> 5.2` + `coffee-rails` | 5 819 | 0 | 1 | ~~**Porter**~~ → **FAIT** — le couplage annoncé n'existait pas ; voir §3.4 |
| `ekylibre-viti` | 2026-05-07 | `rails ~> 5.2` | 2 799 | 8 | 0 | **Relâcher + vérifier** |
| `ekylibre-hve` | 2026-06-21 | `rails ~> 5.2` | 856 | 1 | 0 | **Relâcher** |
| `ekylibre-economic` | 2026-03-28 | `rails >= 5.2` | 966 | 0 | 0 | Rien à faire (borne ouverte) |
| `onoma` | 2026-03-28 | `activesupport >= 4.2` | 2 268 | 0 | 0 | Rien à faire |
| `odf-report` | — | aucune (rubyzip, nokogiri) | 1 801 | 0 | 0 | Rien à faire — **socle d'ADR-6.1** |
| `possibly` | — | aucune | 547 | 0 | 0 | Rien à faire |
| `xsd_errors_parser` | 2026-03-28 | aucune | 294 | 0 | 0 | Rien à faire |
| `cartography` | **2022-10-07** | aucune | 85 | 0 | 0 | Vérifier l'usage — 85 LOC, dormant |
| `ekylibre-idea` | 2026-06-06 | — | 5 047 | 0 | 0 | Rien à faire |
| `ekylibre-hajimari` | 2026-06-19 | — | 3 837 | 0 | 0 | Rien à faire |
| `ekylibre-qonto` | 2026-07-26 | — | 3 367 | 0 | 0 | Rien à faire |
| `ekylibre-ednotif` | 2026-03-28 | — | 3 166 | 3 | 0 | Rien à faire |
| `ekylibre-baqio` | 2026-03-28 | — | 2 223 | 0 | 0 | Rien à faire |
| `ekylibre-samsys` | 2026-08-27 | — | 2 066 | 0 | 0 | Rien à faire |
| `ekylibre-agro-monitoring` | 2026-06-19 | — | 1 097 | 0 | 0 | Rien à faire |
| `ekylibre-traccar` | 2026-07-26 | — | 893 | 0 | 0 | Rien à faire |
| `ekylibre-banking` | 2026-03-28 | — | 824 | 0 | 0 | Rien à faire |
| `ekylibre-sencrop` | 2026-05-19 | — | 612 | 0 | 0 | Rien à faire |
| `ekylibre-natuition` | 2026-03-28 | — | 350 | 0 | 0 | Rien à faire |

*(`ekylibre-imepe` et `ekylibre-weenat` figurent dans les checkouts ; `imepe` est commenté dans `Gemfile.local`, `weenat` est actif et sans contrainte ni couplage.)*

### 3.2 Le constat qui change le chiffrage

**Les bornes déclarées ne reflètent pas le couplage réel.**

- `charta` — cœur géospatial, consommé partout — ne référence **aucune** constante `ActiveSupport::*`. Son seul lien est `require 'active_support/core_ext'`. La borne `~> 5.0` est une sur-déclaration ; la relâcher est une ligne de gemspec.
- `agric` : 119 LOC, zéro couplage, borne `< 6` purement déclarative.
- `active_list` n'a que **trois** points de contact réels hors code de test :
  - `lib/active_list/rails/engine.rb:6-7` — `include` dans `ActionController::Base` et `ActionView::Base` (fonctionne en Rails 6/7) ;
  - `lib/active_list/rails/integration.rb:18` — `ActionView::Base.send(:class_eval, generator.view_method_code)`, **le seul point réellement risqué** (la résolution des helpers a changé en Rails 6+).

`ekylibre-planning` semblait faire exception avec 37 références aux internes d'ActiveRecord. **Le décompte était faux** : voir §3.4.

### 3.4 `ekylibre-planning` : le portage qui n'en était pas un

Le chiffre de 37 « AR-int » comptait tous les fichiers du dépôt. Réparti par répertoire :

| Répertoire | Références `ActiveRecord::` | Nature |
|---|---:|---|
| `app/` + `lib/` + `config/` | **0** | le code livré |
| `spec/` | 42 | dont **40 dans `spec/dummy`**, l'application factice |
| `test/` | 2 | `ActiveRecord::Migrator.migrations_paths` dans `test_helper.rb` |

L'engine **n'a aucun modèle** : il n'apporte que des contrôleurs, des helpers, des vues et un job — tous les modèles (`InterventionTemplate`, `TechnicalItinerary`, `Scenario`…) viennent de l'application hôte. D'où l'absence totale de couplage. Aucune API retirée en Rails 6/7/8 n'y figure non plus.

Le portage s'est donc réduit aux bornes, vérifiées par Bundler et non déduites : le gemspec se résout jusqu'à **Rails 7.1 sous Ruby 3.0**, et pour Rails 8.0 le seul conflit restant oppose `Ruby >= 3.2` (exigé par Rails) au Ruby de la machine de test — plus rien ne vient du plugin.

**Le seul vrai portage de code ne venait pas de Rails mais de nous.** `ScenarioExportJob` créait son document d'export en passant `file:` un StringIO et le nom sous `file_file_name:`, deux attributs que Paperclip acceptait. Le lot A.3 ayant retiré Paperclip et supprimé ces colonnes, le job levait sur toute exportation. Corrigé et vérifié en exécution.

> **Deux autres plugins écrivaient de la même façon**, et sont repris avec celui-ci sur une branche `6.0` publiée : `ekylibre-viti` (registre de vendange) et `ekylibre-baqio` (facture attachée à la vente). `ekylibre-qonto` n'est concerné qu'en lecture (`file_file_name.present?` dans un test), ce que `LegacyAttachmentColumns` continue de servir. Au passage, la borne `rails ~> 5.2` d'`ekylibre-viti` est relâchée : ses 9 références à ActiveRecord sont toutes des API publiques (`Base.transaction`, `RecordNotFound`, un `connection.execute` de SQL PostGIS).

L'état de la suite de tests est en revanche mauvais, et indépendant de la montée :

- `spec/` (20 fichiers, ~64 cas) repose sur `spec/dummy`, une application factice dont les migrations héritent de `ActiveRecord::Migration` **sans version** — invalide depuis Rails 5.0. Son `schema.rb` date de 2018. Cette suite ne s'exécute plus depuis des années ; le dépôt n'a même pas de `Gemfile.lock`.
- `test/` (10 fichiers) ne contient que 8 cas réels, dont 7 dans `technical_itineraries_controller_test.rb` — qui **échoue déjà aujourd'hui en Rails 5.2** : le harnais de l'application ne charge pas les fixtures du plugin (`undefined method 'technical_itineraries'`).

Autrement dit, ce plugin n'a aujourd'hui **aucun filet de sécurité automatisé**, ce qui pèse davantage sur la montée que son couplage — inexistant.

### 3.3 Dev et production chargent la même liste

Les 19 plugins de `Gemfile.local` et de `docker/prod/Gemfile.prod` sont **identiques**. Aucun écart à réconcilier — mais aucun plugin n'est non plus « seulement de dev », donc chacun doit suivre la montée.

---

## 4. Conséquences pour le lot B

Le chiffrage initial du lot B (B.9, « montée en verrou des 7 forks + 12 plugins », 30 j·h) supposait un portage de chaque fork. L'audit le contredit :

| Catégorie | Nombre | Effort |
|---|---:|---|
| Épinglages à relâcher (gems publiques) | 3 | trivial |
| Bornes de gemspec à relâcher (forks sans couplage) | 4 — `agric`, `charta`, `ekylibre-hve`, `ekylibre-viti` | faible |
| Rien à faire | 12 | nul |
| Portage réel | **0** — `ekylibre-planning` mesuré : aucun couplage (§3.4) | ~~substantiel~~ → fait |
| Remplacement | 4 — `active_list`, `apartment`, `state_machine`, `paperclip` | déjà chiffré en A.2/A.3/A.5/A.7 |
| Amont mort à contourner | 1 — `bootstrap-slider-rails` | faible, disparaît au lot G |

**B.9 est ramené de 30 à ~12 j·h**, puis à **~6 j·h** une fois `ekylibre-planning` mesuré et porté (§3.4) : il concentrait l'essentiel du reliquat. Le lot B passe donc de ~118 à **~94 j·h**.

---

## 5. Vérifications déjà effectuées

- **`therubyracer` est du poids mort** (lot A.1, fait). La version d'ExecJS installée ne le liste plus parmi ses runtimes (`therubyrhino, GraalVM, Duktape, mini_racer, Bun.sh, Node.js, JavaScriptCore, SpiderMonkey, JScript, V8`) ; ExecJS sélectionne déjà Node 20, fourni par l'image de base commune au dev et à la prod. Retiré du `Gemfile` : la résolution passe et `libv8 3.16` disparaît avec lui. **Aucun `mini_racer` n'est nécessaire.**
- **PostgreSQL 13 est validé pour la CI** (lot A.8, fait) : les 721 migrations s'appliquent proprement sur `postgis/postgis:13-3.3` et produisent le même schéma que la base de développement — 251 tables, 35 colonnes géométriques, 1 837 index, 169 FK.
- **PostgreSQL 15 fonctionne aussi** (721 migrations, schéma identique), **mais est bloqué par l'image de base** : `postgresql-client` y est en 13, et `pg_dump` refuse de dumper un serveur plus récent (*server version mismatch*). Cela casserait `db:structure:dump` **et** `Ekylibre::Tenant.dump`. Passer en 15/16 impose donc un bump de `ekylibre/docker-base-images` — hors de ce dépôt.

---

## 6. Ordre d'exécution recommandé pour la suite du lot A

1. **A.5 `ros-apartment`** — déverrouille `apartment-sidekiq`, donc Sidekiq. Peu risqué, gros effet de levier.
2. **A.2 `state_machine` → `aasm`** — le plus gros poste (20 j·h) et le plus risqué : 10+ modèles comptables et logistiques. À démarrer tôt.
3. **Relâchement des bornes** — 3 épinglages publics + 4 gemspecs de forks. Rapide, et rend la montée testable de bout en bout.
4. **A.3 Paperclip → Active Storage**, **A.4 suppression de Jasper**.
5. ~~**`ekylibre-planning`**~~ — **fait** ; le portage annoncé n'existait pas, seules les bornes bloquaient (§3.4).
6. **A.7 `active_list`** — dépend d'ADR-6.3 (choix du front).

---

## 7. Relâchement des bornes : ce qui bouge maintenant, ce qui bouge avec Rails

L'idée initiale — « relâcher les bornes d'abord, pour obtenir vite un `bundle` résolvable en Rails 6 » — ne tient qu'à moitié. Les épinglages se répartissent en deux familles.

### 7.1 Relâchables immédiatement (fait)

Ces gems ont une version qui couvre **à la fois** Rails 5.2 et les paliers suivants : on la prend tout de suite, elle n'aura plus à bouger.

| Gem | Avant | Après | Portée de la nouvelle version |
|---|---|---|---|
| `wice_grid` | `~> 4.0` (capé `rails < 5.3`) | **`~> 6.1`** | `rails >= 5.0`, **sans borne haute** |
| `deep_cloneable` | `~> 2.4.0` (capé `activerecord < 6`) | **`~> 3.0`** | `activerecord >= 3.1.0, < 9` |

Deux des neuf bloquants de Rails 6 disparaissent ainsi dès le palier actuel.

*(Note : `wice_grid 7.x` exige `rails ~> 7.1` — la 6.1 est donc le bon palier, pas la dernière.)*

### 7.2 Non relâchables : elles montent **avec** Rails, pas avant

`activerecord-postgis-adapter` et `ros-apartment` sont épinglées à une série d'ActiveRecord précise. Les relâcher aujourd'hui installerait une version incompatible avec Rails 5.2 : leur montée fait partie de chaque palier du lot B, elle ne le précède pas.

| Palier Rails | `activerecord-postgis-adapter` | `ros-apartment` | Note |
|---|---|---|---|
| **5.2** (actuel) | 5.2.3 (`AR ~> 5.1`) | **2.11** (`AR >= 5.0, < 7.1`) | état courant |
| 6.0 | 6.0.3 (`AR ~> 6.0.0`) | 2.11 | |
| 6.1 | 7.1.1 (`AR ~> 6.1`) | 2.11 | |
| 7.0 | 8.0.3 (`AR ~> 7.0.0`) | 2.11 | dernier palier couvert par la 2.11 |
| 7.1 | 9.0.2 (`AR ~> 7.1.0`) | 3.0 (`AR >= 6.1, < 7.2`) | |
| 7.2 | 10.0.3 (`AR ~> 7.2`) | 3.2 (`AR >= 6.1, < 8.1`) | **ruby >= 3.1 requis** |
| 8.0 | 11.0.0 (`AR ~> 8.0.0`) | 3.4 (`AR >= 7.0, < 8.2`) | |
| 8.1 (cible) | 11.1.1 (`AR ~> 8.1.0`) | 3.4 | |

C'est une correspondance un pour un : le lot B devient mécanique sur ces deux gems.

### 7.3 Sans issue amont

`bootstrap-slider-rails` reste capée à `railties < 6.0` et 9.8.0 est la dernière version publiée. C'est une gem d'assets Sprockets (`//= require bootstrap-slider` dans `application.js`) : elle disparaît avec le front au lot G. D'ici là, il faudra soit vendorer le composant JS, soit forker la gem pour relever la borne.

### 7.4 Sidekiq peut monter quand on veut

Sidekiq ne déclare **aucune** contrainte sur Rails, seulement sur Ruby (6.5.12 exige `ruby >= 2.5`, satisfait par le 2.6 actuel). Rien n'empêche techniquement de passer à Sidekiq 6 dès aujourd'hui, avec `sidekiq-unique-jobs 7.1.x` (`sidekiq >= 5.0, < 7.0`) en verrou. Ce n'est pas un relâchement de borne mais une migration à part entière (l'API des middlewares et la configuration serveur changent entre 4 et 6) — à traiter comme un lot propre, pas comme un effet de bord.

---

## 8. Suppression de Jasper (A.4) : ce que l'audit initial avait sous-estimé

L'ADR-6.1 a été tranchée sur un constat partiel : « la voie de remplacement existe déjà — 37 `Printers::*` et 154 templates `.odt` ; restent 14 `.jrxml` à migrer ». La première moitié est exacte, la seconde ne l'est pas.

### 8.1 Comment une nature de document choisit sa voie

`Ekylibre::DocumentManagement::TemplateFileProvider#find_by_nature` résout ainsi :

```ruby
[*odt_paths(nature), *jasper_paths(nature)].detect(&:exist?)
```

L'ODT est donc **prioritaire** et le Jasper n'est qu'un repli. Une nature bascule sur la voie moderne dès qu'un `.odt` existe pour elle — le `file_extension` stocké en base n'y change rien (les 26 `DocumentTemplate` du tenant de test valent tous `xml`, alors que 16 d'entre eux sont servis en ODT).

Conséquence : **le nombre de fichiers `.jrxml` n'est pas la mesure du travail restant**. Ce qui compte est le nombre de *natures* dépourvues d'ODT.

### 8.2 Les 13 natures encore liées à Jasper

Sur les 73 natures déclarées, 13 n'ont ni `.odt` ni `Printers::*` et ne peuvent donc être servies que par Jasper :

| Nature | Format Jasper |
|---|---|
| `animal_husbandry_register` | `.xml` |
| `animal_list` | `.xml` |
| `animal_sheet` | `.xml` |
| `deposit_list` | `.xml` |
| `cultivable_zone_sheet` | `.jrxml` |
| `fr_pcg82_balance_sheet` | `.jrxml` |
| `fr_pcg82_profit_and_loss_statement` | `.jrxml` |
| `fr_pcga_balance_sheet` | `.jrxml` |
| `fr_pcga_profit_and_loss_statement` | `.jrxml` |
| `journal_entry_sheet` | `.jrxml` |
| `outgoing_delivery_docket` | `.jrxml` |
| `purchases_invoice` | `.jrxml` |
| `veterinary_booklet` | `.jrxml` |

Elles sont atteignables : `ToolbarHelper#export` (36 usages dans les vues) produit des liens `format: :pdf, template: <id>`, et le concern `RespondWithTemplate` injecte `with: params[:template]` dans `respond_with` — ce qui alimente `ActionController::Responder#to_pdf`, défini par `lib/reporting.rb`, donc Beardley/Jasper. Onze contrôleurs empruntent cette voie.

### 8.3 Pourquoi le lot ne peut pas être terminé en l'état

Migrer une nature demande **deux** livrables :

1. une classe `Printers::XxxPrinter` — du code, faisable ;
2. un gabarit `.odt` — un document LibreOffice, avec sa mise en page, ses champs de fusion et ses tableaux. Ce n'est pas du code : c'est de la conception documentaire, et cela conditionne le rendu vu par le client (factures d'achat, registre d'élevage, carnet vétérinaire, bilans PCG/PCGA).

Les 13 gabarits `.odt` doivent donc être produits par quelqu'un ayant LibreOffice et la maîtrise du rendu attendu. Tant qu'ils n'existent pas, `rjb`, les 7 gems `beardley*`, `lib/reporting.rb`, `config/initializers/beardley.rb` et les appels `Beardley::Report` de `DocumentTemplate#print`/`#export` doivent rester.

### 8.4 Fait dans ce lot

Suppression de 5 fichiers de gabarits morts, sans aucun effet sur la résolution des 73 natures (vérifié avant/après, résultat identique) :

- `eng/reporting/sale.jrxml` et `fra/reporting/matter.xml` — natures absentes de la nomenclature ;
- `fra/reporting/account_journal_entry_sheet.jrxml`, `outgoing_payment_list__check_letter.jrxml` et `outgoing_payment_list__standard.jrxml` — un `.odt` existe pour ces trois natures et le supplante systématiquement.

Il reste 13 fichiers Jasper, un par nature bloquante.

### 8.5 Anomalie relevée au passage

La nature `purchases_estimate` n'a **aucun** gabarit, ni ODT ni Jasper : `load_defaults` journalise `Cannot load a default document template` et ne crée pas de `DocumentTemplate`. Le bouton d'impression correspondant n'affiche donc rien. 23 autres natures sont dans le même cas (`entity_sheet`, `fixed_asset_sheet`, `prescription`, `stocks`, les registres viticoles…) — à arbitrer : gabarit manquant ou nature à retirer de la nomenclature.

### 8.6 Option 2 retenue : 7 natures migrées avec gabarits provisoires

L'option 2 a été choisie — écrire les classes `Printers::*` en s'appuyant sur les
champs déclarés par les `.jrxml`, et générer des gabarits `.odt` sans mise en
forme, à remettre en page ensuite.

`bin/generate_odt_template.rb` produit ces gabarits depuis une spécification JSON
(`config/reporting/odt_specs/`). **Piège ODF** : l'entrée `mimetype` doit être la
première de l'archive **et stockée sans compression**, sinon `MimeMagic` ne
reconnaît rien, `DocumentTemplate` garde `file_extension = xml` et tente de
parser le fichier comme du Jasper.

Migrées (7) : `journal_entry_sheet`, `animal_sheet`, `animal_list`,
`deposit_list`, `cultivable_zone_sheet`, `outgoing_delivery_docket`,
`purchases_invoice`. Chacune a désormais un printer, un gabarit ODT et une
branche PDF dans son contrôleur, placée **avant** `respond_with` — sans quoi la
requête retombait dans `Responder#to_pdf`, donc dans Jasper.

Restent 6 natures, toutes **sans bouton d'export** :

- `animal_husbandry_register` et `veterinary_booklet` — aucune référence hors
  nomenclature et gabarit : natures mortes ;
- `fr_pcg82_balance_sheet`, `fr_pcg82_profit_and_loss_statement`,
  `fr_pcga_balance_sheet`, `fr_pcga_profit_and_loss_statement` — listées dans
  `HIDDEN_AGGREGATORS` de `exports_controller.rb`, donc masquées de l'interface.

**Bilan** : 43 natures sur ODT, 6 sur Jasper, 24 sans gabarit. La surface Jasper
atteignable depuis l'interface est nulle. `rjb` et les gems `beardley*` restent
néanmoins nécessaires tant que ces 6 natures ne sont pas soit migrées, soit
retirées de la nomenclature — c'est un arbitrage produit, pas technique.

### 8.7 A.4 terminé : Jasper retiré, page Exports et agrégateurs supprimés

Arbitrage du 2026-09-09 : **supprimer la page Exports et les agrégateurs**, et
sortir les quatre natures `fr_pcg82_*` / `fr_pcga_*`.

Une correction préalable était nécessaire. J'avais présenté
`animal_husbandry_register` et `veterinary_booklet` comme des natures mortes, en
n'ayant cherché que les boutons `t.export` et les gestionnaires `format.pdf`.
Une troisième voie existait : `exports_controller` → `Aggeratio` → `ExportJob` →
`DocumentTemplate#export` → `Beardley::Report`. Or `config/aggregators/` ne
contenait **que** ces deux agrégateurs, et c'étaient les deux seules entrées de
la page Exports. À l'inverse, `Aggeratio['fr_pcg82_balance_sheet']` renvoyait
`nil` : les quatre natures comptables n'avaient aucun agrégateur et leurs
`.jrxml` étaient inertes.

Supprimé : `lib/aggeratio.rb` et `lib/aggeratio/`, `config/aggregators/`,
`exports_controller`, ses vues, son helper, `ExportJob`, la route, le groupe de
droits (renommé `synchronizations`, qu'il portait aussi), le chargement dans
`20-start.rb`, la prise en charge des agrégateurs de plugins et la méthode
`clean_aggregators!` de `Clean::Locales`.

Jasper avec : `rjb`, les 7 gems `beardley*`, `lib/reporting.rb` (et ses
*renderers* `Responder#to_pdf`…), `config/initializers/beardley.rb`,
`config/reporting/beardley/`, les 6 derniers gabarits `.jrxml`/`.xml`, et les
méthodes `DocumentTemplate#print`, `#export`, `.print` et `import_jasper`.

`bundle` passe de 169 à 161 dépendances déclarées et de 354 à 345 gems.

**Zéro nature n'est plus servie par Jasper** : `load_defaults` crée 43 gabarits
gérés, tous en `odt`. Un téléversement `.jrxml` est désormais refusé
(« Source is invalid ») plutôt qu'accepté en silence pour produire un gabarit
que plus rien ne saurait imprimer.

**Point de vigilance pour la reprise de données** : les gabarits personnalisés
(`managed: false`) restés en `file_extension = xml` ne sont plus imprimables. Le
tenant de test en compte 3, dont le fichier source n'existe même pas. À recenser
sur les tenants de production avant déploiement.

**Reste à arbitrer** : `Ekylibre::Reporting::FORMATS` annonce toujours
`pdf odt ods docx xlsx`, alors que la chaîne ODFReport ne produit que de l'ODT et
du PDF. La liste n'a pas été réduite ici, car la validation de
`DocumentTemplate#formats` retirerait silencieusement les formats devenus
invalides des enregistrements existants au premier enregistrement.
