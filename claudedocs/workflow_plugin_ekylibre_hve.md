# Workflow — Plugin `ekylibre-hve` (HVE3 v4.4)

**Demande** : construire un plugin Ekylibre dédié à l'audit HVE3 (Haute Valeur Environnementale), pré-rempli depuis les données existantes du tenant, permettant la saisie complémentaire, le calcul des 4 scores et l'export au format Excel exigé par Certibase.

**Stratégie** : Systematic. Plugin Rails Engine séparé hébergé dans `/home/djoulin/projects/ekylibre-plugins/ekylibre-hve`, livré en **6 PRs successives** (le périmètre fonctionnel est trop large pour une PR unique).

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

**Transmission** (note 2025-06-10) : depuis le 28/05/2025, Certibase reçoit les grilles xlsx via les organismes certificateurs. **Pas d'API publique** — le format de transport est le fichier xlsx ministériel, non modifié structurellement (les tabs et cellules doivent rester intacts).

---

## 2. Inventaire Ekylibre — ce qu'on a / ce qu'il faut produire

### Déjà disponible (à consommer)

| Besoin HVE | Source Ekylibre | Fichier |
|---|---|---|
| Phyto interventions (date, produit, dose, surface) | `Intervention` (procedure_name in `SPRAYING_PROCEDURE_NAMES`) | `app/models/intervention.rb:72-74,1177` |
| AMM, substances actives | `RegisteredPhytosanitaryProduct` (lexicon) | `app/models/lexicon/registered_phytosanitary_product.rb` |
| Mentions de danger (SGH08 ≈ CMR partiel) | `RegisteredPhytosanitaryRisk` | `app/models/lexicon/registered_phytosanitary_risk.rb:35-44` |
| IFT/PFI calculé | `PfiCalculationJob` (async, via API externe) | `app/jobs/pfi_calculation_job.rb` |
| SAU, assolement, productions | `Activity`, `ActivityProduction.support_shape_area` | `app/models/activity.rb`, `activity_production.rb` |
| Filière (vine_farming/plant_farming/livestock/…) | `Activity#family` (predicates auto-générés) | `app/models/activity.rb:79` |
| Animaux & effectifs | `Animal < Bioproduct`, `AnimalGroup` | `app/models/animal.rb` |
| Plan de fumure partiel | `ManureManagementPlan` + zones | `app/models/manure_management_plan.rb` |
| Génération PDF | `DocumentTemplate` (ODT/Reporting) | `app/models/document_template.rb` |
| Dashboard cells (beehive) | `backend.html.haml` + `ChartsHelper` (post-migration ECharts) | infrastructure récente |

### Absent → à introduire dans le plugin

- **IAE** (Infrastructures Agro-Écologiques) : haies, bandes enherbées, arbres isolés, mares, prairies permanentes — aucun modèle. Critère **obligatoire** (4.1) → bloquant pour la certif.
- **Mapping CMR officiel HVE** : la liste `HVE_Liste des PPP classés CMR_au_21.10.25.vf_.xlsx` (~2 300 produits par snapshot, clé = AMM) — `RegisteredPhytosanitaryRisk` ne couvre **pas** ce mapping CMR1/CMR2 spécifique à HVE.
- **Coefficients d'export azote par culture × organe** (`Exportations_azote_productions_vegetales_5.pdf`, source Comifer 2013). Pas dans Onoma ni le lexicon.
- **Tables de scoring IFT régionales** (Pf/Pc par bassin/région) — vendored depuis la grille Excel HVE.
- **Container d'audit versionné** : aucun équivalent réutilisable. `Inspection` est trop spécifique (un seul objet de mesure).
- **Variétés/races menacées** (Arrêté 29/04/2015) : référentiel à vendrer.
- **Outils annexes** : matériels optimisants (annexe 6/7), OAD (PPF/ODP/OPI), abonnement BSV — modèles `Subscription` simples à créer.

---

## 3. Architecture proposée

### 3.1 Squelette plugin (modèle des autres plugins Ekylibre)

```
ekylibre-plugins/ekylibre-hve/
├── ekylibre_hve.gemspec
├── lib/
│   ├── ekylibre_hve.rb
│   └── ekylibre_hve/
│       ├── engine.rb              # Rails::Engine + init i18n/assets/navigation
│       ├── plugin.rb              # Ekylibre::Application.instance.plugins << ...
│       └── version.rb
├── app/
│   ├── controllers/backend/hve/
│   │   ├── audits_controller.rb
│   │   ├── audit_items_controller.rb
│   │   ├── biodiversity_items_controller.rb   # IAE
│   │   └── nitrogen_balances_controller.rb
│   ├── models/
│   │   ├── hve_audit.rb
│   │   ├── hve_audit_item.rb
│   │   ├── hve_biodiversity_item.rb           # IAE entry (type + length/area)
│   │   ├── hve_nitrogen_balance.rb            # BGA ou Bilan apparent
│   │   ├── hve_subscription.rb                # OAD/BSV/charte
│   │   ├── hve_cmr_product.rb                 # mapping AMM → CMR1/CMR2 (lookup)
│   │   ├── hve_nitrogen_export_coefficient.rb # crop × organe → kg N/t (lookup)
│   │   └── hve_scoring_table.rb               # Pf/Pc IFT par filière/région
│   ├── services/
│   │   ├── hve/
│   │   │   ├── scoring/biodiversity_scorer.rb
│   │   │   ├── scoring/phyto_scorer.rb
│   │   │   ├── scoring/fertilisation_scorer.rb
│   │   │   ├── scoring/irrigation_scorer.rb
│   │   │   ├── scoring/audit_scorer.rb        # orchestrateur 4 scorers + verdict
│   │   │   └── exports/excel_grid_exporter.rb # remplit la grille xlsx officielle
│   ├── views/backend/hve/
│   │   └── audits/{index,show,edit}.html.haml
│   ├── jobs/
│   │   └── hve_score_refresh_job.rb           # recalcule scores sur intervention/sale save
│   └── assets/javascripts/hve_dashboard.js.coffee
├── config/
│   ├── locales/{eng,fra}/hve.yml
│   ├── navigation.xml                          # menu « Certification HVE »
│   └── rights.yml                              # permissions
├── db/
│   ├── migrate/                                # tables HVE
│   └── seeds/
│       ├── cmr_products_2025.csv               # importé depuis le xlsx HVE
│       ├── nitrogen_exports.csv                # depuis le PDF Exportations_azote
│       └── scoring_tables.yml                  # tables IFT régionales
└── test/
    ├── fixtures/
    ├── models/
    ├── services/scoring/
    └── integration/
```

### 3.2 Modèles principaux

**`HveAudit`** — racine par campagne :
- `campaign_id`, `started_on`, `closed_on`, `status` (draft/submitted/certified/refused)
- `referentiel_version` (ex. « V4.4 »), `filiere` (auto-déduite des activities)
- `score_biodiversity`, `score_phytosanitary`, `score_fertilisation`, `score_irrigation` (caches)
- `verdict` (calculé) : `compliant?` = tous ≥ 10 ET `!uses_cmr1_without_derogation`
- `metadata_jsonb` : trace des inputs manuels, dérogations, justifications

**`HveAuditItem`** — un par critère HVE3 (35 lignes par audit) :
- `audit_id`, `code` (ex. `'4.1'`, `'5.3.herbicide'`), `theme` (biodiv/phyto/…)
- `value_raw` (input agrégé, ex. % SAU IAE), `value_manual` (override utilisateur), `value_used`
- `points`, `points_max`, `auto_computed` (bool)
- `evidence_jsonb` (interventions/parcels qui ont contribué, pour justification audit)
- `notes` (texte libre du saisisseur)

**`HveBiodiversityItem`** — un par élément IAE (haies, prairies permanentes, etc.) :
- `audit_id`, `iae_family` (aquatique/herbager/ligneux/rocheux), `iae_type` (haie/mare/…)
- `surface_or_length`, `coefficient` (depuis lexicon HVE), `equivalent_iae_ha`

**`HveNitrogenBalance`** — BGA ou Bilan apparent par audit :
- `audit_id`, `method` (`bga` / `apparent`)
- `e1_organic_produced`, `e2_organic_imported`, `e3_mineral`, etc. (un attribut par poste)
- `total_inputs`, `total_outputs`, `balance_per_ha`
- Sources tracées : import depuis Intervention/Purchase/Sale via service dédié

**Tables lexicon (seed only, jamais modifiées au runtime — schéma `lexicon` partagé)** :

Décision : éviter le schéma `lexicon` partagé (cf. CLAUDE.md, c'est sensible). Préférer un seed dans le **schéma tenant**, rechargeable via rake `hve:reference:load`. Tables :
- `hve_cmr_products(amm_code, product_name, cmr_class, withdrawal_date, snapshot_year)`
- `hve_nitrogen_export_coefficients(crop_onoma, organ, ms_pct, n_kg_per_t)`
- `hve_scoring_tables(filiere, region/bassin, pc_value, pf_value, ift_type)`

### 3.3 Services & calcul

Pattern : un scorer par thème, orchestré par `AuditScorer.call(audit:)`. Chaque scorer expose `compute_item(code, audit)` → renvoie `{ value, points, evidence }`. Le scorer écrit dans les `HveAuditItem` correspondants.

Idempotent : peut être rejoué après chaque modification d'intervention/saisie. Déclenché par :
- `HveScoreRefreshJob` (async, debounced) déclenché par callback sur Intervention/Sale/Purchase save quand un audit `draft` existe pour la campagne courante.
- Bouton « Recalculer » manuel sur la vue audit.

### 3.4 UI

**Navigation** : section « Certification HVE » sous le menu principal.

**Vue index** : liste des audits (un par campagne), badge statut, score-résumé.

**Vue show** : dashboard à la « beehive », 1 cell par thème :
- Cell « Biodiversité » : jauge 0-36 + détail des 8 items (auto + manual), bouton « éditer IAE »
- Cell « Phyto » : jauge + 10 items + **alerte rouge si CMR1 détecté**
- Cell « Fertilisation » : jauge + 9 items + bouton « éditer bilan azote »
- Cell « Irrigation » : jauge + 8 items (ou « Sans objet » si non-irrigant)
- Cell « Verdict » : compliant/non-compliant + 4 mini-jauges par seuil de 10

**Vue edit** : par thème, tableau d'items avec :
- valeur auto-calculée (read-only) + éventuel override manuel (avec justification)
- pour les items non auto-déductibles (OAD, surveillance, ruches), formulaire libre
- pour IAE : sous-écran dédié de saisie en grille (type / coeff / surface) avec calcul total temps réel

**Export** : bouton « Générer la grille xlsx Certibase ». Charge le template fourni (`grille-audit-hvev4-v1.14 - vf.xlsx`) vendoré dans le plugin, remplit les cellules jaunes/bleues mappées via `Hve::Exports::ExcelGridExporter`, le ressort dans le browser. **Le format de la grille reste celui du ministère** — c'est une exigence Certibase.

---

## 4. Phasage en PRs

Plan en 6 PRs, chacune mergeable indépendamment, pour limiter le risque et faire avancer la valeur.

### PR1 — Skeleton + données de référence (≈ 2 jours)

- Engine + gemspec + plugin registration (`Gemfile.local` pour dev local)
- Modèles `HveAudit`, `HveAuditItem` (CRUD basique, pas encore de scoring)
- Tables `hve_cmr_products`, `hve_nitrogen_export_coefficients`, `hve_scoring_tables` + seeds depuis les sources fournies (XLSX CMR, PDF azote, grille HVE)
- Rake `hve:reference:load` qui (re)charge les seeds dans le tenant courant
- Navigation `Certification HVE > Audits`
- Vue index + new + show (squelette, pas de scoring)
- Tests : présence des seeds (counts attendus : ~2 300 CMR, ~150 lignes azote), modèles instanciables

### PR2 — Biodiversité (≈ 3 jours)

- Modèle `HveBiodiversityItem` (CRUD IAE)
- `Hve::Scoring::BiodiversityScorer` couvrant 4.1 à 4.8 :
  - 4.1 IAE : auto depuis `HveBiodiversityItem` + gating obligatoire (manquant → 0 pts hard)
  - 4.2 Taille parcelles : auto depuis `LandParcel#shape.area`
  - 4.3 Poids culture principale : auto depuis `ActivityProduction.support_shape_area`
  - 4.4 Nb espèces végétales : auto depuis distinct `Activity.cultivation_variety`
  - 4.5-4.7 : manuel (animaux/ruches/variétés menacées) — saisie dans `HveAuditItem`
  - 4.8 Qualité bio sol : manuel
- Vue edit biodiversité (formulaire IAE + saisies manuelles)
- Tests : par item, calculs auto + cas de bordure (0 IAE, prairies > 75%, exemption < 10 ha)

### PR3 — Phyto (≈ 4 jours, le plus dense)

- `Hve::Scoring::PhytoScorer` couvrant 5.1 à 5.10 :
  - 5.1 CMR : itère interventions phyto, join sur `hve_cmr_products` via AMM. **Bloquant CMR1** sans dérogation manuelle.
  - 5.2 % surfaces non traitées : surfaces de `ActivityProduction` sans intervention phyto / SAU
  - 5.3 IFT herbicide / hors-herbicide : agrégation `PfiCalculationJob` outputs + scoring par filière contre `hve_scoring_tables`
  - 5.4-5.10 : selon filière, mix auto/manuel
- Détecteur de filière (GC/viti/arbo/horti) à partir de la composition des `Activity.family` du tenant
- Vue edit phyto + cell dashboard avec alerte CMR1 rouge
- Tests : un par item, cas typique « tenant viti avec une seule intervention CMR2 »

### PR4 — Fertilisation + outil bilan N (≈ 5 jours)

- Modèle `HveNitrogenBalance` (BGA ou Bilan apparent)
- Service `Hve::NitrogenBalance::Computer` : agrège
  - Effluents produits (depuis `Animal` + coefficients excrétion N annuelle par espèce — vendoré)
  - Effluents importés/exportés (via `Purchase`/`Sale` ou saisie manuelle)
  - Engrais minéraux (depuis interventions de fertilisation)
  - Exports cultures (depuis `Sale` × `hve_nitrogen_export_coefficients`)
- Service détecte automatiquement quel formulaire utiliser (élevage présent → BGA, sinon Bilan apparent)
- `Hve::Scoring::FertilisationScorer` (6.1-6.9), dont 6.1 lit `HveNitrogenBalance.balance_per_ha`
- Vue dédiée bilan N (page lourde — tableau structuré façon Excel original)

### PR5 — Irrigation (≈ 2 jours)

- `Hve::Scoring::IrrigationScorer` (7.1-7.8)
- Détection auto « Sans objet » si aucune `Intervention.procedure_name == 'watering'` sur la campagne
- Saisie complémentaire matériels optimisants + démarche collective
- Tests

### PR6 — Verdict + export Excel Certibase (≈ 4 jours)

- `Hve::Scoring::AuditScorer.call` : orchestre les 4 scorers, calcule le verdict (4 × ≥ 10 + pas de CMR1)
- Job async `HveScoreRefreshJob` déclenché sur Intervention/Sale/Purchase save (debounced via Sidekiq unique)
- Cell dashboard verdict (4 jauges + statut global + alerte CMR1)
- `Hve::Exports::ExcelGridExporter` :
  - Lib Ruby : `rubyXL` ou `roo-xls` (lecture) + `caxlsx` (écriture). À choisir en phase 1 ; mon penchant : `rubyXL` qui sait modifier un xlsx existant en préservant la structure.
  - Charge le template `db/templates/grille-audit-hvev4-v1.14 - vf.xlsx` vendoré
  - Itère sur un mapping `code_critere → (sheet, cell)` (le mapping est extrait de la grille en PR1, stocké dans `config/excel_grid_mapping.yml`)
  - Écrit les valeurs, sauvegarde, renvoie en download
- Mêmes étapes pour la synthèse collective (`synthese-collectif-hvev4-v1.04 - vf.xlsx`) — feuille `Synthese_coll_v1.04` (226 colonnes copy-pastables)
- Tests : génération xlsx → ouverture par `roo` → comparaison des valeurs attendues sur 4-5 cellules clés

---

## 5. Risques et mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Le format Excel Certibase évolue (annuel) | Élevée | Le mapping cellules devient obsolète, export refusé | Vendrer le template versionné (`v1.14`) ; rake task pour régénérer le mapping depuis une nouvelle grille ; ne pas hardcoder les coordonnées en Ruby |
| Mapping CMR (AMM → CMR1/CMR2) à mettre à jour annuellement | Élevée | Audit non valide ou faux positif | Rake `hve:cmr:update YEAR=2026` qui re-seede depuis le xlsx fourni par le ministère ; conserver les snapshots antérieurs (campagne 2024 vs 2025) |
| `PfiCalculationJob` dépend d'une API externe (PfiClientApi) | Moyenne | IFT non calculé → 5.3 indisponible | Service fallback qui calcule IFT à partir des interventions sans appel API ; mode dégradé clairement signalé dans l'UI |
| Coefficients d'export azote non publiés en données ouvertes | Moyenne | Saisie manuelle des `hve_nitrogen_export_coefficients` | Extraction OCR/manuelle depuis le PDF Comifer en PR1, stocké en CSV vendoré ; rake d'update annuel |
| Filière mixte (polyculture-élevage avec viti) | Moyenne | Scorings différents s'appliquent | Le scoring de chaque item s'applique sur la part de SAU concernée (pondération). Pré-calculer les ratios SAU par filière dans `HveAudit.metadata_jsonb` |
| Grosses fermes : recalcul des scores lent | Moyenne | UX dégradée sur dashboard | Job async + cache des scores dans `HveAudit.score_*` ; recalcul incrémental par item modifié, pas full audit |
| Conflit avec `Inspection` (modèle existant similaire) | Faible | Confusion sémantique | Documenter explicitement que `HveAudit` est distinct ; namespacer toutes les classes sous `Hve::` |
| Migration `RegisteredPhytosanitaryRisk` → ajout du flag CMR HVE | Faible | Évite la duplication | À écarter en PR1 : on garde la table `hve_cmr_products` distincte, plus simple à maintenir et alignée sur le snapshot annuel HVE |

---

## 6. Données vendored à produire (artefacts livrés avec le plugin)

| Fichier | Source | Format | Taille estimée |
|---|---|---|---|
| `db/seeds/hve_cmr_products_2025.csv` | Tab `Snapshot 2025` du XLSX HVE CMR | CSV (amm, nom, cmr_class, withdrawal_date, status) | ~2 300 lignes |
| `db/seeds/hve_nitrogen_exports.csv` | PDF Exportations_azote (6 tableaux) | CSV (crop_ref Onoma, organe, ms_pct, n_kg_per_t) | ~150 lignes |
| `db/seeds/hve_scoring_tables.yml` | Tabs `Scoring_GC/Viticulture/Arboriculture` de la grille | YAML (filière → région → {pc, pf, ift_type}) | ~50 entries |
| `db/templates/grille-audit-hvev4-v1.14 - vf.xlsx` | Tel quel | xlsx binaire | 438 KB |
| `db/templates/synthese-collectif-hvev4-v1.04 - vf.xlsx` | Tel quel | xlsx binaire | 50 KB |
| `config/excel_grid_mapping.yml` | Extrait de la grille (cellules de saisie / cellules de score) | YAML (code_critere → {sheet, value_cell, score_cell}) | ~80 entries |
| `db/seeds/hve_animal_n_excretion.csv` | Arrêté 19/12/2011 | CSV (espèce, classe d'âge, kg N/an) | ~30 lignes |

---

## 7. Tests

- **Modèles** : couverture standard (validations, scopes).
- **Services scoring** : un test par item HVE (35 items) avec fixtures couvrant les cas typiques + bornes. Total ~60 tests scoring.
- **Service bilan N** : 5-10 tests sur cas type (élevage seul, GC seul, polyculture-élevage).
- **Excel exporter** : génère un xlsx en test, ré-ouvre via `roo`, vérifie 5-10 cellules clés. Pas de comparaison binaire (le format Excel a des variations).
- **Integration** : un test système qui crée un audit minimal sur un tenant fixture, calcule, exporte. Bloque tout régression majeure.

---

## 8. Arbre de dépendances PRs

```
PR1 (skeleton + refs) ─┐
                       ├─► PR2 (biodiv)   ─┐
                       ├─► PR3 (phyto)    ─┤
                       ├─► PR4 (fert)     ─┼─► PR6 (verdict + export Certibase)
                       └─► PR5 (irrigation)┘
```

PR2-3-4-5 sont **parallélisables** une fois PR1 mergée (équipe de 2-3 devs sur quelques semaines, sinon ~6 semaines en séquentiel solo).

---

## 9. Critères d'acceptation globaux

1. ✅ Le plugin se charge via `Gemfile.local` sans modification du core.
2. ✅ Sur un tenant avec activités GC + élevage + viti, le calcul auto produit des scores cohérents pour ≥ 50 % des items (le reste nécessite saisie manuelle).
3. ✅ Le verdict reproduit l'arithmétique de la grille officielle sur 3 jeux de données de test (un par filière dominante).
4. ✅ L'export xlsx généré s'ouvre dans Excel/LibreOffice sans avertissement de corruption, et les cellules de score remplies sont identiques à celles que produit la grille officielle quand on saisit les mêmes valeurs.
5. ✅ La détection CMR1 sans dérogation déclenche l'alerte UI rouge **et** force le verdict global à « non conforme ».
6. ✅ Le rejeu de `HveScoreRefreshJob` est idempotent (recalcul = mêmes scores à fixtures identiques).
7. ✅ Performance : un tenant avec 1 000 interventions sur la campagne calcule le score en < 30 s.

---

## 10. Démarrage immédiat (PR1)

Pour amorcer sans attendre la planification complète :

1. Créer `/home/djoulin/projects/ekylibre-plugins/ekylibre-hve/` avec le squelette plugin (copier la structure de `ekylibre-idea` ou `ekylibre-viti`).
2. Ajouter le mount dans `Gemfile.local` du repo principal (path local).
3. Créer les migrations pour `hve_audits`, `hve_audit_items`, `hve_cmr_products`, `hve_nitrogen_export_coefficients`.
4. Extraire les seeds depuis les XLSX/PDF fournis (script Ruby + `rubyXL` ou `roo` pour le XLSX CMR).
5. Vue index + new + show squelette (pas encore de scoring).
6. Tests minimaux : seeds chargés (counts attendus), modèles instanciables.

**Effort estimé total** : ~20 jours-développeur sur 6 PRs. PR1 livrable en 2 jours.

---

## 11. Prochaine étape

Lancer `/sc:implement claudedocs/workflow_plugin_ekylibre_hve.md` pour démarrer **uniquement PR1** (les autres PRs requièrent leur propre exécution `/sc:implement` après merge de la précédente, pour limiter la taille du diff). 

Avant de coder, valider les choix architecturaux ouverts :
- **Stockage référence CMR** : table tenant vs lexicon partagé → recommandé tenant (cf. risque mise à jour annuelle).
- **Bibliothèque Excel** : `rubyXL` (modification de templates) vs `caxlsx` (génération from-scratch) → recommandé `rubyXL` pour préserver la structure officielle.
- **Saisie IAE** : modèle propre `HveBiodiversityItem` vs JSON dans `HveAudit.metadata_jsonb` → recommandé modèle propre pour requêtage et historique inter-audits.
- **Périmètre PR1 stricte** : ne pas glisser de logique de scoring dans PR1, sinon elle dépasse 2 jours.
