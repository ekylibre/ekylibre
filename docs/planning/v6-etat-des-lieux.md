# Ekylibre v6 — État des lieux au 13 septembre 2026

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
| Suite | 3650 tests, 17 échecs, 15 erreurs | **identique** |
| RuboCop | 1.11, plantait sous Ruby 3.4 | **1.91, sort au vert** (809 offenses au todo) |
| ESLint | 1657 erreurs | **0 erreur** |

Le lot B est achevé : **la cible du plan est atteinte**. Le critère de sortie
retenu à chaque palier était la parité de la suite, jamais le simple démarrage de
l'application — et il a été tenu huit fois de suite, framework puis valeurs par
défaut.

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

- **la suite n'est pas verte** : 17 échecs et 15 erreurs, hérités des paliers
  antérieurs. C'est la raison pour laquelle le job `Tests` de la CI échoue, et
  il échouera tant que ces 32 cas ne seront pas traités. Trois instabilités
  connues s'y ajoutent (ordre des tests, `Devise.mappings` en exécution isolée,
  réécriture de `db/structure.sql` par la suite) — voir `CLAUDE.md` ;
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
- la CI ne se déclenche que sur `main`, `5.0-beta` et `6.0-alpha` : **renommer la
  branche éteint la CI** si l'on n'y touche pas.

## 4. Ce qui vient ensuite

Le plan prévoit les lots C à H. Deux d'entre eux forment le cœur de la v6 et
sont désormais débloqués :

**Lot C — schéma mono-base (~90 j·h).** Passer des schémas PostgreSQL par ferme à
une base unique avec `tenant_id`, PK composites et RLS `FORCE`. Le palier 7.1 a
livré ce qui manquait côté ORM : `query_constraints` et les PK composites
natives. Porte d'entrée : le prototype sur trois tables (C.1), qui couvre à lui
seul PK/FK composites, STI et colonne géométrique.

**Lot D — runtime tenant et preuve d'isolation (~110 j·h).** Plan de contrôle,
`TenantRecord`, annotation des 1 413 associations, contexte `set_config` en
transaction, propagation aux chemins asynchrones, tests d'isolation générés,
retrait d'Apartment. Dépend de C.

**Lot E — restauration d'archives v5 (~56 j·h)**, puis F (API et offline-first),
G (découplage du front, API-only) et H (satellites).

## 5. À trancher avant d'ouvrir le lot C

1. **La production suit-elle maintenant ?** Le palier 8.1 tient, mais il n'est
   pas déployé et l'écart avec la production grandit. Trois questions liées :
   basculer `docker/prod/Dockerfile` en Ruby 3.4, relever le plancher du
   `Gemfile`, et décider si la v6 se déploie avant ou après le mono-schéma.
2. **Dans quel ordre prendre la dette du lot B ?** Les 32 tests en échec valent
   d'être traités avant le lot C : ils rendent la CI illisible et masqueront les
   régressions du chantier de schéma. `raise_on_assign_to_attr_readonly` touche
   les mêmes rappels comptables que ces tests — il y a là un lot cohérent.
3. **PostgreSQL 13 est-il tenable pour le lot C ?** La RLS, les PK composites et
   les index tenant-aware fonctionnent en 13, mais monter l'image de base
   (`postgresql-client`) conditionne tout passage en 15/16 et devrait être
   décidé avant d'écrire 240 migrations.
4. **Les 14 tables du lexique sans clé** : leur donner une clé relève du lot C
   (C.2, classification des 313 tables). Le faire au passage lèverait
   `raise_on_missing_required_finder_order_columns`.
5. **`turnout` et le mode maintenance** : il retient `rack` sous la 3 et
   `sidekiq` sous la 8. Le lot B.7 prévoit Solid Queue ; la question se posera
   à ce moment-là, pas avant.

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
