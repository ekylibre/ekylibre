# Workflow — Plugin `ekylibre-hve` (HVE3 v4.4)

**Demande** : construire un plugin Ekylibre dédié à l'audit HVE3 (Haute Valeur Environnementale), pré-rempli depuis les données existantes du tenant, permettant la saisie complémentaire, le calcul des 4 scores et l'export au format Excel exigé par Certibase.

**Stratégie** : Systematic. **Modèles et migrations dans le core Ekylibre** ; **engine, services de scoring, controllers, vues, seeds et tests d'intégration dans le plugin** `/home/djoulin/projects/ekylibre-plugins/ekylibre-hve`. Livré en **6 PRs successives**.

---

## 0. État d'avancement

| PR | Périmètre | Statut | Doc dédié |
|---|---|---|---|
| **PR1** | Squelette plugin + modèles fondamentaux + référentiels (CMR, azote, IFT régionaux) + rake `hve:reference:load` + vues squelette | ✅ **Livré** | (intégré dans ce doc) |
| **PR2** | Thème Biodiversité (8 items, 36 pts) + modèle IAE + scorers + UI dédiée + clone audit précédent | ✅ **Livré** | `workflow_hve_pr2_biodiversity.md` |
| **PR3** | Thème Phytosanitaire (10 items, 63 pts) + kill-switch CMR1 + IFT (réutilise `PfiInterventionParameter`) | 📋 **Planifié** | `workflow_hve_pr3_phytosanitary.md` |
| PR4 | Thème Fertilisation (9 items, 53 pts) + bilan azoté (BGA / apparent) | À planifier | — |
| PR5 | Thème Irrigation (8 items, 34 pts) + détection « Sans objet » | À planifier | — |
| PR6 | Verdict global + export Excel Certibase (préservation du template ministériel) | À planifier | — |

---

## 1. Contexte HVE3 v4.4 (référentiel applicable depuis 01/01/2025)

**Plan de contrôle** : `Plan_controle_niveau3_V4.4_2024.pdf` (118 p). Voies A/B supprimées au 01/01/2025 — schéma unique :

| Thème | Items | Max pts | Seuil certif | Notes |
|---|---|---|---|---|
| Biodiversité | 8 (§4.1-4.8) | 36 | ≥ 10 | IAE = critère obligatoire (gating) |
| Phytosanitaire | 10 (§5.1-5.10) | 63 | ≥ 10 | **Kill-switch CMR1** sans dérogation → audit invalide |
| Fertilisation | 9 (§6.1-6.9) | 53 | ≥ 10 | Bilan N (BGA ou Bilan apparent) |
| Irrigation | 8 (§7.1-7.8) | 34 | ≥ 10 | « Sans objet » → auto-OK si non-irrigant |

**Certification** = chacun des 4 scores ≥ 10. Pas de seuil global cumulé.

**Filières** : barèmes différents selon Grandes Cultures (GC), Viticulture, Arboriculture, Horticulture/Pépinière, Élevage. Tables de scoring distinctes dans la grille Excel pour Pf/Pc IFT par bassin/région.

**Transmission** (note 2025-06-10) : depuis le 28/05/2025, Certibase reçoit les grilles xlsx via les organismes certificateurs. **Pas d'API publique** — le format de transport est le fichier xlsx ministériel, non modifié structurellement (tabs et cellules doivent rester intacts).

---

## 2. Inventaire Ekylibre — confirmé après investigation PR1-PR3

### Déjà disponible (à consommer)

| Besoin HVE | Source Ekylibre | Confirmé par |
|---|---|---|
| Phyto interventions (procedure_name, date, produit, dose, surface) | `Intervention` (`PHYTO_PROCEDURE_NAMES` ligne 72, `using_phytosanitary?` ligne 1177) | PR3 |
| AMM, substances actives, natures (Herbicide/Fongicide/…) | `RegisteredPhytosanitaryProduct` lexicon : `france_maaid`, `active_compounds`, `natures`, `state` | PR3 |
| Usages référence (dose, ZNT, BBCH, durée d'application) | `RegisteredPhytosanitaryUsage` lexicon | PR3 |
| **IFT déjà calculé** par traitement | `PfiInterventionParameter` (segment_code S2-S6, pfi_value, response API) — alimenté par `PfiCalculationJob` | PR3 ⭐ |
| Inputs phyto (produit, dose, surface) | `InterventionInput` : `product_id`, `quantity_value`, `quantity_unit_name`, `working_zone_area_value` | PR3 |
| Cibles d'intervention | `InterventionTarget` : `product_id`, `working_zone_area_value`, `working_zone` (PostGIS) | PR3 |
| SAU, assolement, productions | `Activity`, `ActivityProduction.support_shape_area`, scope `of_campaign` | PR2 |
| Filière (vine_farming/plant_farming/livestock/…) | `Activity#family` (predicates auto-générés via `refers_to :family`) | PR2 |
| Animaux & effectifs | `Animal < Bioproduct`, scope `alive(at:)` | PR2 |
| Plan de fumure partiel | `ManureManagementPlan` + `ManureManagementPlanZone` | À confirmer PR4 |
| Génération PDF | `DocumentTemplate` (ODT/Reporting) | PR6 |
| Dashboard cells (beehive) | `backend.html.haml` + `ChartsHelper` (ECharts migré) | PR2 |

### Absent → introduit côté plugin/core HVE

| Besoin | Décision | Justification |
|---|---|---|
| IAE (haies, bandes enherbées, mares, prairies permanentes) | **Modèle `HveBiodiversityItem`** (core, créé PR2) | Aucun équivalent dans le core Ekylibre |
| Classification CMR1/CMR2 par AMM | **Table `HveCmrProduct`** (core, créée PR1) | `RegisteredPhytosanitaryRisk` stocke des phrases de risque en **texte FR libre**, pas les codes H standardisés (H340/H351/H360…). Le modèle `RegisteredPhytosanitaryPhrase` est référencé mais **sans table**. Confirmation PR3 : le lexicon ne peut pas suppléer. |
| Coefficients export azote par culture × organe | **Table `HveNitrogenExportCoefficient`** (core, créée PR1) | Pas dans Onoma ni lexicon. Source Comifer 2013. |
| Tables Pc/Pf IFT régionales | **Table `HveScoringTable`** (core, créée PR1) | Spécifique HVE, mises à jour avec la grille ministérielle annuelle. |
| Coefficients IAE (conversion m → ha-équivalent) | **Table `HveIaeCoefficient`** (core, créée PR2) | Annexe 1 Plan V4.4. |
| Container d'audit versionné | **Modèles `HveAudit` + `HveAuditItem`** (core, créés PR1) | `Inspection` du core trop spécifique. |
| Variétés/races menacées (Arrêté 29/04/2015) | Saisie manuelle PR2, vendrer la liste en PR ultérieure | Faible volume, pas critique pour la v0. |
| Outils annexes (matériels annexe 6/7, OAD, BSV) | Saisie manuelle PR3-5 | Pas modélisable proprement dans le core sans connaître l'usage. |

### Séparation core / plugin (règle établie PR1)

| Type | Emplacement | Pourquoi |
|---|---|---|
| Migrations (`db/migrate/*.rb`) | **Core** Ekylibre | Apartment migre toutes les tenants depuis `db/migrate` |
| Modèles ActiveRecord (`app/models/hve_*.rb`) | **Core** Ekylibre | Nécessaires à `manage_restfully` / unroll / autoload Rails au boot, même sans tenant |
| Routes | **Core** (`config/routes.rb`) | Pas d'isolation par engine dans Ekylibre |
| Services scoring (`app/services/hve/scoring/*`) | **Plugin** | Logique métier propre au plugin |
| Controllers | **Plugin** (`app/controllers/backend/hve_*`) | Auto-chargés via `prepend_view_path` de l'engine |
| Vues HAML | **Plugin** (`app/views/backend/hve_*`) | Idem |
| Tests modèles + services | **Core** (`test/...`) | Réutilise `test_helper`, fixtures `Campaign`/`User`, lexicon de test |
| Seeds référentiels (CSV/YAML) | **Plugin** (`db/seeds/*`) | Versionné avec le code du plugin, chargé via rake |
| i18n, navigation.xml, gemspec, engine | **Plugin** | Conventions Ekylibre plugins |

---

## 3. Architecture — état réel après PR2

### 3.1 Squelette plugin (livré PR1, étendu PR2)

```
ekylibre-plugins/ekylibre-hve/
├── ekylibre_hve.gemspec
├── README.md
├── Gemfile
├── Rakefile
├── lib/
│   ├── ekylibre_hve.rb              # Module + constantes (CERTIFICATION_THRESHOLD, MAX_POINTS, …)
│   ├── ekylibre_hve/
│   │   ├── engine.rb                # Rails::Engine + init i18n/navigation/views
│   │   ├── ext_navigation.rb        # injection navigation.xml dans l'arbre core
│   │   └── version.rb
│   └── tasks/hve.rake               # hve:reference:load + hve:reference:status
├── app/
│   ├── controllers/backend/
│   │   ├── hve_audits_controller.rb              # PR1 + actions custom PR2 (biodiversity, recompute, clone)
│   │   └── hve_biodiversity_items_controller.rb  # PR2
│   ├── services/hve/scoring/        # PR2+
│   │   ├── biodiversity_scorer.rb               # orchestrateur thème (PR2)
│   │   ├── biodiversity/                        # 8 sous-scorers (PR2)
│   │   ├── shared/sau_calculator.rb             # SAU / cultures / animaux (PR2, réutilisé PR3-5)
│   │   ├── phyto_scorer.rb                      # à venir PR3
│   │   ├── phyto/                               # à venir PR3
│   │   ├── shared/phyto_inventory.rb            # à venir PR3
│   │   ├── shared/filiere_detector.rb           # à venir PR3
│   │   ├── fertilisation_scorer.rb              # à venir PR4
│   │   ├── irrigation_scorer.rb                 # à venir PR5
│   │   └── audit_scorer.rb                      # orchestrateur global (PR6)
│   └── views/backend/
│       ├── hve_audits/{index,show,new,edit,biodiversity}.html.haml
│       └── hve_biodiversity_items/{_form,new,edit}.html.haml
├── config/
│   ├── locales/{eng,fra}/hve.yml
│   └── navigation.xml
├── db/
│   ├── seeds/
│   │   ├── hve_cmr_products_2025_sample.csv     # PR1 (~20 lignes échantillon)
│   │   ├── hve_nitrogen_exports.csv             # PR1 (~21 lignes Comifer)
│   │   ├── hve_scoring_tables.yml               # PR1 (~20 lignes IFT régionales)
│   │   └── hve_iae_coefficients.yml             # PR2 (16 lignes)
│   └── templates/                                # PR6 : grilles xlsx Certibase
└── bin/
    └── import_cmr_products.rb                    # PR1 : script d'extraction XLSX → CSV
```

### 3.2 Modèles dans le core Ekylibre (livrés PR1-PR2)

**Livrés PR1** (5 modèles, 5 migrations) :

| Modèle | Rôle |
|---|---|
| `HveAudit` | Container par campagne, scores cachés, verdict, métadonnées (`biodiversity_gate`, etc.) |
| `HveAuditItem` | Une ligne par critère scoré (~35 par audit), `value_raw` / `value_manual` / `value_used` |
| `HveCmrProduct` | Snapshot annuel ministère (AMM → CMR1/CMR2) — **maintenue malgré le lexicon** (cf. §2) |
| `HveNitrogenExportCoefficient` | Coefficients Comifer par culture × organe |
| `HveScoringTable` | Tables Pc/Pf IFT par filière × région |

**Livrés PR2** (2 modèles, 2 migrations) :

| Modèle | Rôle |
|---|---|
| `HveIaeCoefficient` | Lookup IAE famille × type × unité → coefficient (annexe 1 Plan V4.4) |
| `HveBiodiversityItem` | Inventaire IAE par audit, hook `compute_equivalent` calcule `equivalent_iae_ha` |

**À introduire PR3** : **aucun nouveau modèle, aucune migration** (confirmé par l'investigation lexicon/PFI/interventions).

**À introduire PR4** : `HveNitrogenBalance` (un par audit, BGA ou Bilan apparent).

### 3.3 Services et calcul

Pattern établi PR2 : 1 sous-scorer par item, 1 orchestrateur par thème, 1 module partagé `Shared::*` pour les agrégations coûteuses (cache memoizé).

**Idempotence** : tous les scorers sont rejouables. Les `value_manual` sont préservées d'un rejeu à l'autre.

**Déclenchement** :
- Bouton « Recalculer » sur la vue thème (PR2 OK)
- Bouton « Relancer PFI » sur la vue phyto (PR3)
- Job auto sur Intervention/Sale/Purchase save : **différé à PR6** pour ne pas étaler des modifications dans le core sur 4 PRs

### 3.4 UI

**Navigation** : section « Certification HVE > Audits HVE » sous le menu principal (PR1).

**Vue show audit** (PR1, enrichie PR2) : 4 cells (1 par thème) + cell verdict, lien « Saisir / Voir » sur la cell biodiversité (PR2).

**Vues thème** : une page dédiée par thème, structurée en blocks (PR2 : biodiversity ; PR3 : phytosanitary ; etc.).

**Saisie IAE** (PR2) : CRUD nested sur `hve_biodiversity_items`, action « Cloner depuis audit précédent » incluse.

**Export Excel** (PR6) : remplit le template ministériel `grille-audit-hvev4-v1.14 - vf.xlsx` sans en altérer la structure.

---

## 4. Phasage en PRs

### PR1 — Skeleton + données de référence ✅ **Livré**

- Engine + gemspec + plugin registration (`Gemfile.local` pour dev local)
- 5 modèles core (`HveAudit`, `HveAuditItem`, `HveCmrProduct`, `HveNitrogenExportCoefficient`, `HveScoringTable`)
- 5 migrations core
- Rake `hve:reference:load` (CMR + azote + scoring + IAE)
- Navigation `Certification HVE > Audits HVE`
- Vue index + new + show squelette
- 18 tests modèles, 44 assertions, 0 échec

**Effort réel** : ~2 jours (conforme estimation).

### PR2 — Biodiversité ✅ **Livré**

- 2 modèles core (`HveIaeCoefficient`, `HveBiodiversityItem`)
- 2 migrations core
- 8 sous-scorers + 1 orchestrateur + 2 modules partagés (`SauCalculator`, `ActivityInventory`)
- 16 coefficients IAE seedés
- 3 actions custom controller : `biodiversity`, `recompute_biodiversity`, `clone_from_previous`
- Vue dédiée saisie biodiversité + CRUD nested IAE items
- Routes ajoutées dans `config/routes.rb` du core
- 34 tests (modèles + services + orchestrateur), 53 assertions, 0 échec
- Vérifié end-to-end sur tenant `djoulin` : 3 IAE → score 7/36, gate `open`, bonus +2 pts (3 familles)

**Effort réel** : ~3 jours (conforme estimation). **Bug attrapé en cours** : association `biodiversity_items` cachée en mémoire après `destroy_all` → fix via requête fresh dans `IaeScorer`.

### PR3 — Phytosanitaire 📋 **Planifié**

Voir `workflow_hve_pr3_phytosanitary.md`. Points-clés :

- 🎉 **Zéro nouvelle migration, zéro nouveau modèle** (confirmé par l'investigation lexicon/PFI/interventions)
- Item 5.3 IFT = **lecture seule + agrégation** de `PfiInterventionParameter.pfi_value` (déjà calculé par `PfiCalculationJob`)
- Item 5.1 CMR : croisement `Intervention#inputs.product.france_maaid` ⋈ `HveCmrProduct` + kill-switch
- 10 sous-scorers + 1 orchestrateur + 2 modules partagés (`PhytoInventory`, `FiliereDetector`)
- Vue dédiée avec alerte CMR rouge + bouton « Relancer PFI »

**Effort estimé** : 4 j-dev.

### PR4 — Fertilisation + bilan azoté

- Modèle core `HveNitrogenBalance` (BGA ou Bilan apparent)
- Service `Hve::NitrogenBalance::Computer` agrège :
  - Effluents produits (depuis `Animal` + coefficients excrétion N — à vendoriser)
  - Effluents importés/exportés (via `Purchase`/`Sale` ou saisie)
  - Engrais minéraux (depuis interventions fertilisantes)
  - Exports cultures (via `Sale` × `HveNitrogenExportCoefficient` PR1)
- Détection BGA vs Bilan apparent (élevage présent → BGA)
- `Hve::Scoring::FertilisationScorer` (6.1-6.9)
- Vue dédiée bilan N (tableau structuré façon Excel original)

**Effort estimé** : 5 j-dev.

### PR5 — Irrigation

- `Hve::Scoring::IrrigationScorer` (7.1-7.8)
- Détection auto « Sans objet » si aucune `Intervention.procedure_name == 'watering'` sur la campagne
- Saisie complémentaire matériels optimisants + démarche collective
- Tests

**Effort estimé** : 2 j-dev.

### PR6 — Verdict + export Excel Certibase

- `Hve::Scoring::AuditScorer.call` : orchestre les 4 scorers thématiques, calcule le verdict (4 × ≥ 10 + pas de CMR1)
- Job async `HveScoreRefreshJob` déclenché sur callbacks Intervention/Sale/Purchase (debounced via Sidekiq unique)
- Cell dashboard verdict (4 jauges + statut global + alerte CMR1)
- `Hve::Exports::ExcelGridExporter` :
  - Lib Ruby : **`rubyXL`** (décidé, préserve la structure xlsx du template)
  - Charge `db/templates/grille-audit-hvev4-v1.14 - vf.xlsx` vendoré
  - Itère sur un mapping `code_critere → (sheet, cell)` extrait de la grille (stocké dans `config/excel_grid_mapping.yml`)
  - Écrit les valeurs, sauvegarde, renvoie en download
- Idem pour la synthèse collective (`synthese-collectif-hvev4-v1.04 - vf.xlsx`)
- Tests : génère xlsx → ouvre via `roo` → compare 5-10 cellules clés

**Effort estimé** : 4 j-dev.

---

## 5. Risques et mitigations (mis à jour après PR2)

| Risque | Probabilité | Impact | Mitigation | Statut |
|---|---|---|---|---|
| Format Excel Certibase évolue annuellement | Élevée | Mapping cellules obsolète | Template versionné, rake regen | À traiter PR6 |
| Liste CMR à mettre à jour annuellement | Élevée | Faux positifs/négatifs CMR | Rake `hve:cmr:update YEAR=2026` + snapshots conservés | Cadre PR1 en place |
| `PfiCalculationJob` peut ne pas avoir tourné sur la campagne | Moyenne | 5.3 IFT indéterminé | Bouton « Relancer PFI » + tag « En attente » UI ; scorer renvoie `nil`, pas `0`, pour ne pas pénaliser | À traiter PR3 |
| Coefficients export azote depuis le PDF Comifer | Moyenne | Saisie manuelle | Extrait OCR + CSV vendoré, rake update annuel | À traiter PR4 (échantillon livré PR1) |
| Filière mixte (polyculture-élevage avec viti) | Élevée | Pondération du scoring | `FiliereDetector` calcule ratios SAU, scoring pondéré | À traiter PR3 |
| Grosses fermes : recalcul lent | Moyenne | UX dégradée | Job async + cache scores dans `HveAudit.score_*` ; recalcul incrémental | Cache PR2, async PR6 |
| Conflit avec `Inspection` (modèle similaire) | Faible | Confusion sémantique | Namespacer toutes les classes sous `Hve::` | Convention en place |
| Association `biodiversity_items` cachée en mémoire après mutation | — | Faux gate « closed » | Requête fresh dans le scorer | ✅ Corrigé PR2 |
| Apartment : controllers chargés sur `public` avant migration | — | `manage_restfully identifier:` requis si pas de `name`/`number`/`id` détecté | Passer `identifier: 'id'` explicitement | ✅ Documenté PR1 |
| Lexicon = source de vérité CMR | — | Auraient permis de retirer `HveCmrProduct` | **Écarté** : phrases de risque en texte FR libre, pas de codes H | ✅ Validé PR3 |

---

## 6. Données vendored à produire

| Fichier | Source | Format | Statut |
|---|---|---|---|
| `db/seeds/hve_cmr_products_2025_sample.csv` | Tab `Snapshot 2025` du XLSX ministère | CSV (amm, nom, cmr_class, withdrawal_date, status) | ✅ Échantillon ~20 lignes (PR1) ; extraction complète via `bin/import_cmr_products.rb` |
| `db/seeds/hve_nitrogen_exports.csv` | PDF Exportations_azote (Comifer 2013) | CSV (crop_ref, organe, ms_pct, n_kg_per_t) | ✅ Échantillon 21 lignes (PR1) ; extraction complète PR4 |
| `db/seeds/hve_scoring_tables.yml` | Tabs `Scoring_GC/Viticulture/Arboriculture` | YAML (filière → région → {pc, pf, ift_type}) | ✅ ~20 lignes (PR1) |
| `db/seeds/hve_iae_coefficients.yml` | Annexe 1 Plan V4.4 | YAML (famille × type × unité → coefficient) | ✅ 16 lignes (PR2) |
| `db/templates/grille-audit-hvev4-v1.14 - vf.xlsx` | Tel quel | xlsx binaire (438 KB) | À vendoriser PR6 |
| `db/templates/synthese-collectif-hvev4-v1.04 - vf.xlsx` | Tel quel | xlsx binaire (50 KB) | À vendoriser PR6 |
| `config/excel_grid_mapping.yml` | Extrait de la grille (cellules saisie / score) | YAML (code_critère → {sheet, value_cell, score_cell}) | À produire PR6 |
| `db/seeds/hve_animal_n_excretion.csv` | Arrêté 19/12/2011 | CSV (espèce, classe d'âge, kg N/an) | À vendoriser PR4 |

---

## 7. Tests

### État actuel (PR1 + PR2)

- **Modèles core** : 9 tests (HveAudit, HveAuditItem, HveCmrProduct, HveNitrogenExportCoefficient, HveScoringTable, HveIaeCoefficient, HveBiodiversityItem)
- **Services scoring** : 21 tests (8 scorers biodiv + 1 orchestrateur + 4 cas IaeScorer)
- **Total** : **34 tests, 53 assertions, 0 échec**

### À venir

- PR3 : ~35 tests (10 sous-scorers phyto + orchestrateur + PhytoInventory + cas CMR/IFT manquant)
- PR4 : ~25 tests (9 sous-scorers fert + NitrogenBalance::Computer + cas BGA/apparent)
- PR5 : ~12 tests (8 sous-scorers irrigation + détection « Sans objet »)
- PR6 : ~15 tests (orchestrateur global + Excel exporter sur 3 fixtures filière + verdict + idempotence)

**Estimation totale fin PR6** : ~120 tests scoring + ~15 tests intégration / contrôleur.

### Convention testing établie PR1-PR2

- Tests modèles dans `ekylibre/test/models/` (réutilise `test_helper` + fixtures Campaign/User)
- Tests services dans `ekylibre/test/services/hve/scoring/` (même raison)
- Pas de runner `rails test test/...` (charge toute la suite Ekylibre) → préférer `bundle exec ruby -Itest -e 'Dir[".../*.rb"].each {require ...}'` pour grouper les tests d'une PR
- Helpers de test : `def score_for(...)` plutôt que `def run(...)` (conflit Minitest)
- Fixtures campagne : `Campaign.find_or_create_by!(harvest_year: <year>)` plutôt que `campaigns(:current_campaign)` (la fixture symbolique n'est pas chargée par défaut)

---

## 8. Arbre de dépendances PRs

```
PR1 ✅ (skeleton + refs) ─┐
                          ├─► PR2 ✅ (biodiv)   ─┐
                          ├─► PR3 (phyto)        ─┤
                          ├─► PR4 (fert)         ─┼─► PR6 (verdict + export Certibase)
                          └─► PR5 (irrigation)   ─┘
```

PR2-3-4-5 sont **parallélisables** une fois PR1 mergée. En solo, on enchaîne PR3 → PR4 → PR5 (~11 j-dev), puis PR6 (4 j-dev).

---

## 9. Critères d'acceptation globaux

| # | Critère | Statut |
|---|---|---|
| 1 | Le plugin se charge via `Gemfile.local` sans modification du core | ⚠️ Partiel : routes + modèles sont dans le core par contrainte Apartment/manage_restfully |
| 2 | Sur un tenant avec activités GC + élevage + viti, le calcul auto produit des scores cohérents pour ≥ 50 % des items | À évaluer PR3-5 |
| 3 | Le verdict reproduit l'arithmétique de la grille officielle sur 3 jeux de données de test | À traiter PR6 |
| 4 | L'export xlsx généré est binaire-compatible Certibase (mêmes cellules de score que le template) | À traiter PR6 |
| 5 | La détection CMR1 sans dérogation déclenche l'alerte UI rouge ET force le verdict à `cmr1_blocked` | À traiter PR3 (déjà câblé dans le modèle PR1) |
| 6 | Le rejeu des scorers est idempotent | ✅ Vérifié PR2 |
| 7 | Performance : 1 000 interventions / campagne → score en < 30 s | À évaluer fin PR3 |

---

## 10. Démarrage immédiat (PR3)

PR1 et PR2 sont **livrées et vérifiées**. La prochaine étape concrète :

1. Valider les 5 décisions ouvertes du `workflow_hve_pr3_phytosanitary.md` §12 (fallback IFT à `nil`, détection biocontrôle via `segment_code='S2'`, dérogation par audit, relaunch PFI direct, pondération filière par SAU).
2. Lancer `/sc:implement claudedocs/workflow_hve_pr3_phytosanitary.md`.

---

## 11. Décisions architecturales tranchées au fil des PRs

| Décision | Tranchée en | Choix | Raison |
|---|---|---|---|
| Stockage référence CMR (lexicon vs tenant) | PR1 | Tenant (`HveCmrProduct`) | Mise à jour annuelle, snapshots, lexicon n'a pas les codes H |
| Bibliothèque Excel pour export Certibase | PR1 (plan) | `rubyXL` | Préserve la structure xlsx du template ministère |
| Saisie IAE : modèle dédié vs JSON dans metadata | PR2 | Modèle dédié `HveBiodiversityItem` | Requêtage, historique, clone inter-audits |
| Migrations + modèles : core ou plugin | PR1 (corrigé en cours) | **Core** | Apartment migration, manage_restfully autoload au boot |
| Services scoring : core ou plugin | PR2 | **Plugin** | Logique propre au plugin, autoload via engine |
| Tests : core ou plugin | PR2 | **Core** (test_helper + fixtures) | Réutilisation du Rails environnement |
| Prairie permanente : détection | PR2 | `Activity.cultivation_variety ∈ {grass, pasture, meadow}` | Pas de migration core nécessaire |
| Ruches (4.6), races menacées (4.7), qualité sol (4.8) | PR2 | Saisie manuelle dans `HveAuditItem.value_manual` | Pas de modèle Equipment « ruche » dans Onoma actuel |
| Recompute automatique sur callbacks | PR2 (différé) | **À PR6** | Évite d'éparpiller des modifs dans le core |
| Clone audit précédent | PR2 | Inclus dans le controller | Gros gain UX, ~30 lignes |
| `manage_restfully` sans `name`/`number` | PR1 | `identifier: 'id'` explicite | Auto-détection échoue avec colonne `id` seule |
| Conservation `HveCmrProduct` après investigation lexicon | PR3 (plan) | **Maintenue** | Lexicon stocke des phrases en texte libre, pas de codes H standardisés |
| IFT (item 5.3) : recalcul ou réutilisation | PR3 (plan) | **Réutilise** `PfiInterventionParameter` | Déjà calculé par `PfiCalculationJob` (API ministère) |
| Items « Sans objet » | PR3 (plan) | Renvoient `{skip: true}` dans evidence, ne pénalisent pas | Conforme au Plan V4.4 |
