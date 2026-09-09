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
| `ekylibre-planning` | **2023-03-20** | `rails ~> 5.2` + `coffee-rails` | 5 819 | 37 | 1 | **Porter** — en production, seul fork à couplage réel |
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

Sur les 23 dépôts, **un seul** (`ekylibre-planning`) présente un couplage substantiel : 37 références aux internes d'ActiveRecord, dernier commit en mars 2023, dépendances `coffee-rails` / `vuejs-rails`. Il est chargé en production (`docker/prod/Gemfile.prod`), donc non abandonnable.

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
| Portage réel | **1** — `ekylibre-planning` | substantiel |
| Remplacement | 4 — `active_list`, `apartment`, `state_machine`, `paperclip` | déjà chiffré en A.2/A.3/A.5/A.7 |
| Amont mort à contourner | 1 — `bootstrap-slider-rails` | faible, disparaît au lot G |

**B.9 est ramené de 30 à ~12 j·h.** Le lot B passe donc de ~118 à **~100 j·h**.

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
5. **`ekylibre-planning`** — le seul portage réel ; peut avancer en parallèle.
6. **A.7 `active_list`** — dépend d'ADR-6.3 (choix du front).
