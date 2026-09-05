# Workflow — PR3 plugin `ekylibre-hve` : scoring Phytosanitaire

**Demande** : implémenter le thème **Phytosanitaire** (10 items 5.1-5.10, max 63 pts, seuil ≥ 10) du HVE3 V4.4. Contrainte forte du user : **réutiliser au maximum les données déjà présentes** dans le lexicon Ekylibre et dans les interventions, sans réinventer.

**Stratégie** : Systematic. Aucune nouvelle table de référence — tout ce qui peut s'extraire du lexicon ou des interventions est exploité directement. Le seul référentiel tenant nécessaire reste `HveCmrProduct` (déjà créé en PR1, justifié dans la section 6).

---

## 1. État de l'art Ekylibre — ce qu'on consomme tel quel

### Lexicon (déjà chargé, schéma partagé read-only)

| Modèle | Champs utiles pour HVE | Limite |
|---|---|---|
| `RegisteredPhytosanitaryProduct` | `france_maaid` (AMM), `active_compounds` (text[]), `natures` (text[] — Herbicide/Fongicide/Insecticide/…), `state` (authorized/withdrawn), `product_type` (ADJUVANT/PPP/PCP/PRODUIT-MIXTE), `allowed_mentions` (jsonb, dont organic_usage), `in_field_reentry_delay`, `started_on`/`stopped_on` | Pas de classification CMR (cf. §6) |
| `RegisteredPhytosanitaryRisk` | `risk_code` (R10, SGH01-09), `risk_phrase` (texte FR) | **Pas les codes H** (H340, H351, H360…) — texte libre non-indexable |
| `RegisteredPhytosanitaryUsage` | `dose_quantity`, `dose_unit`, `pre_harvest_delay`, `untreated_buffer_aquatic` (5/20/30/50/100 m), `applications_count`, `target_name_label_fra`, `state` | — |
| `RegisteredPhytosanitaryTargetNameToPfiTarget` | `ephy_name` → `pfi_id`, `pfi_name`, `default_pfi_treatment_type_id` | Mapping EPHY → PFI |

### Modèles tenant (déjà migrés, données saisies par l'utilisateur)

| Modèle | Constantes/champs | Source / référence |
|---|---|---|
| `Intervention` | `PHYTO_PROCEDURE_NAMES` (11 entrées) ligne 72, `SPRAYING_PROCEDURE_NAMES` (4) ligne 74, `#using_phytosanitary?` ligne 1177, scope `of_campaign(campaign)` ligne 211, scope `of_nature_using_phytosanitary` ligne 200 | `app/models/intervention.rb` |
| `InterventionInput` (STI sur `InterventionProductParameter`) | `product_id`, `quantity_value`, `quantity_unit_name`, `usage_id` (ref `RegisteredPhytosanitaryUsage`), `spray_volume_value`, `working_zone_area_value` (ha), `reference_data` (jsonb) | `app/models/intervention_input.rb` |
| `InterventionTarget` | `product_id` (Product cible — souvent un LandParcel ou un Plant), `working_zone_area_value` (ha), `working_zone` (PostGIS), `#working_area` ligne 183 | `app/models/intervention_target.rb` |
| **`PfiInterventionParameter`** ⭐ | `campaign_id`, `input_id`, `target_id`, `nature` (intervention/crop), `pfi_value` (decimal — **l'IFT calculé**), `segment_code` (S2=Biocontrôle, S3=Herbicide, S4=Insecticide, S5=Fongicide, S6=Autres), `response` (jsonb), `signature` | `app/models/pfi_intervention_parameter.rb` |
| `PfiCalculationJob` | Calcule via l'API ministère agriculture.gouv.fr et stocke dans `PfiInterventionParameter` | `app/jobs/pfi_calculation_job.rb` |

### En clair pour le scoring

- **L'IFT est déjà calculé et stocké** : aucune ré-implémentation. Je lis et agrège.
- **Le segment phyto est déjà classifié** par l'API ministère (S2=biocontrôle, S3=herbicide, etc.) — exactement les distinctions dont HVE 5.3 a besoin.
- **Les surfaces non traitées** se calculent par anti-jointure entre `ActivityProduction.support` et `InterventionTarget.product` sans nouveau modèle.

---

## 2. Détail des 10 items à scorer (Plan V4.4 §5.1-5.10)

### 5.1 — CMR — **KILL-SWITCH + 0-2 pts**

**Référentiel** : `HveCmrProduct` (table tenant créée en PR1, seedée annuellement depuis le XLSX ministère).

**Calcul** :
- Pour chaque `Intervention` de la campagne where `using_phytosanitary?` :
  - Pour chaque `input` : récupérer `input.product.phytosanitary_product.france_maaid` (AMM)
  - Lookup `HveCmrProduct.classify(amm, year: campaign.harvest_year)` → `'CMR1' | 'CMR2' | nil`
- **CMR1 détecté** → consulter `HveAuditItem(code='5.1.derogation').value_manual` :
  - Si dérogation saisie OUI → `points = 2` (utilisation autorisée), trace l'evidence
  - Sinon → set `audit.uses_cmr1_without_derogation = true` + `points = 0` + **kill-switch global** (le verdict de l'audit devient `cmr1_blocked` dès qu'on rejoue `audit.recompute_verdict`)
- **CMR2 herbicide** (lookup `RegisteredPhytosanitaryProduct.natures` contient `'Herbicide'`) → tableau Phyto rows 11-25 du Plan
- **Aucun CMR** → `points = 2`

**Pas de nouveau modèle** : on réutilise `HveCmrProduct` (PR1) + `RegisteredPhytosanitaryProduct.natures` (lexicon).

### 5.2 — Surfaces non traitées (% SAU) — **0-10 pts**

**Calcul** : ratio SAU jamais touchée par une `Intervention` phyto sur la campagne.

```ruby
treated_supports = Intervention
                   .of_campaign(campaign)
                   .of_nature_using_phytosanitary
                   .joins(:targets)
                   .pluck('intervention_targets.product_id')
                   .uniq

apd_all = ActivityProduction.of_campaign(campaign).to_a
apd_treated = apd_all.select { |a| treated_supports.include?(a.support_id) }
sau_total = apd_all.sum { |a| ha_of(a) }
sau_non_treated = (apd_all - apd_treated).sum { |a| ha_of(a) }
share = (sau_non_treated / sau_total * 100).round(2)
```

Mapping linéaire 5 % → 1 pt … 95 % → 10 pts (table dans le Plan).

**Cas de bord** : une target qui pointe sur un `Plant` (et non sur le support directement) doit être traversée. Le service détecte ça via `target.product.is_a?(Plant)` et remonte à `plant.activity_production.support`.

### 5.3 — IFT herbicides + IFT hors-herbicides — **0-10 pts (5+5)**

🎉 **Reuse intégral du calcul existant** :

```ruby
records = PfiInterventionParameter
            .where(campaign_id: campaign.id)
            .where.not(segment_code: 'S2')   # exclut biocontrôle
            .where(nature: 'crop')           # un row par (input × target)

ift_herbicide      = aggregate(records.where(segment_code: 'S3'))
ift_hors_herbicide = aggregate(records.where(segment_code: ['S4', 'S5', 'S6']))
```

**Agrégation** : ECharts / Plan V4.4 demande l'IFT moyen pondéré par la surface traitée. Le `pfi_value` stocké par `PfiComputation` est déjà l'IFT par traitement (input × target) ramené à 100 %. Sommer + diviser par SAU concernée.

**Scoring** : table régionale `HveScoringTable` (déjà créée + seedée PR1). Détecter la filière (GC/Viti/Arbo) via la composition des `Activity.family` du tenant (cache dans `audit.metadata`).

**Risque** : tenant sans `PfiInterventionParameter` (API down, jamais lancée) → IFT indéterminé. Mitigation : bouton « Relancer le calcul PFI sur la campagne » qui invoque `PfiCalculationJob` avec tous les `intervention.id` de la campagne, et affiche un état « En attente du calcul IFT » côté UI tant qu'il manque des rows.

### 5.4 — Quantité SA appliquée (horticulture / pépinière uniquement) — **0-5 pts**

**Calcul** : somme des `input.quantity_value * substance_content` agrégée par hectare horticole. Hors filière, **« Sans objet »**.

Détection : si aucune `Activity.family` n'est de type horticole / pépinière (Onoma `horticulture` ?), score = N/A et le scorer renvoie `{ skip: true }` qui marque l'item « Sans objet » dans `HveAuditItem.evidence`.

### 5.5 — Surveillance phytosanitaire — **0-3 pts**

Manuel. 3 items distincts (1 pt chacun, cumulables, cap 3) :
- `5.5.diagnostic_tool` : abonnement outil OAD (booléen)
- `5.5.collective_scouting` : participation prospection collective
- `5.5.bsv_subscription` : abonnement BSV

→ Saisie dans `HveAuditItem.value_manual` (3 items distincts), le scorer somme.

### 5.6 — Méthodes alternatives — **0-6 pts**

Partiellement auto-détectable via `Intervention.procedure_name` :
- Désherbage mécanique (`chemical_mechanical_weeding` partiel, ou `mechanical_weeding` si pur)
- Biocontrôle = intervention phyto dont segment_code == 'S2' (déjà classifié par l'API)
- Le reste (lâchers auxiliaires, méthodes prophylactiques) : manuel

Le scorer compte les méthodes effectivement utilisées + les saisies manuelles. Cap 6.

### 5.7 — Conditions d'application — matériels annexe 7 — **0-2 pts**

Manuel. L'utilisateur déclare possède X matériels limitant la dérive (buses, panneaux récupérateurs, etc.).

### 5.8 — Diversité spécifique / variétale — **0-6 pts**

Cultures pérennes (viti/arbo) ou hors-sol uniquement. **Partage du calcul biodiversité 4.4** (compte d'espèces végétales) avec un cap adapté.

### 5.9 — Couvert inter-rang viti/arbo/horti — **0-9 pts**

Manuel + détection partielle : pour chaque `ActivityProduction` perenne, vérifier l'existence d'une `Intervention` `sowing` sur un couvert inter-rang dans la campagne. Pondéré par surface concernée.

### 5.10 — Recyclage eaux d'irrigation cultures hors sol — **0-10 pts**

Manuel. Filière hors-sol uniquement, sinon « Sans objet ».

---

## 3. Architecture (pas de nouveau modèle)

### Services à introduire (plugin)

```
ekylibre-hve/app/services/hve/scoring/
├── phyto_scorer.rb                       # orchestrateur 10 items
├── phyto/
│   ├── cmr_scorer.rb                     # 5.1 — kill-switch + dérogation
│   ├── untreated_surface_scorer.rb       # 5.2 — % SAU non traitée
│   ├── ift_scorer.rb                     # 5.3 — agrège PfiInterventionParameter
│   ├── sa_quantity_scorer.rb             # 5.4 — horti only
│   ├── surveillance_scorer.rb            # 5.5 — 3 manuels
│   ├── alternative_methods_scorer.rb     # 5.6 — auto+manuel
│   ├── application_conditions_scorer.rb  # 5.7 — manuel
│   ├── species_diversity_scorer.rb       # 5.8 — réutilise SauCalculator
│   ├── inter_row_cover_scorer.rb         # 5.9 — partiel auto
│   └── recycling_scorer.rb               # 5.10 — manuel
└── shared/
    ├── phyto_inventory.rb                # cache des interventions phyto de la campagne
    └── filiere_detector.rb               # GC/Viti/Arbo/Horti détection (réutilisable PR4-5)
```

### Pas de migration. Pas de nouveau modèle.

Tout est lecture seule sur :
- `Intervention`, `InterventionInput`, `InterventionTarget`
- `Product` → `RegisteredPhytosanitaryProduct` (lexicon)
- `PfiInterventionParameter`
- `HveCmrProduct` (PR1, table tenant)
- `HveScoringTable` (PR1, table tenant)

### Module clé : `Hve::Scoring::Shared::PhytoInventory`

```ruby
class Hve::Scoring::Shared::PhytoInventory
  def initialize(audit)
    @audit = audit
    @campaign = audit.campaign
  end

  def phyto_interventions          # cache liste des Intervention phyto
  def phyto_inputs                 # cache flat (Intervention × Input)
  def cmr1_inputs                  # inputs dont AMM est CMR1
  def cmr2_herbicide_inputs        # inputs CMR2 dont nature inclut Herbicide
  def treated_supports             # set d'IDs supports touchés
  def pfi_records                  # PfiInterventionParameter de la campagne
  def biocontrol_inputs            # inputs whose PFI record has segment 'S2'
  def has_pfi_data?                # true ssi tous les inputs ont un PFI record
end
```

Mémoïse tout, partagé entre les 10 scorers (sinon 10 × N requêtes).

---

## 4. UI

Nouvelle vue dédiée `/backend/hve_audits/:id/phytosanitary` (action custom du contrôleur).

- **Block alerte CMR** en tête : si CMR1 détecté, encadré rouge avec :
  - Liste des interventions concernées (date, produit, AMM, surface)
  - Champ booléen « Dérogation officielle obtenue ? » avec justificatif texte
  - Bouton « Confirmer la dérogation »
- **Bloc IFT** : visualisation (`spline_highcharts` migré ECharts) IFT herbicide et hors-herbicide vs. Pc/Pf régionaux. État « En attente du calcul » si `phyto_inventory.has_pfi_data?` est false.
- **Bloc surfaces non traitées** : compteur % + carte (optionnelle) des supports non traités.
- **Bloc surveillance** : 3 checkboxes (5.5.diagnostic_tool / 5.5.collective_scouting / 5.5.bsv_subscription).
- **Bloc méthodes alternatives** : liste auto-détectée + champ d'ajout manuel.
- **Boutons** :
  - « Recalculer le score phyto »
  - « Relancer le calcul PFI » (invoque `PfiCalculationJob.perform_later(campaign_id, intervention_ids, current_user)`)

Lien depuis la cell Phytosanitaire de `hve_audits/show.html.haml`.

---

## 5. Risques et mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| `PfiInterventionParameter` vide (API down, jamais déclenchée) | **Élevée** sur ferme nouvellement onboardée | IFT non disponible → 5.3 indéfini | Bouton « Relancer PFI » ; tag visuel « En attente » ; le scorer renvoie `points: nil` au lieu de 0 pour ne pas pénaliser à tort |
| Dérogation CMR1 saisie après le verdict | Moyenne | Verdict figé en `cmr1_blocked` à tort | À chaque save de `HveAuditItem(code='5.1.derogation')`, déclencher `audit.recompute_verdict` |
| Filière mixte (polyculture-viti) | Élevée | Items 5.4, 5.8, 5.9, 5.10 partiellement applicables | `FiliereDetector` calcule les ratios SAU par filière et le scoring de chaque item est pondéré |
| `InterventionTarget` qui pointe sur un `Plant` plutôt que sur le support de l'`ActivityProduction` | Moyenne | Faux négatif sur 5.2 | Service `Shared::Phyto::TargetResolver` traverse Plant → activity_production → support |
| Performance : 5.1 scan tous les inputs phyto (peut être 1000+ sur une grosse ferme) | Moyenne | Lent | `PhytoInventory` charge en bulk avec `includes(:product → :phytosanitary_product → :risks)` |
| `RegisteredPhytosanitaryProduct.france_maaid` absent (produit récent ou retiré) | Faible | CMR non détecté | Logger un warning + ajouter l'AMM dans evidence pour audit humain |
| `HveCmrProduct` snapshot pas à jour | Moyenne | Faux positifs / négatifs CMR | Bandeau UI montrant la date du dernier `hve:reference:load` et l'année snapshot active |
| Tenant viti sans `HveScoringTable` pour son bassin | Moyenne | 5.3 sans seuil | Fallback sur la table « toutes régions » ou alerte UI invitant à enrichir le seed |
| Le segment_code 'S2' (biocontrôle) n'est garanti que si l'API a répondu | Moyenne | Filtrage 5.1 / 5.6 fragile sans PFI | Detection secondaire via `RegisteredPhytosanitaryProduct.natures` ne contenant que des codes biocontrôle reconnus (à valider) |

---

## 6. Décision : maintenir `HveCmrProduct` malgré le lexicon ?

**OUI**. L'investigation confirme que :
- `RegisteredPhytosanitaryRisk.risk_phrase` stocke du **texte FR libre**, pas les codes H standardisés (H340, H351, H360…) → **impossible** d'en déduire la classification CMR par requête SQL.
- Le modèle `RegisteredPhytosanitaryPhrase` est référencé en association mais **n'a pas de table** (gap connu du lexicon).
- La liste ministère porte aussi la **date de retrait** et le **statut** par snapshot annuel — info que le lexicon ne maintient pas.

Conséquence : le snapshot annuel `hve_cmr_products` reste indispensable, géré par le rake `hve:reference:load` (déjà en place).

---

## 7. Tests

### Models : aucun (pas de nouveau modèle).

### Services (dans le core, comme PR2) :

- `test/services/hve/scoring/phyto/cmr_scorer_test.rb` : 5 cas (aucun phyto, CMR1 sans dérog, CMR1 avec dérog, CMR2 herb, mix)
- `test/services/hve/scoring/phyto/untreated_surface_scorer_test.rb` : 3 cas (100 % non traité, 50/50, 0 %)
- `test/services/hve/scoring/phyto/ift_scorer_test.rb` : 4 cas (PFI complet, PFI manquant, sous Pc, au-delà Pf)
- 1 test par scorer manuel/auto restant (5.4-5.10) : ≈ 12 tests
- `test/services/hve/scoring/shared/phyto_inventory_test.rb` : 6 tests
- `test/services/hve/scoring/phyto_scorer_test.rb` : orchestrateur intégration + idempotence + kill-switch (4 tests)

Total estimé : ~35 tests / ~60 assertions.

### Controller : 3 tests (action phyto rendue, recompute, dérogation toggle).

---

## 8. Arbre de dépendances

```
1. PhytoInventory + FiliereDetector ─┐
2. CmrScorer (5.1, kill-switch)      ├─► 6. UI saisie + alerte CMR
3. UntreatedSurfaceScorer (5.2)      │
4. IftScorer (5.3, lit PfiIP)        ├─► 5. PhytoScorer orchestrateur ─► 7. Tests intégration
5. Scorers manuels (5.5, 5.7, 5.10) ─┤
6. Scorers semi-auto (5.4, 5.6,      │
   5.8, 5.9)                         ┘
```

Étapes 1-2-3-4 parallélisables. Tout converge sur l'orchestrateur, puis l'UI.

---

## 9. Critères d'acceptation

1. ✅ Aucune nouvelle table de référence créée ; toutes les données lues depuis le lexicon, les interventions, ou les tables HVE existantes (PR1).
2. ✅ Item 5.1 détecte un CMR1 et bloque le verdict (`uses_cmr1_without_derogation: true`) ; la dérogation manuelle libère le kill-switch.
3. ✅ Item 5.3 utilise `PfiInterventionParameter.pfi_value` sans recalcul ; signale clairement « En attente du PFI » si la table est vide pour la campagne.
4. ✅ Bouton « Relancer PFI » planifie `PfiCalculationJob.perform_later` pour toutes les interventions phyto de la campagne.
5. ✅ Items « Sans objet » (5.4, 5.10 hors filière concernée) sont marqués comme tels dans `HveAuditItem.evidence`, ne pénalisent pas le score.
6. ✅ La cell Phytosanitaire de la vue `show` montre un score / 63 + alerte rouge si CMR1.
7. ✅ Re-jouer `PhytoScorer.call` est idempotent (mêmes scores à fixtures identiques).
8. ✅ ~35 tests verts.

---

## 10. Fichiers touchés (synthèse)

**Dans le core Ekylibre** :

| Fichier | Action |
|---|---|
| `config/routes.rb` | +member actions `phytosanitary`, `recompute_phytosanitary`, `relaunch_pfi` sur `hve_audits` |
| `test/services/hve/scoring/phyto/*` | ~12 nouveaux tests par item |
| `test/services/hve/scoring/shared/phyto_inventory_test.rb` | Nouveau |
| `test/services/hve/scoring/phyto_scorer_test.rb` | Nouveau |
| `test/controllers/backend/hve_audits_controller_test.rb` | +3 tests |

**Dans le plugin `ekylibre-hve`** :

| Fichier | Action |
|---|---|
| `app/services/hve/scoring/phyto_scorer.rb` | Nouveau |
| `app/services/hve/scoring/phyto/*.rb` | 10 nouveaux |
| `app/services/hve/scoring/shared/phyto_inventory.rb` | Nouveau |
| `app/services/hve/scoring/shared/filiere_detector.rb` | Nouveau (réutilisable PR4-5) |
| `app/controllers/backend/hve_audits_controller.rb` | +3 actions |
| `app/views/backend/hve_audits/phytosanitary.html.haml` | Nouveau |
| `app/views/backend/hve_audits/_cmr_alert.html.haml` | Partial |
| `app/views/backend/hve_audits/show.html.haml` | Modif (cell phyto cliquable) |
| `config/locales/fra/hve.yml` | +clés phyto + i18n des codes 5.x |
| `config/locales/eng/hve.yml` | idem |

**Pas de nouvelle migration. Pas de nouveau seed YAML.** Tout est calcul à la volée.

---

## 11. Estimation et phasage interne

PR3 estimée à **4 jours-développeur**, découpée en 5 commits :

- **C1** : `PhytoInventory` + `FiliereDetector` + tests (~0.5 j)
- **C2** : `CmrScorer` + `UntreatedSurfaceScorer` + `IftScorer` (3 items les plus complexes) + tests (~1.5 j)
- **C3** : 7 scorers restants + tests (~0.5 j)
- **C4** : `PhytoScorer` orchestrateur + intégration kill-switch dans `HveAudit.recompute_verdict` + tests (~0.5 j)
- **C5** : UI (vue phyto + alerte CMR + bouton relaunch PFI) + i18n (~1 j)

Validation end-to-end sur tenant `djoulin` en clôture.

---

## 12. Décisions ouvertes à valider avant `/sc:implement`

1. **Fallback IFT** quand `PfiInterventionParameter` est vide : on renvoie `nil` (item « En attente ») ou `0` (pénalise) ? **Recommandation** : `nil` + UI claire, sinon on punit injustement.
2. **Détection biocontrôle** : on s'appuie uniquement sur `segment_code='S2'` du PFI (API ministère) ou on ajoute une heuristique secondaire (substances actives reconnues biocontrôle) ? **Recommandation** : uniquement PFI pour rester aligné sur la classification officielle ; warning visible si pas de PFI.
3. **Dérogation CMR1** : on saisit *une* dérogation globale par audit (booléen) ou *par intervention* concernée (plus précis) ? **Recommandation** : par audit en PR3, par intervention en PR ultérieure si besoin (le Plan HVE accepte les deux).
4. **Relancer PFI depuis l'UI** : on déclenche un job async (UX OK mais utilisateur attend) ou on insère un délai pour batcher plusieurs audits ? **Recommandation** : async direct, tag « En cours » jusqu'à callback.
5. **Filière mixte pondération** : on pondère chaque item filière-spécifique (5.4, 5.8, 5.9, 5.10) par la part SAU de la filière concernée, ou on applique le score plein si la filière est présente ? **Recommandation** : pondération par SAU pour rester juste sur les fermes polyvalentes.

Mes recommandations sont prudentes (côté correctness) — dis-moi si tu veux trancher autrement.

---

## 13. Prochaine étape

Valider les 5 décisions du §12, puis lancer `/sc:implement claudedocs/workflow_hve_pr3_phytosanitary.md`.
