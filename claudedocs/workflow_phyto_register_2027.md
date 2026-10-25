# Workflow — Registre phytosanitaire électronique 2027 (Issue #2663)

> **Statut** : Plan d'implémentation (aucune modification de code dans ce document)
> **Auteur** : Claude Code · 2026-06-05
> **Branche cible** : `5.0-beta`
> **Issue** : [ekylibre/ekylibre#2663](https://github.com/ekylibre/ekylibre/issues/2663) — *Registre phytosanitaire électronique 2027 - Beta*
> **Cadre réglementaire** : [Arrêté du 24 décembre 2025 (JORF n°053228465)](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053228465)
> **Milestone** : 5.0
> **Étape suivante** : `/sc:implement claudedocs/workflow_phyto_register_2027.md`

---

## 1. TL;DR

L'arrêté du 24/12/2025 oblige tous les utilisateurs professionnels de phytos à tenir un registre **au format électronique lisible par machine** à partir du **1er janvier 2027**, avec **conservation 5 ans**, et **conversion sous 30 jours** à partir du 1er janvier 2030.

Ekylibre possède déjà **~85 %** de la donnée. **Validé en revue** : la cible visée (via `usage_id` snapshotté dans `LoggedPhytosanitaryUsage`, cf. JS `interventions_phyto.js.coffee:285-288`) et le statut AB (`activity_productions.organic`, cf. `db/structure.sql:528`) sont déjà capturés — pas de migration nécessaire pour ces deux mentions. Les chantiers restants sont :

1. **Capturer les mentions encore manquantes** : stade BBCH au traitement, mode d'application, n° de lot semences, "intervention de ré-entrée précoce" + EPI associé, SIRET bénéficiaire (prestation), conditions météo (JSONB OpenWeatherMap).
2. **Modéliser le Certiphyto** sur `Worker` (numéro, validité) — non requis dans l'Annexe I mais cohérent avec les opérations.
3. **Construire deux exporteurs structurés** : XML et JSON sérialisant l'Annexe I de l'arrêté, par campagne ou plage de dates, scopés au SIRET du tenant. Format générique conforme à *EU Directive 2019/1024 Art. 2(13)*.
4. **Service de production du registre** : `Phytosanitary::Register::Builder` qui collecte toutes les interventions phyto d'une campagne et matérialise un payload conforme.
5. **UI Backend** : page `/backend/phytosanitary_register` avec sélecteur de campagne, validation pré-export (champs manquants), boutons XML / JSON / PDF, archivage `Document`.
6. **Job d'archivage annuel** : génération automatique avant le 31 janvier de l'année N+1 (transition 2027-2029) puis sous 30 jours (≥ 2030).

L'implémentation se fait **dans le cœur** (pas en plugin) car la fonctionnalité est obligatoire pour tous les utilisateurs FR — cohérent avec PFI / FEC / Telepac déjà en cœur. Le pilier UI peut être derrière un feature flag (`Preference`) pour rollout progressif.

---

## 2. Cadre réglementaire — mentions de l'Annexe I

Source : Arrêté du 24/12/2025, Annexe I.

| # | Mention | Statut | Source côté Ekylibre |
|---|---|---|---|
| 1 | SIRET de l'établissement détenteur | Obligatoire | `Entity#of_company` → `Entity#siret_number` (`app/models/entity.rb:73`) |
| 2 | SIRET du bénéficiaire (si prestation de services) | Conditionnel | À ajouter sur `Intervention` (ou récupérer via tiers facturant) |
| 3 | Nom commercial du produit | Obligatoire | `RegisteredPhytosanitaryProduct#name` (lexique EPHY) |
| 4 | Numéro AMM (autorisation de mise sur le marché) | Obligatoire | `RegisteredPhytosanitaryProduct#france_maaid` |
| 5 | Substances actives (semences traitées uniquement) | Conditionnel | À résoudre via `RegisteredPhytosanitaryProduct#active_compounds` (présent ou à ajouter selon migration lexique) |
| 6 | Date d'utilisation (ou semis pour semences traitées) | Obligatoire | `Intervention#started_at` |
| 7 | Dose appliquée (par ha ou densité semences) | Obligatoire | `InterventionInput#quantity_value` + `quantity_handler` (déjà calculée par `dose_validation_validator`) |
| 8 | Surface traitée / quantité de semences/plants | Obligatoire | `InterventionTarget#working_zone_area_value` |
| 9 | Nom de la culture ou rattachement à une zone | Obligatoire | `Plant#variety` → `Activity#name` via `ActivityProduction` |
| 10 | Localisation du traitement (coordonnées ou ref RPG) | Obligatoire | `InterventionTarget#working_zone` (geom) + `ActivityProduction#cap_land_parcel` (PAC îlot/parcelle, `app/models/activity_production.rb:86`) |
| 11 | Statut AB de la production | Obligatoire | ✅ Déjà présent — corrigé en implémentation : pas sur `activity_productions` (`organic` à `db/structure.sql:528` est en réalité sur `lexicon.master_production_prices`), mais via `Activity#production_system_name == 'organic_farming'` exposé par le helper `Activity#organic_farming?` (`app/models/activity.rb:462-464`). |
| 12 | Horaire début/fin (si AMM/règlementation l'impose) | Conditionnel | `InterventionWorkingPeriod#started_at`/`stopped_at` |
| 13 | Stade phénologique (BBCH) | Conditionnel | **MANQUANT** — à ajouter (cf. §4.1) |
| 14 | N° de lot (traitement semences/plants) | Conditionnel | **MANQUANT** — à ajouter (cf. §4.1) |
| 15 | Cible visée (organisme nuisible) | Conditionnel | ✅ Déjà captée : sélection de l'usage côté UI (`app/assets/javascripts/backend/interventions_phyto.js.coffee:285-288`) → `intervention_inputs.usage_id` → snapshot `LoggedPhytosanitaryUsage#target_name_label_fra` + `crop_label_fra` |
| 16 | Mode d'application | Conditionnel | `Intervention#procedure_name` couvre partiellement ; champ explicite préférable (pulvérisation localisée, enrobage, granulé…) |
| 17 | Intervention ré-entrée précoce : horaire, lieu, EPI | Conditionnel | **MANQUANT** — nouvelle entité ou flag sur intervention + association EPI |

**Hors Annexe I, recommandés** : Certiphyto applicateur, conditions météo (température, vent, hygrométrie). Non obligatoires au registre mais soutiennent les autres obligations (BCAE, Ecophyto, audit).

Conditions météo : ajouter un champs 'weather_conditions" type JSONB au modele "Intervention" table : "interventions".
{weather_condition_code: '502', temperature: '22', wind: '10', humidity: '68' }
Utilise un selecteur d'icone dans le formulaire intervention pour faire selectionner à l'utilisateur les conditions basé sur cette reference
https://openweathermap.org/api/weather-conditions

la température 'temperature' est en °C et la vitesse du vent 'wind' en km/h et l'humidité 'humidity' en %

---

## 3. Audit du code existant — ce qui est déjà là

Inventaire issu de l'exploration ciblée. Sauf mention contraire, les chemins sont relatifs à `/home/djoulin/projects/ekylibre`.

### 3.1 Référentiel produits (lexique EPHY)
- `app/models/lexicon/registered_phytosanitary_product.rb` — `france_maaid` (AMM), `state` (autorisé/retiré), `in_field_reentry_delay`, `product_type` (ADJUVANT/PCP), `allowed_mentions` (compatibilité bio).
- `app/models/lexicon/registered_phytosanitary_usage.rb` — `dose_quantity/unit`, `development_stage_min/max`, `pre_harvest_delay`, ZNT (`untreated_buffer_aquatic/arthropod/plants`), `target_name_label_fra`, `ephy_usage_phrase`.
- `app/models/lexicon/registered_phytosanitary_risk.rb` + `registered_phytosanitary_symbol.rb` — symbologie SGH, phrases H.
- Décorateurs : `app/decorators/registered_phytosanitary_*_decorator.rb`.
- Schéma `lexicon` partagé, chargé via `rake lexicon:load` (cf. CLAUDE.md).

### 3.2 Interventions phyto
- `app/models/intervention.rb:72` — `PHYTO_PROCEDURE_NAMES` (≈ 13 procédures, dont `spraying`, `chemical_weed_killing`, `vine_spraying_with_fertilizing`).
- `app/models/intervention_input.rb:75-100` — lien `usage_id` vers `RegisteredPhytosanitaryUsage`, `allowed_entry_factor`, `allowed_harvest_factor`.
- `app/models/intervention_parameter/logged_phytosanitary_product.rb` & `logged_phytosanitary_usage.rb` — **snapshot** du produit/usage au moment de l'intervention (résistant aux modifications postérieures du lexique). Atout réglementaire majeur : les données ne dérivent pas.
- `app/models/intervention_target.rb:71-80` — `working_zone` (PostGIS), `working_zone_area_value`, FK vers `Product` (Plant).
- `app/models/intervention_working_period.rb:42-223` — `started_at`, `stopped_at`, `nature` (préparation/déplacement/intervention/pause).
- 12 validators métier dans `app/services/interventions/phytosanitary/` (dose, ZNT aquatique, mentions AB, état produit, fréquence, max d'applications, areas non traitées, mix category, …) — base solide pour valider la conformité d'export.

### 3.3 PFI / IFT
- `app/jobs/pfi_calculation_job.rb`, `app/jobs/pfi_report_job.rb` — pipeline async, produit un PDF `Bilan_IFT_<campagne>.pdf` archivé en `Document` de nature `phytosanitary_certification`.
- `app/services/interventions/phytosanitary/pfi_computation.rb` + `pfi_client_api.rb` + `lib/clients/gouv/pfi_client.rb` — appel API agriculture.gouv.fr (alim.agriculture.gouv.fr).
- `app/models/pfi_intervention_parameter.rb` + `pfi_campaigns_activities_intervention.rb` (vue matérialisée).

### 3.4 Exports existants
- `app/services/printers/phytosanitary_register_printer.rb` — **PDF** registre par campagne ± activité (filtre par `procedure_name`). Sert de référence pour le scope.
- `app/services/printers/phytosanitary_applicator_sheet_printer.rb` — fiche applicateur PDF (parameters_settings, doses, volume bouillie).
- `app/services/interventions/exports/*.rb` — patron d'export XLSX (3 services existants : interventions, costs, tool_costs). Patron à dupliquer pour XML/JSON.
- API v1/v2 lecture seule sur `registered_phytosanitary_*` (aucun export registre).

### 3.5 Liaison Activité ↔ Culture ↔ Parcelle
- `Intervention.targets → Product → activity_production_id → ActivityProduction → activity_id → Activity`.
- `ActivityProduction#cap_land_parcel` (`app/models/activity_production.rb:86`) → `CapLandParcel` (îlot + parcelle PAC) — **clé pour le champ "ref RPG"**.

### 3.6 Tiers
- `Entity#siret_number` (`app/models/entity.rb:73`, validation française `app/models/entity.rb:197`).

### 3.7 Lacunes confirmées
- ❌ Météo sur intervention/working_period (le plugin `weenat` existe mais n'est pas couplé).
- ❌ Certiphyto sur `Worker` / `WorkerContract` / `MasterDoerContract`.
- ❌ EPI/PPE sur intervention (ni en attribut, ni en association).
- ❌ Stade BBCH au traitement (uniquement plage autorisée dans `LoggedPhytosanitaryUsage`).
- ❌ Mode d'application explicite (rampe / atomiseur / enrobage / granulé).
- ❌ N° de lot semences/plants traités.
- ❌ Export XML / JSON conforme Annexe I.
- ❌ Plugin dédié — **par choix, ne PAS créer de plugin** (obligation universelle pour les exploitations FR, cf. §6).

---

## 4. Plan d'implémentation par phases

7 phases, dépendances strictes. **Phases 1-3 livrent l'export beta minimal viable** (correspondant à *Registre phytosanitaire électronique 2027 - **Beta***, intitulé de l'issue).

### Phase 1 — Migrations & enrichissement du modèle (J+1 à J+3)

Objectif : capturer les mentions manquantes sur les bons agrégats.

#### 4.1 Migrations

| # | Migration | Colonnes | Note |
|---|---|---|---|
| 1.1 | `add_bbch_to_intervention_targets` | `phenological_bbch_stage:integer` | BBCH 00-99 — cible et statut AB déjà captés ailleurs (cf. §2) |
| 1.2 | `add_application_mode_to_intervention_parameters` | `application_mode:string` seul | Colonne sur la table STI `intervention_parameters`. Enum string (`rampe`, `atomiseur`, `enrobage`, `granule`, `localized`, `aerial`…). ⚠️ Validé en implémentation : `batch_number:string` existe déjà sur `intervention_parameters` et est utilisé pour les n° de lot (cf. `intervention_output:191-197`, API v1/v2). **Réutiliser** `batch_number`, pas de `seed_lot_number`. |
| 1.3 | `add_weather_conditions_to_interventions` | `weather_conditions:jsonb` sur `interventions` | Schéma JSON figé : `{ weather_condition_code, temperature, wind, humidity }`. `weather_condition_code` = code numérique [OpenWeatherMap](https://openweathermap.org/api/weather-conditions) (ex. `502`). Unités : `temperature` °C, `wind` km/h, `humidity` %. Pattern `jsonb` déjà utilisé (`custom_fields`, `providers`, `provider` sur la même table). |
| 1.5 | `add_early_reentry_to_interventions` | sur `interventions` : `early_reentry:boolean DEFAULT false`, `early_reentry_ppe_description:text`, `early_reentry_reason:text` | intervention de ré-entrée précoce (mention 17 Annexe I) |
| 1.6 | `add_certiphyto_to_workers` | `certiphyto_number:string`, `certiphyto_kind:string`, `certiphyto_expires_on:date` | hors Annexe I mais recommandé |
| 1.7 | `add_beneficiary_siret_to_interventions` | `beneficiary_siret:string` | si prestation de services |

**Conventions** :
- Toutes les migrations doivent passer `rake tenant:migrate` (cf. CLAUDE.md — schéma SQL régénéré).
- Index : `add_index :workers, :certiphyto_expires_on` (alertes UI). Pas d'index requis sur les autres colonnes (cardinalité faible ou usage tabulaire).
- Une seule migration par fichier (convention Ekylibre).

#### 4.2 Modèles & validations

- `app/models/intervention_target.rb` — exposer `phenological_bbch_stage`, ajouter validation `inclusion: 0..99` quand présent.
- `app/models/intervention_input.rb` — ajouter `enum application_mode: …` ; valider présence de `seed_lot_number` si la procédure est `seeding_with_treated_seeds`.
- `app/models/intervention.rb` — exposer `weather_conditions`, `early_reentry`, `early_reentry_ppe_description`, `early_reentry_reason`, `beneficiary_siret` ; helper `weather_conditions_icon_code` (mapping `weather_condition_code` → icône OpenWeatherMap) ; validation conditionnelle `presence: true, of: :early_reentry_ppe_description if: :early_reentry?`.
- `app/models/worker.rb` — validation `certiphyto_expires_on` futur si numéro renseigné ; helper `certiphyto_valid_at?(date)`.
- `ActivityProduction#organic` est déjà exposé — aucune modification modèle requise.

#### 4.3 Decorators

- `app/decorators/intervention_decorator.rb` — méthode `register_payload` qui assemble l'Annexe I (utilisée par §4.3 Phase 2 export).

### Phase 2 — Service de construction du registre (J+3 à J+5)

Objectif : un seul point de vérité qui matérialise la donnée structurée à exporter.

#### Fichiers

| Fichier | Rôle |
|---|---|
| `app/services/phytosanitary/register/builder.rb` | Reçoit `(campaign:, scope: :all/activity/period, from:, to:)`. Charge interventions avec `includes(...)` (cf. §6 — N+1). Renvoie un `RegisterPayload` (struct immuable). |
| `app/services/phytosanitary/register/payload.rb` | Struct `RegisterPayload` : `holder_siret`, `entries[]`, `period`, `generated_at`. Chaque `entry` = une intervention × un input × une target (cartésien). |
| `app/services/phytosanitary/register/entry.rb` | Struct `Entry` typée — 17 champs Annexe I + métadonnées. |
| `app/services/phytosanitary/register/integrity_validator.rb` | Valide qu'un payload est conforme (champs obligatoires présents). Renvoie `Result` (ok / errors par entrée). |

#### Sélection des interventions

```ruby
# pseudo-code dans Builder#fetch
Intervention
  .joins(:campaigns).where(campaigns: { id: campaign.id })
  .where(procedure_name: Intervention::PHYTO_PROCEDURE_NAMES)
  .where.not(state: :rejected)
  .includes(
    :working_periods,
    :early_reentries,
    inputs: [
      { product: :variant },
      :logged_phytosanitary_product,
      :logged_phytosanitary_usage  # snapshot cible + culture
    ],
    targets: [
      { product: { activity_production: [:activity, :cap_land_parcel] } }  # organic via activity_production
    ],
    doers: [:product]
  )
```

L'`includes` ci-dessus prévient explicitement le N+1 identifié dans CLAUDE.md (`backend/interventions/show.html.haml:100-113`).

#### Memoisation

`Intervention#total_cost` est connu pour être recalculé 6-10× par render (CLAUDE.md). Le builder doit memoizer les coûts/doses pendant la vie du `RegisterPayload` — ce sont des données figées au moment de l'export.

### Phase 3 — Exporteurs XML & JSON (J+5 à J+7)

Objectif : sérialisation conforme "lisible par machine" (EU 2019/1024).

#### Fichiers

| Fichier | Rôle |
|---|---|
| `app/services/phytosanitary/register/exporters/json_exporter.rb` | `call(payload)` → `String` JSON. Schéma : 1 racine `{ holder, period, entries: [...] }`. |
| `app/services/phytosanitary/register/exporters/xml_exporter.rb` | `call(payload)` → `String` XML. Racine `<PhytoRegister>` ; espace de noms candidat : `urn:fr:agri:phyto:register:1.0` (placeholder en attendant un schéma officiel — voir §7 Open Questions). |
| `app/services/phytosanitary/register/exporters/csv_exporter.rb` | Bonus : CSV "à plat" pour ouverture tableur (1 ligne par `entry`). |
| `lib/eky_phyto_register.xsd` *(optionnel)* | Schéma XSD interne pour validation de notre propre sortie. **Pas un standard officiel** — l'arrêté ne le publie pas. |

#### Convention de nommage des fichiers exportés

`registre_phyto_<siret>_<campagne>_<YYYYMMDD>.{xml,json,csv}` — archivé dans `Document` avec nature `phytosanitary_register` (nouvelle nature à déclarer dans `app/models/document.rb` / locales).

#### Tests

- `test/services/phytosanitary/register/builder_test.rb` — fixture campagne avec 2-3 interventions, vérifier exhaustivité.
- `test/services/phytosanitary/register/exporters/{xml,json}_exporter_test.rb` — golden files (snapshot) sous `test/fixtures/phyto_register/expected/*.{xml,json}`.
- `test/services/phytosanitary/register/integrity_validator_test.rb` — chaque mention obligatoire manquante doit lever une erreur tracée.

### Phase 4 — UI Backend (J+7 à J+10)

Objectif : page utilisateur pour générer et archiver le registre.

#### Routes

```ruby
# config/routes.rb (namespace :backend)
resources :phytosanitary_registers, only: [:index, :show, :create] do
  collection do
    get :preview
    get :download
  end
end
```

#### Contrôleur

`app/controllers/backend/phytosanitary_registers_controller.rb`
- `#index` — liste des registres déjà générés (`Document.where(nature: 'phytosanitary_register')`).
- `#show` — détail d'un registre archivé.
- `#preview` — appel `Builder` + `IntegrityValidator`, affiche un tableau lisible + liste des erreurs/warnings (interventions sans BBCH, sans cible, sans SIRET bénéficiaire pour prestations…).
- `#create` — params `campaign_id`, `format` (xml/json/csv) → archive `Document` + redirige vers `#show`.

#### Vues HAML

`app/views/backend/phytosanitary_registers/` :
- `index.html.haml` — liste avec sélecteur de campagne et bouton "Générer".
- `preview.html.haml` — tableau (utiliser `collection: ...` partial — CLAUDE.md performance).
- `show.html.haml` — lien de téléchargement + métadonnées.

#### i18n

- `config/locales/eng/actions.yml` — `phytosanitary_registers.preview`, `phytosanitary_registers.generate_xml`, `…generate_json`.
- `config/locales/eng/models.yml` — labels nouvelles colonnes (bbch_stage, targeted_pest, application_mode, seed_lot, …).
- `config/locales/fra/*.yml` — équivalent FR (DeepL via `bin/translate_locales_deepl.rb` après `rake clean:locales`).
- Workflow `clean:locales` exige `Gemfile.local`/`Gemfile.plugins` désactivés (CLAUDE.md).

#### Permissions

- Mettre à jour `config/rights.yml` — action `phytosanitary_registers` sous le rôle "Phytosanitaire".

### Phase 5 — Formulaire d'intervention enrichi (J+10 à J+13)

Objectif : exposer les nouveaux champs à la saisie pour que la donnée existe à l'export.

- `app/views/backend/interventions/_form.html.haml` — bloc conditionnel quand `procedure.phytosanitary?` :
  - input `phenological_bbch_stage` (select 00-99 ou stades clés BBCH ; possibilité de s'appuyer sur `lexicon.master_phenological_stages` ou `public.vegetative_stages`).
  - input `application_mode` (select sur enum).
  - input `seed_lot_number` si procédure de semis traité.
  - checkbox `early_reentry` qui révèle `early_reentry_ppe_description` + `early_reentry_reason` (pattern existant `data-show-if`).
  - bloc météo : sélecteur d'icône OpenWeatherMap (le `weather_condition_code` mappe vers un set d'icônes — patron existant des sélecteurs avec preview, cf. `data-selector` Ekylibre), puis trois inputs numériques `temperature` (°C), `wind` (km/h), `humidity` (%). Valeurs sérialisées dans `interventions.weather_conditions` JSONB.
  - **Pas d'input cible visée** : déjà capté par la sélection d'usage (cf. §2 mention 15).
- Asset JS : nouveau fichier `app/assets/javascripts/backend/interventions_phyto_register.js.coffee` pour la sérialisation/désérialisation JSONB des conditions météo côté formulaire (lecture du sélecteur d'icône, écriture dans un input caché `interventions[weather_conditions]`).
- Whitelister les nouveaux params dans `app/controllers/backend/interventions_controller.rb` : `:phenological_bbch_stage`, `:application_mode`, `:seed_lot_number`, `:early_reentry`, `:early_reentry_ppe_description`, `:early_reentry_reason`, `:beneficiary_siret`, `weather_conditions: %i[weather_condition_code temperature wind humidity]`.

### Phase 6 — Génération automatique annuelle (J+13 à J+15)

Objectif : tenir le calendrier réglementaire.

- `app/jobs/phytosanitary_register_archive_job.rb` — pour chaque tenant, génère le registre des interventions de l'année écoulée. Cron Sidekiq.
- Déclenchement :
  - **2027-2029** : avant le **31 janvier N+1**, génération du registre de l'année N. Schedule cron : `0 6 15 1 *` (15 janvier 06:00) pour laisser 16 jours de marge.
  - **≥ 2030** : génération à J+30 après chaque intervention. Soit hook `after_commit` sur `Intervention` créant un job différé, soit cron quotidien qui balaye les interventions de J-30.
- Archivage `Document.create!(nature: 'phytosanitary_register', file: …)` — patron déjà utilisé par `pfi_report_job.rb`.
- **Attention apartment-sidekiq** (cf. CLAUDE.md) : ce job doit s'exécuter par tenant. Privilégier l'enqueue depuis un rake task qui itère sur `Ekylibre::Tenant.list`.

### Phase 7 — Conformité, conservation & intégrité (J+15 à J+17)

Objectif : garantir les 5 ans de conservation et l'intégrité.

- `Document` de nature `phytosanitary_register` : ajouter `sha256_digest` + `signed_at` à la création. Empêcher destruction.
- Migration `add_phyto_register_protection_to_documents` (colonne booléenne `legal_retention` + check d'expiration ≥ created_at + 5 ans).
- Rake task `phyto_register:verify` qui vérifie l'intégrité des SHA des registres archivés.
- Documenter dans le manuel utilisateur (hors scope code, mais à signaler).

---

## 5. Inventaire des fichiers (changement direct)

| # | Fichier | Action | Phase |
|---|---|---|---|
| 1 | `db/migrate/YYYYMMDDHHMMSS_add_bbch_to_intervention_targets.rb` | Créer | 1 |
| 2 | `db/migrate/…_add_application_mode_to_intervention_inputs.rb` | Créer | 1 |
| 3 | `db/migrate/…_add_weather_conditions_to_interventions.rb` | Créer | 1 |
| 4 | `db/migrate/…_add_early_reentry_to_interventions.rb` | Créer | 1 |
| 5 | `db/migrate/…_add_certiphyto_to_workers.rb` | Créer | 1 |
| 6 | `db/migrate/…_add_beneficiary_siret_to_interventions.rb` | Créer | 1 |
| 7 | `db/structure.sql` | Régénéré auto (ne PAS éditer à la main) | 1 |
| 8 | `app/models/intervention.rb` | Exposer `weather_conditions`, `early_reentry*`, `beneficiary_siret` + validation conditionnelle PPE | 1 |
| 9 | `app/models/intervention_target.rb` | Colonne `phenological_bbch_stage` + validation `0..99` | 1 |
| 10 | `app/models/intervention_input.rb` | Enum `application_mode`, `seed_lot_number` + validation conditionnelle | 1 |
| 11 | `app/models/worker.rb` | Champs Certiphyto + helper `certiphyto_valid_at?` | 1 |
| 12 | `app/services/phytosanitary/register/builder.rb` | **Nouveau** | 2 |
| 13 | `app/services/phytosanitary/register/payload.rb` | **Nouveau** | 2 |
| 14 | `app/services/phytosanitary/register/entry.rb` | **Nouveau** | 2 |
| 15 | `app/services/phytosanitary/register/integrity_validator.rb` | **Nouveau** | 2 |
| 16 | `app/services/phytosanitary/register/exporters/json_exporter.rb` | **Nouveau** | 3 |
| 17 | `app/services/phytosanitary/register/exporters/xml_exporter.rb` | **Nouveau** | 3 |
| 18 | `app/services/phytosanitary/register/exporters/csv_exporter.rb` | **Nouveau (bonus)** | 3 |
| 19 | `lib/eky_phyto_register.xsd` | **Nouveau (optionnel)** | 3 |
| 20 | `app/controllers/backend/phytosanitary_registers_controller.rb` | **Nouveau** | 4 |
| 21 | `app/views/backend/phytosanitary_registers/index.html.haml` | **Nouveau** | 4 |
| 22 | `app/views/backend/phytosanitary_registers/preview.html.haml` | **Nouveau** | 4 |
| 23 | `app/views/backend/phytosanitary_registers/show.html.haml` | **Nouveau** | 4 |
| 24 | `config/routes.rb` | Ajout routes `:phytosanitary_registers` | 4 |
| 25 | `config/rights.yml` | Permission phyto register | 4 |
| 26 | `config/locales/eng/{actions,models,enumerize}.yml` | Nouvelles clés | 4-5 |
| 27 | `config/locales/fra/*.yml` | Traductions | 4-5 |
| 28 | `app/views/backend/interventions/_form.html.haml` | Inputs BBCH, mode appli, lot semences, ré-entrée, sélecteur météo | 5 |
| 29 | `app/assets/javascripts/backend/interventions_phyto_register.js.coffee` | **Nouveau** — sérialisation JSONB météo + show/hide ré-entrée | 5 |
| 30 | `app/controllers/backend/interventions_controller.rb` | Whitelist params (cf. §Phase 5) | 5 |
| 31 | `app/jobs/phytosanitary_register_archive_job.rb` | **Nouveau** | 6 |
| 32 | `config/sidekiq.yml` ou cron loader | Schedule annuel | 6 |
| 33 | `lib/tasks/phyto_register.rake` | Tâches `enqueue_all`, `verify` | 6-7 |
| 34 | `app/models/document.rb` | Nature `phytosanitary_register` + `legal_retention` | 7 |
| 35 | `app/decorators/intervention_decorator.rb` | `register_payload` helper | 2 |
| 36 | Tests : `test/services/phytosanitary/register/**/*_test.rb` | Builder + integrity + 3 exporters | 2-3 |
| 37 | Tests : `test/controllers/backend/phytosanitary_registers_controller_test.rb` | CRUD + preview | 4 |
| 38 | Tests : `test/jobs/phytosanitary_register_archive_job_test.rb` | Génération par tenant | 6 |
| 39 | Fixtures : `test/fixtures/phyto_register/expected/*.{xml,json,csv}` | Golden files | 3 |

---

## 6. Décisions architecturales

### 6.1 Cœur ou plugin ?

**Cœur** (pas de plugin). Justifications :
- Obligation réglementaire universelle pour les exploitations FR (calendrier 2027/2030).
- PFI, FEC, Telepac (autres obligations FR) sont déjà en cœur.
- Pas de dépendance externe lourde (pas de service métier tiers requis).
- Garantie de migration cohérente avec `db/structure.sql` lors des upgrades.

Une variation : encapsuler le registre derrière une `Preference` `:phytosanitary_register_enabled` (default `true` si tenant FR détecté par `Entity#country`).

### 6.2 Snapshot vs résolution dynamique

Le modèle existant `LoggedPhytosanitaryProduct/Usage` snapshot la donnée du lexique au moment de la création de l'intervention. **C'est la bonne stratégie pour le registre** : si l'AMM est retirée 6 mois plus tard, le registre conserve la trace exacte au jour du traitement. À ne pas régresser.

### 6.3 Performances (CLAUDE.md — hotspots connus)

- L'export doit utiliser `find_each` (pas `each`) sur les interventions d'une campagne (campagnes > 1000 interventions possibles sur de grosses exploitations).
- `Ekylibre::Record.suppress_callbacks` pour les job d'archivage (lecture seule mais évite la cascade `Sums`/`Bookkeep` sur recompute incident).
- Mémoizer `Onoma::*` lookups dans le builder (cf. CLAUDE.md — 183 calls non memoizés).
- Préférer `render partial:, collection:` dans les vues `preview` (cf. CLAUDE.md HAML).

### 6.4 Format XML — schéma

L'arrêté ne publie **pas** de schéma XML/JSON officiel à ce jour (juin 2026 — vérifier au moment de l'implémentation). Approche :
1. Définir un schéma interne `urn:fr:agri:phyto:register:1.0` couvrant l'Annexe I.
2. Documenter le schéma en YAML (`config/phyto_register_schema.yml`).
3. Prévoir un point d'extension `Exporters::Adapters::*` si l'État publie un format normé (équivalent FEC-XSD).

### 6.5 Pas de mock DB en tests

Cf. memory `local-test-db-run-friction.md` : `bundle exec rake test` exige une base `ekylibre_test` correctement reconstituée. Les tests du builder doivent passer en intégration sur la DB (Apartment + tenant `test`).

---

## 7. Risques et questions ouvertes

| # | Question | Impact | Action |
|---|---|---|---|
| 7.1 | Format XML/JSON publié officiellement par DGAL/ministère ? | Élevé — sans schéma officiel, l'export ne garantit pas la conformité 100 %. | Surveiller publications JORF Q4 2026. Concevoir l'exporteur pour basculer vers un schéma officiel via une couche d'adaptateurs. |
| 7.2 | API ministérielle de dépôt direct ? | Moyen — l'arrêté ne mentionne pas de dépôt, mais cela peut évoluer (cf. PFI déjà piloté par API). | Architecture déjà prévue dans `lib/clients/gouv/` (cf. PFI). Stub à ajouter si nécessaire. |
| 7.3 | Statut AB de la production : champ existant ailleurs ? | ✅ Résolu | `activity_productions.organic boolean` confirmé (`db/structure.sql:528`). Aucune migration nécessaire. |
| 7.4 | Confirmation que la cible *choisie* est stockée | ✅ Résolu | Sélection d'usage côté UI (`interventions_phyto.js.coffee:285-288`) → `intervention_inputs.usage_id` → snapshot dans `LoggedPhytosanitaryUsage` (`target_name_label_fra`, `crop_label_fra`). Aucun champ supplémentaire requis. |
| 7.5 | Intervention multi-input/multi-target — cardinalité dans le registre | Faible | Décision : 1 ligne de registre = (intervention × input × target). Doc à inclure dans le préambule du payload XML. |
| 7.6 | Prestation de services : qui détient le registre ? | Moyen | L'Annexe I distingue détenteur (entreprise prestataire) et bénéficiaire (donneur d'ordre). Modéliser via `beneficiary_siret` sur intervention (§4.1 migration 1.7). |
| 7.7 | Plugin Weenat actif : météo auto ? | Faible | Vérifier hooks existants. Si non, laisser les champs météo optionnels en saisie manuelle. |
| 7.8 | Volume de données 5 ans × N tenants — stockage | Faible | XML/JSON < 1 Mo par campagne typique. Pas de problème à 5 ans. SHA stocké en base, fichier en `Document.file`. |
| 7.9 | Préparation EU SUR (Sustainable Use Regulation) | Inconnu | Cadrer une seconde itération si le règlement européen ajoute des mentions. |

---

## 8. Stratégie de test

1. **Tests unitaires** — chaque service de la Phase 2-3 (builder, validator, exporters) avec fixtures minimalistes.
2. **Tests d'intégration** — Phase 4 contrôleur, scénario : créer 5 interventions phyto sur 1 campagne, générer le registre, vérifier XML produit contre golden file.
3. **Tests de conformité** — `IntegrityValidator` couvre exhaustivement les 17 mentions Annexe I. Chaque mention manquante = un test dédié.
4. **Tests de migration** — fixtures legacy sans BBCH ; vérifier que le validator les marque comme incomplètes mais que l'export ne crashe pas.
5. **Tests de job** — Phase 6, avec `apartment-sidekiq` côté tenant `test`.

Lancer : `bundle exec ruby -Itest test/services/phytosanitary/register/builder_test.rb -n test_…` (cf. CLAUDE.md).

---

## 9. Calendrier et points de validation

| Phase | Durée | Sortie validable |
|---|---|---|
| 1 | 1.5 j | 6 migrations passent ; tests modèles verts (réduit suite à validation : cible/AB déjà présents) |
| 2 | 2 j | Builder produit un payload sur dataset démo |
| 3 | 2 j | XML/JSON valident contre le schéma interne + golden files |
| 4 | 3 j | Page `/backend/phytosanitary_registers` fonctionnelle |
| 5 | 3 j | Saisie complète d'une intervention phyto via formulaire (sélecteur météo inclus) |
| 6 | 2 j | Job archive un registre dans `Document` |
| 7 | 2 j | Intégrité SHA vérifiée ; rake `phyto_register:verify` |
| **Total** | **~15.5 j** | Beta livrable pour campagne 2027 |

**Gates qualité** :
- Fin Phase 3 = beta démontrable à l'équipe métier (export brut sans UI).
- Fin Phase 4 = démo utilisateur agronome possible.
- Fin Phase 7 = release candidate.

---

## 10. Hors scope de ce ticket

- Connecteur amont vers OAD / pulvérisateur connecté (Iso 11783) — sujet séparé.
- Refactoring des hotspots de performance documentés dans CLAUDE.md (cascade callbacks `Intervention#save`, N+1 controllers) — à traiter dans une initiative dédiée.
- Plugin officiel ministériel s'il est publié — à intégrer dans une itération ultérieure via la couche d'adaptateurs prévue en §6.4.
- Intégration mobile / saisie offline.

---

## 11. Sources

- [Arrêté du 24 décembre 2025 — JORF n°053228465](https://www.legifrance.gouv.fr/jorf/id/JORFTEXT000053228465)
- [Réussir Grandes Cultures — Registre phytosanitaire numérique 2027](https://www.reussir.fr/grandes-cultures/registre-phytosanitaire-numerique-annie-genevard-fixe-les-regles-pour-2027)
- [DRAAF Pays-de-la-Loire — Évolutions réglementaires 1er janvier 2026](https://draaf.pays-de-la-loire.agriculture.gouv.fr/tenue-des-registres-d-utilisation-des-produits-phytopharmaceutiques-des-a2081.html)
- [Chambre d'agriculture Ardennes — Nouvelle réglementation 2027](https://ardennes.chambres-agriculture.fr/sinformer/reglementations/details-des-reglementations/registre-phyto-nouvelle-reglementation-2027)
- [Terre-net — Précisions ministère sur registre numérique](https://www.terre-net.fr/produits-phytos/article/892753/le-ministere-precise-les-modalites-pour-le-registre-phytosanitaire-numerique)
