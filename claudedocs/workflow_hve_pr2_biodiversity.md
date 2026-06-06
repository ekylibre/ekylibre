# Workflow — PR2 plugin `ekylibre-hve` : scoring Biodiversité

**Demande** : implémenter le thème **Biodiversité** (4 items 4.1-4.8, max 36 points, seuil de certif ≥ 10) du référentiel HVE3 V4.4, sur la base du squelette livré en PR1.

**Stratégie** : Systematic. Une PR ciblée sur le thème, modèles dans le core, services + UI dans le plugin (mêmes règles de séparation que PR1).

---

## 1. Pré-requis (état après PR1)

- ✅ Squelette plugin chargé, migrations + 5 modèles core (`HveAudit`, `HveAuditItem`, `HveCmrProduct`, `HveNitrogenExportCoefficient`, `HveScoringTable`)
- ✅ Rake `hve:reference:load` charge les seeds référentiels
- ✅ Vue index/show squelette
- ❌ Aucun calcul de score — c'est l'objet de PR2-5

PR2 introduit :
- 1 nouveau modèle core (`HveBiodiversityItem`) + 1 référentiel core (`HveIaeCoefficient`)
- Le service `Hve::Scoring::BiodiversityScorer` (orchestrateur du thème) + 8 sous-stratégies dans le plugin
- UI dédiée pour la saisie IAE + items manuels
- Cell dashboard de score biodiversité (réutilise `ChartsHelper` migré ECharts)

---

## 2. Détail des 8 items à scorer (référentiel V4.4 §4.1-4.8)

Tous les calculs sont **idempotents** (rejouables à partir des données stockées dans le tenant + saisies de l'audit) et écrivent dans `HveAuditItem` (1 ligne par code).

### 4.1 — IAE (Infrastructures Agro-Écologiques) — **CRITÈRE OBLIGATOIRE GATING + 0-9 pts**

**Précondition** : un inventaire `HveBiodiversityItem` non vide doit exister pour l'audit. Sinon : score 0 + **flag bloquant** dans `HveAudit.metadata['biodiversity_gate']`.

**Sub-scores** :
- 0-7 pts : table linéaire sur ratio IAE éligibles / terres arables (compte tenu d'exemptions : < 10 ha SAU, > 75 % prairies, etc.)
  - 4 % → 1 pt, 5 % → 2, 6 % → 3, 7 % → 4, 8 % → 5, 9 % → 6, ≥ 10 % → 7
- +2 pts bonus si ≥ 3 familles IAE différentes parmi `aquatique`, `herbager`, `ligneux`, `rocheux`

**Inputs** :
- `HveBiodiversityItem` : un par élément, avec `iae_family`, `iae_type`, `surface_or_length`, `coefficient`, `equivalent_iae_ha` (= surface_or_length × coefficient, calculé en hook)
- SAU totale de l'audit : agrégée depuis `ActivityProduction.support_shape_area` pour la campagne
- Surface terres arables : SAU moins prairies permanentes (filtrer par `Activity.family`)

### 4.2 — Taille parcelles — **0-5 pts**

**Calcul** : % SAU en parcelles < 6 ha **ou** prairies permanentes.
- < 40 % → 0, 40 % → 1, 50 % → 2, 60 % → 3, 70 % → 4, ≥ 80 % → 5

**Inputs** :
- `ActivityProduction.support_shape_area` par production
- `Activity.family` pour identifier prairies permanentes (`plant_farming` + nature herbacée pérenne — à vérifier nomenclature Onoma)

### 4.3 — Poids culture principale — **0-5 pts**

**Calcul** : % SAU **hors prairies permanentes** occupée par la culture dominante (la plus représentée en surface).
- ≥ 60 % → 0, 50 % → 1, 40 % → 2, 30 % → 3, 20 % → 4, < 20 % → 5

**Inputs** :
- Idem 4.2 + groupement par `Activity.cultivation_variety` ou `Activity.name`

### 4.4 — Nb espèces végétales cultivées — **0-6 pts**

**Calcul bracketé par 4.3** :
- Cas 1 (poids culture principale ≥ 60 %) : 4 espèces = 0, +1/espèce, max 5
- Cas 2 (poids culture principale < 60 %) : 4 espèces = 0, +1/espèce, max 6

**Inputs** :
- Distinct count des `Activity.cultivation_variety` actives sur la campagne

### 4.5 — Nb espèces animales — **0-3 pts**

**Calcul** : 0-1 espèce → 0, 2 → 1, 3 → 2, ≥ 4 → 3

**Inputs** :
- Distinct count des `Animal.variety` (ou `AnimalGroup`) actifs sur la campagne (présents ≥ 6 mois)

### 4.6 — Ruches — **0-1 pt**

**Calcul** : 1 pt si ≥ 3 ruches sédentaires (présentes ≥ 9 mois sur la ferme).

**Inputs** : à modéliser — Ekylibre n'a pas de modèle « ruche ». Options :
- Compter les `Equipment` avec `nature` = ruche (à coder en Onoma ?)
- Saisie manuelle dans `HveAuditItem` code `4.6`

**Décision PR2** : saisie manuelle pour cette PR (le modèle Equipment n'a pas de nature « ruche » dans Onoma actuellement). À automatiser quand Onoma sera enrichi.

### 4.7 — Variétés/races menacées — **0-6 pts**

**Calcul** : 1 pt par variété végétale menacée présente (cap 3) + 1 pt par race animale menacée présente (cap 3).

**Inputs** :
- Liste de référence = Arrêté 29/04/2015 (à vendoriser, ~150 entrées)
- Croisement avec `Activity.cultivation_variety` (végétal) et `Animal.variety` (animal)

**Décision PR2** : saisie manuelle dans `HveAuditItem` code `4.7.plant` et `4.7.animal` (cap appliqué côté scorer). La liste de référence ne devient utile que lorsqu'on aura un picker auto-complete : reportée à PR ultérieure.

### 4.8 — Qualité biologique du sol — **0-1 pt**

**Calcul** : 1 pt si test bêche OPVT **ou** analyse microbiologique réalisée pendant la campagne.

**Inputs** : saisie manuelle (booléen) dans `HveAuditItem` code `4.8`.

---

## 3. Modèles à introduire (dans le core Ekylibre)

### 3.1 — `HveBiodiversityItem`

Table : `hve_biodiversity_items`

```ruby
t.references :hve_audit, null: false, foreign_key: true, index: true
t.string  :iae_family, null: false      # aquatique | herbager | ligneux | rocheux
t.string  :iae_type, null: false        # 'haie' | 'mare' | 'arbre_isole' | 'bande_enherbee' | 'prairie_permanente' | ...
t.decimal :surface_or_length, precision: 12, scale: 3, null: false  # ha ou m
t.string  :unit, null: false            # 'ha' | 'm'
t.decimal :coefficient, precision: 6, scale: 3  # facteur de conversion vers ha-équivalent IAE
t.decimal :equivalent_iae_ha, precision: 12, scale: 4  # calculé via before_save
t.string  :location_notes
t.timestamps null: false

t.index %i[hve_audit_id iae_family]
```

**Méthodes** :
- `before_save :compute_equivalent` → `equivalent_iae_ha = surface_or_length × coefficient / 10_000` si unit = 'm', sinon × coefficient
- Lookup du coefficient via `HveIaeCoefficient.find_for(family:, type:, unit:)`

### 3.2 — `HveIaeCoefficient` (référentiel, seed)

Table : `hve_iae_coefficients`

```ruby
t.string  :iae_family, null: false       # idem
t.string  :iae_type, null: false         # idem
t.string  :unit, null: false             # 'ha' | 'm'
t.decimal :coefficient, precision: 6, scale: 3, null: false
t.string  :description
t.timestamps null: false

t.index %i[iae_family iae_type unit], unique: true
```

Seed depuis un YAML vendoré dans le plugin (`db/seeds/hve_iae_coefficients.yml`) chargé par la rake `hve:reference:load` (déjà en place).

**Sources des coefficients** : Plan de contrôle V4.4 annexe 1 (table officielle IAE). Échantillon initial ~15 entrées (haie, mare, bande enherbée, arbre isolé, prairie permanente, ripisylve, alignement d'arbres, etc.).

### 3.3 — Migrations (2 nouvelles)

| Fichier | Action |
|---|---|
| `db/migrate/<ts>_create_hve_biodiversity_items.rb` | Nouveau |
| `db/migrate/<ts>_create_hve_iae_coefficients.rb` | Nouveau |

---

## 4. Services scoring (dans le plugin)

### 4.1 — Structure

```
ekylibre-hve/
└── app/services/hve/scoring/
    ├── biodiversity_scorer.rb           # orchestrateur 8 items
    ├── biodiversity/
    │   ├── iae_scorer.rb                # 4.1
    │   ├── parcel_size_scorer.rb        # 4.2
    │   ├── main_crop_weight_scorer.rb   # 4.3
    │   ├── plant_species_count_scorer.rb # 4.4
    │   ├── animal_species_count_scorer.rb # 4.5
    │   ├── hives_scorer.rb              # 4.6
    │   ├── threatened_breeds_scorer.rb  # 4.7
    │   └── soil_quality_scorer.rb       # 4.8
    └── shared/
        ├── sau_calculator.rb            # SAU + ratios (réutilisable PR3-5)
        └── activity_inventory.rb        # cultures / animaux comptes / surfaces
```

### 4.2 — Pattern commun

Chaque sous-scorer expose :

```ruby
class Hve::Scoring::Biodiversity::IaeScorer
  attr_reader :audit, :inventory

  def initialize(audit:, inventory: nil)
    @audit = audit
    @inventory = inventory || Hve::Scoring::Shared::ActivityInventory.new(audit)
  end

  # Returns { code:, value_raw:, points:, points_max:, evidence:, auto_computed: }
  def call
    # ... compute ...
    {
      code: '4.1',
      theme: 'biodiversity',
      value_raw: ratio,
      points: derived,
      points_max: 9,
      auto_computed: true,
      evidence: {
        iae_total_ha: total,
        arable_ha: arable,
        families_count: families
      }
    }
  end
end
```

L'orchestrateur `BiodiversityScorer.call(audit:)` :
1. Construit l'inventaire commun une seule fois (SAU, productions, animaux).
2. Itère sur les 8 sous-scorers.
3. Upsert chaque résultat dans `HveAuditItem` (clé `(audit_id, code)`).
4. Met à jour `audit.score_biodiversity = items.sum(:points)`.
5. Met à jour `audit.metadata['biodiversity_gate'] = (item 4.1 IAE non vide)`.

**Idempotent** : `find_or_initialize_by(code:)` puis `update!(value_raw, points, evidence, auto_computed)`. Préserve les `value_manual` saisies par l'utilisateur (le `value_used` recalculé via callback du modèle).

### 4.3 — Module partagé `Shared::SauCalculator`

```ruby
class Hve::Scoring::Shared::SauCalculator
  def initialize(audit)
    @audit = audit
    @campaign = audit.campaign
  end

  def total_sau_ha               # somme support_shape_area de toutes les productions
  def permanent_grassland_ha     # filtre par activity.family ou cultivation_variety
  def arable_ha                  # total - prairies permanentes
  def small_parcels_ha           # somme des productions < 6 ha
  def main_crop_share            # % SAU hors prairies permanentes occupée par dominante
  def crops_count                # distinct cultivation_variety
  def animal_species_count       # distinct Animal.variety actifs ≥ 6 mois
end
```

Mis en cache via `Rails.cache.fetch` à clé `[audit_id, campaign_updated_at]` pour éviter de recompiler à chaque sous-scorer (8 appels en cascade).

---

## 5. UI (dans le plugin)

### 5.1 — Vue dashboard `show.html.haml` enrichie

Le squelette PR1 affiche 4 cells vides. PR2 enrichit la cell « Biodiversité » :
- Score actuel `score_biodiversity / 36` avec jauge ECharts
- Liste des 8 items avec leurs points / max
- Lien « Saisir / Modifier » → vue dédiée biodiversité

### 5.2 — Nouvelle vue dédiée saisie biodiversité

Route : `GET /backend/hve_audits/:id/biodiversity` (action custom du controller).

Layout :
1. **Block IAE** (4.1) : tableau éditable des `HveBiodiversityItem` (ajout/édition/suppression via cocoon ou turbo-frame). Colonnes : famille, type, longueur/surface, unité, coefficient (auto), équivalent ha (auto), notes.
2. **Block items auto-calculés** (4.2, 4.3, 4.4, 4.5) : tableau read-only des valeurs calculées + bouton « Recalculer ».
3. **Block items manuels** (4.6, 4.7, 4.8) : formulaire de saisie + champ libre de justification (`HveAuditItem.notes`).
4. **Block résumé** : score biodiversité + verdict du seuil (≥ 10 OK / < 10 KO).

### 5.3 — Cell dashboard mise à jour

Pour cohérence avec l'écosystème dashboard d'Ekylibre, ajouter dans `app/views/backend/cells/hve_biodiversity_cell/show.html.haml` un widget compact :
- Score / 36 + jauge
- Liste compacte des items
- Bouton « Détail » → vue saisie ci-dessus

Le cell sera invoqué depuis `backend/dashboards/biodiversity` (à définir aussi côté plugin ou par l'utilisateur dans la config du dashboard).

### 5.4 — Nouveau controller : actions custom

```ruby
class Backend::HveAuditsController < Backend::BaseController
  # CRUD inchangé...

  def biodiversity
    return unless @hve_audit = find_and_check
    @scorer_result = Hve::Scoring::BiodiversityScorer.call(audit: @hve_audit)
    @biodiversity_items = @hve_audit.biodiversity_items
    @audit_items_by_code = @hve_audit.items.theme('biodiversity').index_by(&:code)
  end

  def recompute_biodiversity
    return unless @hve_audit = find_and_check
    Hve::Scoring::BiodiversityScorer.call(audit: @hve_audit)
    redirect_to biodiversity_backend_hve_audit_path(@hve_audit), notice: :scores_recomputed.tl
  end
end
```

Routes générées automatiquement par `manage_restfully` ? Non — les actions custom doivent être déclarées explicitement. Ajouter dans `config/routes.rb` du core :

```ruby
resources :hve_audits do
  member do
    get  :biodiversity
    post :recompute_biodiversity
  end
end
```

À insérer dans le bloc backend du `routes.rb` du core (pas dans le plugin — Ekylibre n'utilise pas `routes.rb` par engine).

---

## 6. i18n à enrichir

Compléter `config/locales/{eng,fra}/hve.yml` :

```yaml
fra:
  labels:
    biodiversity_section: "Saisie Biodiversité"
    iae_inventory: "Inventaire IAE (Infrastructures Agro-Écologiques)"
    iae_family: "Famille IAE"
    iae_type: "Type"
    surface_or_length: "Surface / Longueur"
    unit: "Unité"
    coefficient: "Coefficient"
    equivalent_iae_ha: "Équivalent IAE (ha)"
    scores_recomputed: "Scores recalculés."
    biodiversity_gate_open: "Inventaire IAE manquant — audit non éligible."
  hve:
    iae_families:
      aquatique: "Aquatique"
      herbager: "Herbager"
      ligneux: "Ligneux"
      rocheux: "Rocheux"
    items:
      "4.1": "IAE / Terres arables"
      "4.2": "Taille des parcelles"
      "4.3": "Poids de la culture principale"
      "4.4": "Nombre d'espèces végétales"
      "4.5": "Nombre d'espèces animales"
      "4.6": "Présence de ruches"
      "4.7": "Variétés / races menacées"
      "4.8": "Qualité biologique du sol"
```

Et équivalent `eng`.

---

## 7. Tests

### 7.1 — Modèles (dans le core)

- `test/models/hve_biodiversity_item_test.rb` : validations, hook `compute_equivalent`
- `test/models/hve_iae_coefficient_test.rb` : seed correctement chargé, lookup `find_for`

### 7.2 — Services (dans le plugin)

`test/services/hve/scoring/biodiversity/` — 1 fichier par item, fixtures dédiées :

- `iae_scorer_test.rb` : 4 cas (ratio < 4 %, ratio 7 %, ratio 10 %, ≥ 3 familles)
- `parcel_size_scorer_test.rb` : 3 cas (< 40 %, 60 %, ≥ 80 %)
- `main_crop_weight_scorer_test.rb` : 4 cas (≥ 60 %, 40 %, 20 %, < 20 %)
- `plant_species_count_scorer_test.rb` : cas bracketé par 4.3 (2 sous-cas)
- `animal_species_count_scorer_test.rb` : 4 cas (0, 2, 3, ≥ 4)
- `hives_scorer_test.rb` : 2 cas (saisie 2 ruches, saisie 5 ruches)
- `threatened_breeds_scorer_test.rb` : 3 cas (0, 2 plantes, 3+1 cap)
- `soil_quality_scorer_test.rb` : 2 cas (oui / non)
- `biodiversity_scorer_test.rb` : test d'intégration de l'orchestrateur (somme + gate)

### 7.3 — Service partagé

`test/services/hve/scoring/shared/sau_calculator_test.rb` : 5-6 tests sur les agrégations.

### 7.4 — Controller

`test/controllers/backend/hve_audits_controller_test.rb` : 2 tests (action `biodiversity` rendue, action `recompute_biodiversity` met à jour les scores).

---

## 8. Risques et mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Coefficients IAE évoluent dans le Plan de contrôle | Moyenne | Faux scores | Seed YAML versionné, rake `hve:reference:load` réintégrable |
| Classification "prairie permanente" vs "temporaire" ambiguë côté Activity | Élevée | Mauvaise SAU prairies | Documenter convention via `Activity.cultivation_variety` Onoma + cas de bord testé |
| Filière de la ferme non identifiée (polyculture-élevage) | Faible (PR2 ne dépend pas de la filière) | — | Filière déterminée en PR3 (phyto) |
| Activity.support_shape_area renvoie nil sur productions sans géométrie | Moyenne | Sous-estimation SAU | Fallback sur `working_zone_area_value` ; signaler à l'utilisateur les productions sans géométrie dans evidence |
| `Animal.variety` distinct ne correspond pas à « espèce » (mais à race) | Moyenne | Sur-estimation 4.5 | Mapper variety → espèce via Onoma `Master*` ; vendoriser un mini mapping si nécessaire |
| Le hook `compute_equivalent` boucle infini si modifié en after_save | Faible | — | Implémenter en `before_save`, pas `after_save`. Tests dédiés |
| Performance : 8 scorers × 1000 productions = 8000 SQL queries | Moyenne | Lent sur grosses fermes | `SauCalculator` met en cache toutes les agrégations en 1 requête + memoize |
| Permanence multi-année (l'inventaire IAE est-il reconduit ?) | Moyenne | UX médiocre si tout retaper chaque année | Action « Cloner depuis l'audit précédent » dans la vue saisie (à ajouter PR2 ou plus tard — recommandé PR2) |

---

## 9. Arbre de dépendances

```
1. Migrations (HveBiodiversityItem + HveIaeCoefficient)  ─┐
2. Modèles + seed IAE                                     ├─► 4. Services scoring ─┐
3. Rake update (charge HveIaeCoefficient)                 ┘                          ├─► 6. UI saisie + dashboard ─► 7. Tests + vérif
                                                                                    │
                                                          5. Hooks de raccordement ─┘
                                                          (callback recompute sur
                                                           ActivityProduction save)
```

Étapes 1-3 indépendantes une fois la migration écrite. Étape 4 dépend de 1+2. Étape 5 (callbacks de recompute) optionnelle pour PR2 — peut être traitée en PR ultérieure avec le `HveScoreRefreshJob`.

---

## 10. Critères d'acceptation

1. ✅ Le score biodiversité s'affiche sur la vue `show` d'un audit avec une valeur cohérente sur ≥ 1 jeu de fixtures (un tenant fictif avec 5 productions, 2 animaux, 4 IAE).
2. ✅ La saisie IAE permet d'ajouter, modifier, supprimer une entrée — le total `equivalent_iae_ha` se recalcule.
3. ✅ Le score 4.1 est `0` et le `biodiversity_gate` est ouvert si aucun `HveBiodiversityItem` n'existe.
4. ✅ Les 4 items auto (4.2-4.5) produisent le bon score sur les fixtures (tests unitaires).
5. ✅ Les 3 items manuels (4.6-4.8) acceptent une saisie via `HveAuditItem.value_manual` et la traduisent en points via leur sous-scorer.
6. ✅ `BiodiversityScorer.call` est idempotent (rejouable sans changer de score).
7. ✅ La vue saisie biodiversité affiche les 8 items, distingue auto/manuel, et propose un bouton « Recalculer ».
8. ✅ Sur un audit de tenant réel (`djoulin`), le calcul prend < 3 secondes.

---

## 11. Fichiers touchés (synthèse)

**Dans le core Ekylibre** :

| Fichier | Action |
|---|---|
| `db/migrate/<ts>_create_hve_biodiversity_items.rb` | Nouveau |
| `db/migrate/<ts>_create_hve_iae_coefficients.rb` | Nouveau |
| `app/models/hve_biodiversity_item.rb` | Nouveau |
| `app/models/hve_iae_coefficient.rb` | Nouveau |
| `app/models/hve_audit.rb` | Modif (ajout `has_many :biodiversity_items`) |
| `config/routes.rb` | Modif (member actions `biodiversity`, `recompute_biodiversity` sur `hve_audits`) |
| `test/models/hve_biodiversity_item_test.rb` | Nouveau |
| `test/models/hve_iae_coefficient_test.rb` | Nouveau |
| `test/controllers/backend/hve_audits_controller_test.rb` | Nouveau |

**Dans le plugin `ekylibre-hve`** :

| Fichier | Action |
|---|---|
| `app/controllers/backend/hve_audits_controller.rb` | Modif (actions `biodiversity`, `recompute_biodiversity`) |
| `app/services/hve/scoring/biodiversity_scorer.rb` | Nouveau |
| `app/services/hve/scoring/biodiversity/*.rb` | 8 nouveaux (un par item) |
| `app/services/hve/scoring/shared/sau_calculator.rb` | Nouveau |
| `app/services/hve/scoring/shared/activity_inventory.rb` | Nouveau |
| `app/views/backend/hve_audits/biodiversity.html.haml` | Nouveau (vue saisie) |
| `app/views/backend/hve_audits/_biodiversity_items_form.html.haml` | Nouveau (partial IAE) |
| `app/views/backend/hve_audits/show.html.haml` | Modif (jauge biodiv + lien vers saisie) |
| `app/views/backend/cells/hve_biodiversity_cell/show.html.haml` | Nouveau (dashboard cell) |
| `config/locales/fra/hve.yml` | Modif (clés biodiv) |
| `config/locales/eng/hve.yml` | Modif (clés biodiv) |
| `db/seeds/hve_iae_coefficients.yml` | Nouveau (vendored, ~15 entrées) |
| `lib/tasks/hve.rake` | Modif (chargement du nouveau seed) |
| `test/services/hve/scoring/biodiversity/*_test.rb` | 8 nouveaux |
| `test/services/hve/scoring/shared/sau_calculator_test.rb` | Nouveau |
| `test/services/hve/scoring/biodiversity_scorer_test.rb` | Nouveau (intégration) |

---

## 12. Estimation et phasage interne

PR2 estimée à **3 jours-développeur**, découpable en 4 commits successifs :

- **C1** : migrations + modèles + seed IAE + rake update (~0.5 j)
- **C2** : `SauCalculator` + `ActivityInventory` + 5 scorers auto (4.1-4.5) + tests unitaires (~1.5 j)
- **C3** : 3 scorers manuels (4.6-4.8) + orchestrateur + tests intégration (~0.5 j)
- **C4** : UI (vue saisie + cell dashboard) + controller actions + i18n + tests controller (~0.5 j)

Un test « bout en bout » sur un tenant réel (`djoulin`) en clôture.

---

## 13. Décisions ouvertes à valider avant `/sc:implement`

1. **Filière « prairie permanente »** : on s'aligne sur `Activity.family == 'plant_farming'` + `cultivation_variety` correspondant à une  crop_sets "meadow" dans Onoma
2. **Ruches (4.6)** : saisie manuelle confirmée pour PR2
3. **Variétés / races menacées (4.7)** : picker auto-complete depuis liste Arrêté 29/04/2015
4. **Recompute** : déclencher automatiquement après chaque modification d'`Intervention` / `Animal` / `ActivityProduction` (callback + job)  attendre PR6 (verdict + recompute global)
5. **Action « Cloner depuis l'audit précédent »** : intégrée à PR2

Mes recommandations : (1) `Activity.family + Onoma cultivation_variety` pour rester sans migration core ; (2-3) saisie manuelle PR2, automatisation différée ; (4) attendre PR6, sinon on multiplie les modifications dans le core ; (5) inclure dans PR2, c'est un gros gain UX pour 30 lignes de code.

---

## 14. Prochaine étape

Valider les 5 décisions du §13, puis lancer `/sc:implement claudedocs/workflow_hve_pr2_biodiversity.md`.
