# Classification des modèles — questionnaire

> Engendré par `rake monoschema:questionnaire` le 14 septembre 2026.
> **Les faits sont mesurés, les réponses sont à écrire à la main.** Une fois
> le document rempli, ses réponses sont reportées dans
> `db/monoschema/classification.yml`, qui fait foi.

> **Dépouillé le 15 septembre 2026.** Les réponses de ce document ont été
> reportées dans `db/monoschema/classification.yml`, qui fait foi, et
> `plan.yml` régénéré : 234 tables au plan de données, 5 à déplacer vers le
> `lexicon`, 2 supprimées, 40 clés en UUIDv7. Ce fichier reste le relevé des
> réponses — le régénérer les effacerait.

Ce document accompagne le point 1.5 de
[la feuille de route](v6-roadmap.md) : chacune des **241 tables du
plan de données** doit recevoir une décision avant que le générateur de
migrations du point 1.6 ne les touche.

**Quatre réponses possibles**, à écrire dans la colonne *Décision* :

| Réponse | Ce qu'elle veut dire |
|---|---|
| *(vide)* ou `conserver` | la table porte les données d'une ferme : `tenant_id`, PK composite, RLS. C'est le défaut |
| `lexicon` | référentiel partagé entre toutes les fermes, lu seulement. Suppose qu'aucune ferme ne l'édite |
| `supprimer` | table morte : ni le lot 1 ni la suite n'ont à la porter |
| `contrôle` | globale sans être un référentiel : infrastructure, identité inter-fermes |
| `discuter` | la question demande autre chose qu'une réponse en un mot |

Chaque table n'apparaît qu'une fois, dans la section où un signal l'a
rangée. La colonne `clé` marque les tables qui recevraient une clé
**UUIDv7** parce que le terrain peut les créer hors ligne (ADR-003) ;
écrire `bigint` ou `uuidv7` dans la décision revient sur ce choix, qui est
le seul irréversible du lot.

**Comment lire les faits.** `mentions` compte les occurrences du nom de la
table et de ses modèles dans `app/`, `lib/` et `config/` — le fichier du
modèle lui-même est exclu, pour qu'une table morte ne se compte pas
elle-même. `fixtures` donne le nombre de lignes du jeu de test, `—` quand
il n'y en a pas. `migration` est la dernière migration qui nomme la table.
`réf.` compte les clés étrangères déclarées, `impl.` les colonnes en `_id`
qui en tiennent lieu sans contrainte. `écran` dit si le backend porte un
contrôleur ou des vues pour cette table — donc si une ferme peut la
modifier.


---

## 1. Les 7 questions déjà ouvertes

Ce sont celles que la classification a laissées en suspens. Elles
demandent plus qu'un mot : la réponse attendue est une phrase.

### districts

référentiel géographique dupliqué dans chaque ferme. Le passer au plan référentiel supposerait qu'aucune ferme ne l'édite — à vérifier avant de trancher

**Réponse : lexicon**

### postal_zones

même question que `districts`

**Réponse :lexicon**

### vegetative_stages

stades BBCH : référentiel agronomique dupliqué par ferme, alors que le lexicon en porte déjà

**Réponse :lexicon**

### net_services

liste de services, sans donnée propre à la ferme : candidate au plan référentiel

**Réponse :lexicon**

### units

unités de mesure : le lexicon porte `master_units`. Fusionner ou garder une table par ferme est une décision agronomique, pas technique

**Réponse :fusionner et a mettre dans lexicon**

### saas_subscriptions

porte un `tenant_name` : une ligne d'une ferme désigne une *autre* ferme par son nom. C'est exactement le lien inter-tenant que le point 1.22 doit rendre explicite

**Réponse :supprimer ancienne table pour gérer les abonnements**

### users

reste au plan de données pour le lot 1 — Devise y est encore. Le trio du point 1.14 (`tenants`, `users`, `user_tenants`) est neuf ; le lot 2 réconciliera les deux avec Keycloak

**Réponse : table historique des utilisateurs d'une ferme dans un tenant, à supprimer si on considere que le trio gerera les acces et droits**

---

## 2. Le reste des tables, par ordre d'attention


### Tables sans modèle ActiveRecord

Aucune classe ne les déclare. Soit elles sont mortes, soit elles ne sont
lues qu'en SQL — ce qui se vérifie dans la colonne « mentions ».

*Aucune.*

### Tables peu mentionnées et sans fixtures (62)

Moins de quinze mentions dans le code et pas une ligne de fixture. Le
signal est faible pris seul — une table peut être écrite par un
exchanger et lue nulle part — mais c'est là que se trouvent les
candidates à la suppression.

| Table | Modèle | col. | réf. | impl. | mentions | fixtures | écran | migration | clé | Décision |
|---|---|---:|---:|---:|---:|---:|---|---|---|---|
| alerts | Alert | 8 | 1 | 2 | 14 | 0 | non | 2016-09 |  |  |
| intervention_proposals | InterventionProposal | 11 | 3 | 0 | 14 | — | non | 2018-05 |  |  |
| target_distributions | TargetDistribution | 11 | 0 | 5 | 14 | 0 | non | 2017-10 |  |  |
| activity_distributions | ActivityDistribution | 9 | 0 | 4 | 11 | 0 | non | 2015-02 |  |  |
| daily_charges | DailyCharge | 13 | 4 | 0 | 11 | — | non | 2023-01 |  |  |
| product_linkages | ProductLinkage | 15 | 0 | 6 | 11 | 0 | oui | 2018-09 |  |  |
| technical_itinerary_intervention_templates | TechnicalItineraryInterventionTemplate | 14 | 2 | 0 | 11 | — | non | 2021-10 |  |  |
| manure_management_plan_zones | ManureManagementPlanZone | 26 | 0 | 4 | 10 | — | non | 2021-07 |  |  |
| planning_scenarios | Scenario | 9 | 1 | 2 | 9 | — | non | 2018-07 |  |  |
| planning_scenario_activities | ScenarioActivity | 7 | 2 | 2 | 8 | — | non | 2018-07 |  |  |
| ride_set_equipments | RideSetEquipment | 10 | 2 | 2 | 8 | — | non | 2023-02 |  |  |
| product_nature_variant_tags | ProductNatureVariantTag | 11 | 0 | 5 | 7 | — | oui | 2024-07 |  |  |
| products_yield_observations | ProductsYieldObservation *(géo)* | 5 | 0 | 3 | 7 | — | non | 2022-05 |  |  |
| sale_contract_items | SaleContractItem | 12 | 1 | 3 | 7 | — | non | 2017-11 |  |  |
| tax_declaration_item_parts | TaxDeclarationItemPart | 14 | 3 | 2 | 7 | 0 | non | 2017-04 |  |  |
| worker_group_labellings | WorkerGroupLabelling | 5 | 2 | 0 | 7 | — | non | 2022-03 |  |  |
| custom_field_choices | CustomFieldChoice | 10 | 0 | 3 | 6 | — | oui | 2015-02 |  |  |
| intervention_labellings | InterventionLabelling | 8 | 0 | 4 | 6 | 0 | non | 2016-09 |  |  |
| intervention_template_product_parameters | InterventionTemplate::ProductParameter, InterventionTemplate::Tool, InterventionTemplate::Output, InterventionTemplate::Input, InterventionTemplate::Doer *(STI)* | 13 | 4 | 0 | 6 | — | non | 2022-12 |  |  |
| product_labellings | ProductLabelling | 8 | 0 | 4 | 6 | 0 | non | 2016-09 |  |  |
| worker_group_items | WorkerGroupItem | 5 | 0 | 2 | 6 | — | non | 2022-03 |  |  |
| wine_incoming_harvests | WineIncomingHarvest | 15 | 2 | 2 | 5 | — | non | 2020-09 |  |  |
| affair_natures | AffairNature | 8 | 0 | 2 | 4 | — | oui | 2017-10 |  |  |
| financial_year_archives | FinancialYearArchive | 6 | 0 | 1 | 4 | — | oui | 2018-11 |  |  |
| pfi_intervention_parameters | PfiInterventionParameter | 11 | 3 | 0 | 4 | — | non | 2021-04 |  |  |
| saas_subscriptions | SaasSubscription | 20 | 4 | 2 | 4 | — | non | 2021-12 |  | supprimer |
| vegetative_stages | VegetativeStage | 9 | 0 | 2 | 4 | — | oui | 2022-04 |  |  |
| active_storage_attachments | ActiveStorage::Attachment | 6 | 1 | 1 | 3 | — | non | 2026-09 | uuidv7 |  |
| planning_scenario_activity_plots | ScenarioActivity::Plot | 12 | 2 | 2 | 3 | — | non | 2018-07 |  |  |
| user_tickets | UserTicket | 13 | 0 | 2 | 3 | — | oui | 2023-04 |  | supprimer |
| wice_grid_serialized_queries | WiceGridSerializedQuery | 6 | 0 | 0 | 3 | 0 | non | 2018-07 |  |  |
| economic_cash_indicators | EconomicCashIndicator | 22 | 0 | 9 | 2 | — | non | 2022-01 |  |  |
| idea_diagnostic_item_values | IdeaDiagnosticItemValue | 13 | 0 | 3 | 2 | — | non | 2021-06 |  |  |
| idea_diagnostic_items | IdeaDiagnosticItem | 12 | 0 | 3 | 2 | — | non | 2021-06 |  |  |
| issues_yield_observations | IssuesYieldObservation | 3 | 0 | 2 | 2 | — | non | 2022-04 |  |  |
| worker_contract_distributions | WorkerContractDistribution | 9 | 0 | 4 | 2 | — | non | 2022-05 |  |  |
| active_storage_blobs | ActiveStorage::Blob | 9 | 0 | 0 | 1 | — | non | 2026-09 | uuidv7 |  |
| hve_audits | HveAudit | 19 | 3 | 0 | 1 | — | non | 2026-06 |  |  |
| hve_biodiversity_items | HveBiodiversityItem | 11 | 1 | 0 | 1 | — | non | 2026-06 |  |  |
| intervention_template_activities | InterventionTemplateActivity | 5 | 2 | 0 | 1 | — | non | 2018-01 |  |  |
| planning_scenario_activity_animals | ScenarioActivity::Animal | 9 | 2 | 2 | 1 | — | non | 2023-01 |  |  |
| active_storage_variant_records | ActiveStorage::VariantRecord | 3 | 1 | 0 | 0 | — | non | 2026-09 | uuidv7 |  |
| activity_production_batches | ActivityProductionBatch | 8 | 2 | 0 | 0 | — | non | 2018-08 |  |  |
| activity_production_irregular_batches | ActivityProductionIrregularBatch | 6 | 1 | 0 | 0 | — | non | 2018-02 |  |  |
| affair_labellings | AffairLabelling | 8 | 2 | 2 | 0 | — | non | 2017-10 |  |  |
| alert_phases | AlertPhase | 9 | 1 | 2 | 0 | 0 | non | 2016-09 |  |  |
| entity_payment_methods | EntityPaymentMethod | 12 | 1 | 2 | 0 | — | non | 2021-12 |  |  |
| hve_audit_items | HveAuditItem | 14 | 1 | 0 | 0 | — | non | 2026-06 |  |  |
| hve_cmr_products | HveCmrProduct | 13 | 0 | 0 | 0 | — | non | 2026-06 |  |  |
| hve_iae_coefficients | HveIaeCoefficient | 8 | 0 | 0 | 0 | — | non | 2026-06 |  |  |
| hve_nitrogen_export_coefficients | HveNitrogenExportCoefficient | 9 | 0 | 0 | 0 | — | non | 2026-06 |  |  |
| hve_scoring_tables | HveScoringTable | 9 | 0 | 0 | 0 | — | non | 2026-06 |  |  |
| idea_diagnostic_results | IdeaDiagnosticResult | 9 | 0 | 3 | 0 | — | non | 2021-05 |  |  |
| intervention_proposal_parameters | InterventionProposal::Parameter | 10 | 3 | 1 | 0 | — | non | 2018-05 |  |  |
| project_members | ProjectMember | 9 | 2 | 2 | 0 | — | non | 2017-10 |  |  |
| qonto_inbound_invoices | Qonto::InboundInvoice | 18 | 3 | 0 | 0 | — | non | 2026-07 |  |  |
| qonto_outbound_invoices | Qonto::OutboundInvoice | 14 | 1 | 0 | 0 | — | non | 2026-07 |  |  |
| synchronization_operations | SynchronizationOperation | 14 | 0 | 4 | 0 | 0 | non | 2018-09 |  |  |
| wine_incoming_harvest_inputs | WineIncomingHarvestInput | 10 | 1 | 3 | 0 | — | non | 2020-09 |  |  |
| wine_incoming_harvest_plants | WineIncomingHarvestPlant | 10 | 1 | 3 | 0 | — | non | 2021-02 |  |  |
| wine_incoming_harvest_presses | WineIncomingHarvestPress | 12 | 2 | 2 | 0 | — | non | 2020-10 |  |  |
| wine_incoming_harvest_storages | WineIncomingHarvestStorage | 10 | 1 | 3 | 0 | — | non | 2020-09 |  |  |

### Tables qu'aucun écran ne modifie (33)

Ni contrôleur ni vue dans le backend : aucune ferme ne les édite depuis
l'application. C'est la question du référentiel partagé — si la donnée
est la même pour tous, elle a sa place dans le `lexicon` plutôt que
recopiée dans chaque ferme.

| Table | Modèle | col. | réf. | impl. | mentions | fixtures | écran | migration | clé | Décision |
|---|---|---:|---:|---:|---:|---:|---|---|---|---|
| versions | Version | 9 | 0 | 2 | 89 | 282 | non | 2018-09 |  |  |
| tokens | Token | 8 | 0 | 2 | 70 | 1 | non | 2016-09 |  |  |
| calls | Call | 12 | 0 | 3 | 42 | 9 | non | 2018-09 |  |  |
| technical_itineraries | TechnicalItinerary | 12 | 2 | 3 | 29 | — | non | 2023-02 |  |  |
| locations | Location | 10 | 0 | 3 | 24 | 6 | non | 2020-08 |  |  |
| inspection_points | InspectionPoint | 12 | 0 | 4 | 20 | 4 | non | 2016-09 | uuidv7 |  |
| intervention_costings | InterventionCosting | 10 | 0 | 2 | 20 | 23 | non | 2020-12 |  |  |
| inspection_calibrations | InspectionCalibration | 12 | 0 | 4 | 18 | 4 | non | 2016-09 | uuidv7 |  |
| analytic_segments | AnalyticSegment | 6 | 1 | 0 | 15 | — | non | 2021-02 |  |  |
| contract_items | ContractItem | 11 | 0 | 4 | 15 | 2 | non | 2017-11 |  |  |
| parcel_item_storings | ParcelItemStoring | 12 | 2 | 4 | 15 | 24 | non | 2021-03 |  |  |
| intervention_working_periods | InterventionWorkingPeriod | 12 | 2 | 2 | 11 | 23 | non | 2021-05 | uuidv7 |  |
| product_enjoyments | ProductEnjoyment | 14 | 0 | 6 | 10 | 126 | non | 2018-09 |  |  |
| product_nature_category_taxations | ProductNatureCategoryTaxation | 9 | 0 | 4 | 10 | 5 | non | 2015-02 |  |  |
| incoming_harvest_crops | IncomingHarvestCrop | 10 | 1 | 4 | 8 | 2 | non | 2023-06 |  |  |
| crop_group_labellings | CropGroupLabelling | 8 | 2 | 2 | 7 | 2 | non | 2021-03 |  |  |
| intervention_crop_groups | InterventionCropGroup | 8 | 2 | 2 | 6 | 2 | non | 2021-02 |  |  |
| crop_group_items | CropGroupItem | 9 | 1 | 3 | 5 | 2 | non | 2021-03 |  |  |
| product_movements | ProductMovement | 15 | 0 | 5 | 5 | 186 | non | 2020-03 |  |  |
| incoming_harvest_storages | IncomingHarvestStorage | 11 | 1 | 4 | 4 | 2 | non | 2023-06 |  |  |
| plant_counting_items | PlantCountingItem | 8 | 0 | 3 | 3 | 6 | non | 2016-04 | uuidv7 |  |
| cvi_cadastral_plant_cvi_land_parcels | CviCadastralPlantCviLandParcel | 9 | 2 | 2 | 2 | 2 | non | 2020-08 |  |  |
| idea_diagnostics | IdeaDiagnostic | 12 | 1 | 3 | 2 | 1 | non | 2021-06 |  |  |
| naming_format_fields | NamingFormatField, NamingFormatFieldLandParcel *(STI)* | 10 | 0 | 3 | 2 | 3 | non | 2018-09 |  |  |
| gap_items | GapItem | 11 | 0 | 4 | 1 | 6 | non | 2016-11 |  |  |
| guide_analysis_points | GuideAnalysisPoint | 10 | 0 | 3 | 1 | 2 | non | 2015-02 |  |  |
| product_links | ProductLink | 14 | 0 | 6 | 1 | 2 | non | 2018-09 |  |  |
| activity_inspection_calibration_natures | ActivityInspectionCalibrationNature | 10 | 0 | 3 | 0 | 4 | non | 2016-05 |  |  |
| activity_inspection_calibration_scales | ActivityInspectionCalibrationScale | 9 | 0 | 3 | 0 | 1 | non | 2016-05 |  |  |
| cash_sessions | CashSession | 14 | 0 | 3 | 0 | 2 | non | 2015-05 |  |  |
| delivery_tools | DeliveryTool | 8 | 0 | 4 | 0 | 2 | non | 2016-02 |  |  |
| intervention_parameter_settings | InterventionParameterSetting | 10 | 2 | 2 | 0 | 1 | non | 2022-05 |  |  |
| supervision_items | SupervisionItem | 9 | 0 | 4 | 0 | 2 | non | 2016-02 |  |  |

### Le reste (146)

Rien ne les signale. Ne rien écrire vaut « conserver au plan de
données ».

| Table | Modèle | col. | réf. | impl. | mentions | fixtures | écran | migration | clé | Décision |
|---|---|---:|---:|---:|---:|---:|---|---|---|---|
| products | Product, Worker, Zone, ProductGroup, Matter, Easement, SubZone, Settlement, LandParcel, BuildingDivision, EquipmentFleet, Building, AnimalGroup, Equipment, Bioproduct, Fungus, Animal, Plant *(STI)* *(géo)* | 69 | 4 | 19 | 1963 | 144 | oui | 2026-09 | uuidv7 |  |
| interventions | Intervention | 41 | 2 | 10 | 1067 | 21 | oui | 2026-06 | uuidv7 |  |
| product_nature_variants | ProductNatureVariant, Variants::ZoneVariant, Variants::WorkerVariant, Variants::ServiceVariant, Variants::EquipmentVariant, Variants::CropVariant, Variants::ArticleVariant, Variants::AnimalVariant, Variants::Equipments::TrailedEquipmentEquipment, Variants::Equipments::ToolEquipment, Variants::Equipments::MotorizedEquipmentEquipment, Variants::Equipments::FixedEquipmentEquipment, Variants::Articles::SeedAndPlantArticle, Variants::Articles::PlantMedicineArticle, Variants::Articles::FertilizerArticle, Variants::Articles::FarmProductArticle *(STI)* | 30 | 1 | 6 | 947 | 74 | oui | 2026-09 |  |  |
| accounts | Account | 22 | 0 | 2 | 768 | 336 | oui | 2023-06 |  |  |
| entities | Entity | 54 | 1 | 9 | 631 | 19 | oui | 2026-09 |  |  |
| sales | Sale | 48 | 0 | 15 | 578 | 19 | oui | 2024-11 |  |  |
| parcels | Parcel, Reception, Shipment *(STI)* | 41 | 2 | 14 | 492 | 25 | oui | 2022-02 |  |  |
| purchases | Purchase, PurchaseOrder, PurchaseInvoice *(STI)* | 35 | 0 | 11 | 479 | 11 | oui | 2022-04 |  |  |
| activities | Activity | 40 | 0 | 2 | 452 | 22 | oui | 2023-01 |  |  |
| journals | Journal | 22 | 2 | 2 | 430 | 14 | oui | 2021-02 |  |  |
| journal_entry_items | JournalEntryItem | 52 | 2 | 14 | 424 | 811 | oui | 2023-11 |  |  |
| imports | Import | 12 | 0 | 3 | 414 | 2 | oui | 2026-09 |  |  |
| taxes | Tax | 24 | 0 | 7 | 369 | 6 | oui | 2022-08 |  |  |
| preferences | Preference | 15 | 0 | 4 | 355 | 452 | oui | 2023-06 |  |  |
| journal_entries | JournalEntry | 33 | 1 | 5 | 308 | 250 | oui | 2021-02 |  |  |
| documents | Document | 21 | 0 | 3 | 307 | 13 | oui | 2026-09 | uuidv7 |  |
| campaigns | Campaign | 11 | 0 | 2 | 299 | 8 | oui | 2021-06 |  |  |
| units | Unit, ReferenceUnit, Conditioning *(STI)* | 16 | 0 | 3 | 298 | 6 | oui | 2023-02 |  | lexicon |
| product_natures | ProductNature, VariantTypes::ZoneType, VariantTypes::WorkerType, VariantTypes::ServiceType, VariantTypes::EquipmentType, VariantTypes::CropType, VariantTypes::ArticleType, VariantTypes::AnimalType *(STI)* | 29 | 0 | 3 | 291 | 61 | oui | 2026-09 |  |  |
| financial_years | FinancialYear | 21 | 2 | 3 | 274 | 29 | oui | 2023-06 |  |  |
| product_nature_categories | ProductNatureCategory, VariantCategories::ZoneCategory, VariantCategories::WorkerCategory, VariantCategories::ServiceCategory, VariantCategories::EquipmentCategory, VariantCategories::CropCategory, VariantCategories::ArticleCategory, VariantCategories::AnimalCategory *(STI)* | 32 | 0 | 9 | 262 | 26 | oui | 2021-02 |  |  |
| labels | Label | 8 | 0 | 2 | 261 | 3 | oui | 2018-07 |  |  |
| users | User | 48 | 0 | 6 | 228 | 4 | oui | 2026-06 |  |  |
| activity_productions | ActivityProduction *(géo)* | 38 | 1 | 8 | 227 | 43 | oui | 2024-02 | uuidv7 |  |
| affairs | Affair, PurchaseAffair, PayslipAffair, SaleAffair, SaleTicket, SaleOpportunity *(STI)* | 29 | 2 | 6 | 201 | 40 | oui | 2019-10 |  |  |
| subscriptions | Subscription | 25 | 0 | 7 | 196 | 5 | oui | 2021-12 |  |  |
| issues | Issue *(géo)* | 20 | 1 | 4 | 195 | 6 | oui | 2026-09 | uuidv7 |  |
| notifications | Notification | 14 | 0 | 4 | 195 | 4 | oui | 2018-09 |  |  |
| cashes | Cash | 32 | 0 | 7 | 188 | 3 | oui | 2021-02 |  |  |
| inspections | Inspection | 18 | 0 | 4 | 175 | 2 | oui | 2018-07 | uuidv7 |  |
| custom_fields | CustomField | 17 | 0 | 2 | 166 | — | oui | 2024-04 |  |  |
| fixed_assets | FixedAsset | 49 | 1 | 18 | 166 | 2 | oui | 2022-06 |  |  |
| analyses | Analysis *(géo)* | 24 | 1 | 7 | 161 | 49 | oui | 2021-12 | uuidv7 |  |
| deliveries | Delivery | 18 | 0 | 6 | 160 | 16 | oui | 2016-02 |  |  |
| events | Event | 17 | 0 | 3 | 151 | 48 | oui | 2026-07 |  |  |
| incoming_payments | IncomingPayment | 33 | 0 | 10 | 150 | 10 | oui | 2024-03 |  |  |
| loans | Loan | 36 | 1 | 9 | 150 | 4 | oui | 2021-02 |  |  |
| cultivable_zones | CultivableZone *(géo)* | 18 | 0 | 4 | 142 | 39 | oui | 2021-12 | uuidv7 |  |
| payslips | Payslip | 28 | 5 | 2 | 140 | 3 | oui | 2023-10 |  |  |
| tasks | Task | 15 | 0 | 5 | 136 | 3 | oui | 2018-01 | uuidv7 |  |
| contracts | Contract | 17 | 0 | 4 | 132 | 2 | oui | 2022-05 |  |  |
| bank_statements | BankStatement | 18 | 0 | 4 | 125 | 6 | oui | 2016-12 |  |  |
| gaps | Gap, SaleGap, PurchaseGap *(STI)* | 17 | 0 | 5 | 124 | 6 | oui | 2019-10 |  |  |
| intervention_parameters | InterventionParameter, InterventionGroupParameter, InterventionProductParameter, InterventionTarget, InterventionOutput, InterventionInput, InterventionAgent, InterventionTool, InterventionDoer *(STI)* *(géo)* | 44 | 0 | 13 | 123 | 108 | non | 2026-06 | uuidv7 |  |
| sensors | Sensor | 21 | 0 | 4 | 121 | 12 | oui | 2016-09 |  |  |
| deposits | Deposit | 17 | 0 | 6 | 112 | 2 | oui | 2016-02 |  |  |
| attachments | Attachment | 13 | 0 | 5 | 108 | 4 | oui | 2026-09 | uuidv7 |  |
| outgoing_payments | OutgoingPayment, PayslipPayment, PayslipContributionPayment, PurchasePayment *(STI)* | 28 | 4 | 6 | 105 | 12 | oui | 2024-03 |  |  |
| catalogs | Catalog | 14 | 0 | 2 | 102 | 6 | oui | 2021-12 |  |  |
| purchase_items | PurchaseItem | 35 | 2 | 13 | 101 | 12 | non | 2022-04 |  |  |
| inventories | Inventory | 20 | 2 | 5 | 100 | 2 | oui | 2019-08 |  |  |
| identifiers | Identifier | 9 | 0 | 3 | 99 | 6 | oui | 2016-02 |  |  |
| sale_items | SaleItem | 37 | 2 | 13 | 97 | 22 | non | 2022-03 |  |  |
| catalog_items | CatalogItem | 23 | 1 | 8 | 96 | 23 | oui | 2022-03 |  |  |
| document_templates | DocumentTemplate | 16 | 0 | 2 | 96 | 26 | oui | 2023-06 |  |  |
| projects | Project | 17 | 2 | 4 | 92 | — | oui | 2018-01 |  |  |
| sale_natures | SaleNature | 22 | 0 | 5 | 92 | 2 | oui | 2022-02 |  |  |
| rides | Ride *(géo)* | 25 | 4 | 2 | 87 | 2 | oui | 2022-12 |  |  |
| roles | Role | 9 | 0 | 2 | 83 | 2 | oui | 2016-02 |  |  |
| trackings | Tracking | 14 | 0 | 4 | 81 | 3 | oui | 2016-02 | uuidv7 |  |
| plant_countings | PlantCounting | 16 | 0 | 5 | 79 | 2 | oui | 2016-11 | uuidv7 |  |
| tax_declarations | TaxDeclaration | 19 | 0 | 5 | 78 | 5 | oui | 2019-10 |  |  |
| observations | Observation | 12 | 0 | 4 | 77 | 5 | oui | 2022-06 | uuidv7 |  |
| crumbs | Crumb *(géo)* | 17 | 2 | 4 | 76 | 59 | oui | 2021-03 | uuidv7 |  |
| prescriptions | Prescription | 11 | 0 | 3 | 74 | 2 | oui | 2016-02 |  |  |
| teams | Team | 13 | 0 | 3 | 74 | 2 | oui | 2021-03 |  |  |
| activity_budgets | ActivityBudget | 11 | 1 | 4 | 72 | 3 | oui | 2021-12 |  |  |
| dashboards | Dashboard | 9 | 0 | 3 | 71 | 2 | oui | 2016-02 |  |  |
| incoming_payment_modes | IncomingPaymentMode | 20 | 0 | 6 | 71 | 3 | oui | 2022-10 |  |  |
| associates | Associate | 16 | 0 | 4 | 69 | 3 | oui | 2024-04 |  |  |
| integrations | Integration | 12 | 0 | 2 | 69 | 0 | oui | 2021-01 |  |  |
| listings | Listing | 14 | 0 | 2 | 69 | 2 | oui | 2018-09 |  |  |
| parcel_items | ParcelItem, ReceptionItem, ShipmentItem *(STI)* *(géo)* | 44 | 7 | 16 | 68 | 32 | non | 2022-02 |  |  |
| outgoing_payment_modes | OutgoingPaymentMode | 12 | 0 | 3 | 64 | 3 | oui | 2017-04 |  |  |
| bank_statement_items | BankStatementItem | 21 | 0 | 5 | 63 | 24 | oui | 2023-11 |  |  |
| georeadings | Georeading *(géo)* | 11 | 0 | 2 | 61 | 3 | oui | 2016-02 | uuidv7 |  |
| purchase_natures | PurchaseNature | 11 | 0 | 3 | 61 | 2 | oui | 2019-10 |  |  |
| cap_land_parcels | CapLandParcel *(géo)* | 14 | 0 | 4 | 60 | 31 | oui | 2016-02 | uuidv7 |  |
| cap_islets | CapIslet *(géo)* | 10 | 0 | 3 | 58 | 26 | oui | 2016-02 | uuidv7 |  |
| map_layers | MapLayer | 20 | 0 | 2 | 58 | 36 | oui | 2019-06 |  |  |
| sequences | Sequence | 16 | 0 | 2 | 56 | 34 | oui | 2021-02 |  |  |
| cap_statements | CapStatement | 11 | 0 | 4 | 54 | 2 | oui | 2016-02 |  |  |
| guides | Guide | 12 | 0 | 2 | 54 | 2 | oui | 2026-09 |  |  |
| cash_transfers | CashTransfer | 20 | 0 | 6 | 52 | 2 | oui | 2016-02 |  |  |
| financial_year_exchanges | FinancialYearExchange | 15 | 1 | 2 | 50 | 1 | oui | 2026-09 |  |  |
| incoming_harvests | IncomingHarvest | 19 | 2 | 6 | 50 | 2 | oui | 2023-06 | uuidv7 |  |
| entity_links | EntityLink | 16 | 0 | 4 | 49 | 8 | oui | 2016-11 |  |  |
| net_services | NetService | 7 | 0 | 2 | 48 | 3 | oui | 2016-02 |  |  |
| intervention_participations | InterventionParticipation | 11 | 2 | 2 | 47 | 3 | oui | 2020-10 | uuidv7 |  |
| payslip_natures | PayslipNature | 14 | 2 | 2 | 46 | 2 | oui | 2023-10 |  |  |
| supervisions | Supervision | 10 | 0 | 2 | 46 | 2 | oui | 2016-02 |  |  |
| postal_zones | PostalZone | 13 | 0 | 3 | 45 | 13 | oui | 2016-02 |  |  lexicon |
| subscription_natures | SubscriptionNature | 8 | 0 | 2 | 45 | 3 | oui | 2016-05 |  |  |
| crop_groups | CropGroup | 8 | 0 | 2 | 44 | 2 | oui | 2021-03 |  |  |
| outgoing_payment_lists | OutgoingPaymentList | 10 | 0 | 3 | 42 | 2 | oui | 2017-04 |  |  |
| listing_nodes | ListingNode | 25 | 0 | 6 | 40 | 5 | oui | 2015-02 |  |  |
| product_readings | ProductReading *(géo)* | 24 | 0 | 4 | 40 | 228 | oui | 2022-05 | uuidv7 |  |
| project_budgets | ProjectBudget | 9 | 0 | 2 | 39 | 3 | oui | 2021-03 |  |  |
| districts | District | 8 | 0 | 2 | 37 | 2 | oui | 2016-02 |  | lexicon |
| manure_management_plans | ManureManagementPlan | 14 | 0 | 4 | 37 | — | oui | 2015-02 |  |  |
| naming_formats | NamingFormat, NamingFormatLandParcel *(STI)* | 8 | 0 | 2 | 37 | 1 | oui | 2018-09 |  |  |
| plant_density_abaci | PlantDensityAbacus | 11 | 0 | 3 | 35 | 2 | oui | 2016-07 |  |  |
| fixed_asset_depreciations | FixedAssetDepreciation | 18 | 0 | 5 | 34 | 42 | oui | 2019-06 |  |  |
| entity_addresses | EntityAddress *(géo)* | 25 | 0 | 4 | 33 | 18 | oui | 2017-10 |  |  |
| product_localizations | ProductLocalization | 14 | 0 | 6 | 31 | 187 | oui | 2018-09 |  |  |
| worker_time_logs | WorkerTimeLog | 16 | 1 | 3 | 31 | 1 | oui | 2023-08 | uuidv7 |  |
| debt_transfers | DebtTransfer | 14 | 0 | 5 | 30 | 0 | oui | 2017-04 |  |  |
| worker_groups | WorkerGroup | 10 | 0 | 2 | 29 | 1 | oui | 2022-03 |  |  |
| worker_contracts | WorkerContract | 19 | 1 | 2 | 28 | 2 | oui | 2022-05 |  |  |
| analysis_items | AnalysisItem *(géo)* | 23 | 0 | 4 | 27 | 77 | oui | 2016-02 | uuidv7 |  |
| cap_neutral_areas | CapNeutralArea *(géo)* | 11 | 1 | 2 | 26 | 0 | non | 2018-04 | uuidv7 |  |
| loan_repayments | LoanRepayment | 18 | 0 | 4 | 26 | 243 | oui | 2017-03 |  |  |
| product_memberships | ProductMembership | 14 | 0 | 6 | 26 | 1 | oui | 2021-06 |  |  |
| regularizations | Regularization | 9 | 2 | 2 | 26 | 2 | oui | 2017-04 |  |  |
| tax_payments | TaxPayment | 17 | 0 | 5 | 26 | 2 | oui | 2024-03 |  |  |
| guide_analyses | GuideAnalysis | 12 | 0 | 3 | 24 | 3 | oui | 2015-02 |  |  |
| intervention_templates | InterventionTemplate | 17 | 1 | 3 | 24 | — | non | 2022-06 |  |  |
| yield_observations | YieldObservation *(géo)* | 13 | 0 | 4 | 22 | — | oui | 2022-06 | uuidv7 |  |
| event_participations | EventParticipation | 9 | 0 | 4 | 21 | 67 | oui | 2016-02 |  |  |
| analytic_sequences | AnalyticSequence | 3 | 0 | 0 | 20 | — | oui | 2021-02 |  |  |
| issue_natures | IssueNature | 4 | 0 | 0 | 20 | — | oui | 2022-04 |  |  |
| project_tasks | ProjectTask | 17 | 2 | 3 | 20 | — | oui | 2018-01 |  |  |
| ride_sets | RideSet *(géo)* | 20 | 0 | 2 | 20 | 2 | oui | 2022-05 | uuidv7 |  |
| account_balances | AccountBalance | 17 | 0 | 4 | 19 | 2 | oui | 2017-03 |  |  |
| plant_density_abacus_items | PlantDensityAbacusItem | 9 | 0 | 3 | 18 | 6 | oui | 2016-04 |  |  |
| tax_declaration_items | TaxDeclarationItem | 19 | 0 | 4 | 18 | 30 | non | 2016-11 |  |  |
| sale_contracts | SaleContract | 19 | 0 | 6 | 17 | 1 | oui | 2017-10 |  |  |
| activity_budget_items | ActivityBudgetItem | 35 | 4 | 4 | 16 | 5 | non | 2022-07 |  |  |
| email_templates | EmailTemplate | 17 | 0 | 2 | 15 | — | oui | 2024-11 |  |  |
| inventory_items | InventoryItem | 13 | 0 | 5 | 15 | 2 | oui | 2017-04 | uuidv7 |  |
| product_nature_variant_components | ProductNatureVariantComponent | 11 | 0 | 5 | 14 | 3 | oui | 2016-07 |  |  |
| activity_seasons | ActivitySeason | 8 | 0 | 3 | 12 | 5 | oui | 2016-07 |  |  |
| product_phases | ProductPhase | 15 | 0 | 8 | 11 | 120 | oui | 2018-09 |  |  |
| activity_inspection_point_natures | ActivityInspectionPointNature | 9 | 0 | 3 | 10 | 4 | oui | 2016-05 |  |  |
| product_ownerships | ProductOwnership | 14 | 0 | 6 | 10 | 127 | oui | 2018-09 |  |  |
| call_messages | CallMessage, CallResponse, CallRequest *(STI)* | 18 | 0 | 4 | 9 | 42 | non | 2018-09 |  |  |
| cvi_land_parcels | CviLandParcel *(géo)* | 24 | 2 | 3 | 8 | 2 | non | 2021-03 | uuidv7 |  |
| cvi_cadastral_plants | CviCadastralPlant | 26 | 2 | 3 | 6 | 4 | non | 2020-08 | uuidv7 |  |
| cvi_cultivable_zones | CviCultivableZone *(géo)* | 14 | 1 | 2 | 6 | 2 | non | 2021-03 | uuidv7 |  |
| activity_tactics | ActivityTactic | 16 | 1 | 4 | 4 | 2 | non | 2021-10 |  |  |
| cvi_statements | CviStatement | 17 | 1 | 2 | 4 | 2 | non | 2020-08 | uuidv7 |  |
| sale_contract_natures | SaleContractNature | 9 | 0 | 2 | 3 | 1 | oui | 2017-10 |  |  |
| listing_node_items | ListingNodeItem | 9 | 0 | 3 | 1 | 2 | oui | 2015-02 |  |  |
| intervention_parameter_readings | InterventionParameterReading *(géo)* | 21 | 0 | 3 | 0 | 14 | non | 2016-02 | uuidv7 |  |
| intervention_setting_items | InterventionSettingItem *(géo)* | 21 | 2 | 2 | 0 | 2 | non | 2022-03 | uuidv7 |  |
| product_nature_variant_readings | ProductNatureVariantReading *(géo)* | 21 | 0 | 3 | 0 | 78 | non | 2021-11 |  |  |

