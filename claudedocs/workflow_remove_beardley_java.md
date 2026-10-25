# Workflow — Suppression Beardley/JAVA & migration des rapports XML → ODT

> **Statut** : Plan d'implémentation (aucune modification de code dans ce document)
> **Auteur** : Claude Code · 2026-05-31 (v2 après audit vues backend)
> **Branche cible** : `5.0-beta`
> **Objectif** : retirer `beardley`, `rjb` et la JVM du runtime Ekylibre en migrant les rapports résiduels vers la pipeline ODT (`odf-report` + LibreOffice headless).
> **Étape suivante** : `/sc:implement claudedocs/workflow_remove_beardley_java.md` ou exécution phase par phase.

---

## 1. TL;DR (révisé après audit des vues)

- **9 gems beardley** + `rjb` + `rjb-loader` + dépendance JVM au démarrage (`config/initializers/beardley.rb`).
- **Le verrou architectural est `lib/reporting.rb`** : il enregistre un renderer `format.pdf` (et `.odt/.ods/.docx/.xlsx`) global qui appelle systématiquement `template.export()` → Beardley, et monkey-patch `ActionController::Responder` pour intercepter tous les `respond_with(@resource)` sans `format.pdf` explicite.
- **Conséquence majeure** : toute vue contenant `t.export(:nature)` dont le contrôleur ne définit pas de `format.pdf` ODT-natif tombe **silencieusement** sur Beardley. La classification initiale "templates morts" était fausse.
- **Reclassement après audit `app/views/backend/`** :
  - 🟢 **1 mort confirmé** : `matter.xml` (aucune vue, aucun agrégateur).
  - 🔴 **15 vivants via UI/Aggeratio** : nécessitent un Printer + template ODT.
  - 🟠 **2 mixtes** : `account_journal_entry_sheet` et `outgoing_payment_list__*` (chemin ODT existe pour `format.odt`, mais `format.pdf` reste Beardley).
- **Aucune dépendance LibreOffice ne disparaît** — `soffice` reste nécessaire pour la conversion ODT → PDF (`lib/ekylibre/document_management/pdf_converter.rb:30-34`).
- **Gain attendu** : suppression d'environ 200–300 Mo d'images Docker (JRE + JARs Beardley), suppression de RJB (compilation JNI à `bundle install`), suppression d'une classe entière de bugs (segfaults JVM, fuites mémoire RJB).
- **Effort total estimé** : 15–25 jours-homme (vs 7–10 dans la v1) en raison du périmètre découvert.

---

## 2. Inventaire — dépendances à supprimer

### 2.1 Gems (Gemfile / Gemfile.lock)

| Gem | Version verrouillée | Rôle |
|---|---|---|
| `beardley` | 1.4.2 | Coeur — wrap JasperReports via RJB |
| `beardley-barcode` | 1.0.1 | Codes-barres dans rapports |
| `beardley-batik` | 1.0.1 | SVG (Apache Batik) |
| `beardley-charts` | 0.0.1 | Graphiques JFreeChart |
| `beardley-groovy` | 2.0.1 | Scripts d'expressions Jasper |
| `beardley-open_sans` | 0.1.0 | Police bundled |
| `beardley-xml` | 1.1.2 | Datasource XML |
| `rjb` | 1.6.2 | Ruby ↔ Java bridge (JNI) |
| `rjb-loader` | 0.0.2 | Configuration du classpath JVM |

### 2.2 Initializer & runtime

- `config/initializers/beardley.rb` : charge RJB, ajoute `config/reporting/beardley/` et les polices au classpath JVM. Désactivable via `DISABLE_JAVA=1`.
- `config/reporting/beardley/` : dossier de JARs/ressources Java embarquées (à vérifier puis supprimer).
- Image Docker (`ghcr.io/ekylibre/docker-base-images/ruby2.6`) : embarque actuellement un JRE et les libs natives requises par RJB.

### 2.3 Code applicatif (à nettoyer)

- **`lib/reporting.rb`** (✨ verrou architectural — voir section 3) : enregistre les renderers globaux et patche le Responder. Doit être **réécrit avant** toute suppression de Beardley.
- `app/models/document_template.rb:139-170` — méthodes `#print` et `#export` utilisant `Beardley::Report`.
- `app/models/document_template.rb:307-354` — `import_jasper`, parsing/nettoyage du XML Jasper + suppression du `.jasper` compilé.
- `app/models/document_template.rb:236-257` — `template_fallbacks` (déjà `deprecated`) qui empile `.xml`/`.jrxml`.
- `lib/ekylibre/document_management/template_file_provider.rb:54-62` — fallback `jasper_paths` à retirer.
- `lib/aggeratio/` + `config/aggregators/*.xml` — module entier devenu obsolète après réécriture Groupe B.
- `app/jobs/export_job.rb:23` — seul appelant runtime restant de `template.export` (via Aggeratio).

---

## 3. Verrou architectural — `lib/reporting.rb`

```ruby
# lib/reporting.rb (état actuel)
Ekylibre::Reporting.formats.each do |format|              # [:pdf, :odt, :ods, :docx, :xlsx]
  ActionController::Renderers.add(format) do |object, options|
    template = DocumentTemplate.find_active_template(options[:with])
    path = template.export(object.to_xml(options), options[:key], format, options)  # ← Beardley
    send_file(path, ...)
  end
end

module ActionController
  class Responder
    Ekylibre::Reporting.formats.each do |format|
      define_method :"to_#{format}" do
        controller.render(options.merge("#{format}": resource))      # ← intercepte respond_with
      end
    end
  end
end
```

**Effets** :

1. N'importe quel contrôleur faisant `respond_with(@resource)` répond automatiquement aux formats `pdf/odt/ods/docx/xlsx` via Beardley, **sans bloc `format.pdf` explicite**.
2. L'helper `t.export(:nature)` (`app/helpers/toolbar_helper.rb:34-54`) génère un menu dont chaque item pointe vers `params.merge(format: :pdf, template: <id>, key: <num>)` — ce qui déclenche exactement ce chemin.
3. Les contrôleurs qui ont migré (`sales`, `tax_declarations`, `accounts`, etc.) interceptent **manuellement** `format.pdf`/`format.odt` avec `Printers::*` + `DocumentGenerator`. Les autres tombent sur Beardley.

**Décision architecturale** : avant toute suppression de gem, `lib/reporting.rb` doit être réécrit pour router vers `DocumentGenerator.generate_pdf(template, printer)` via un **registry `Onoma::DocumentNature → Printers::*`**. Toute nature absente du registry lève une exception explicite — ce qui révèle mécaniquement, en CI et en exploration manuelle, la liste exhaustive des rapports encore vivants.

---

## 4. Inventaire — rapports XML/JRXML

### 4.1 Vue globale (61 fichiers, 2 locales)

| Format | eng | fra | Total |
|---|---|---|---|
| `.odt` | 0 | 43 | 43 |
| `.jrxml` | 1 | 9 | 10 |
| `.xml` (Jasper) | 0 | 8 | 8 |

### 4.2 Classification — corrigée après audit des vues `app/views/backend/`

#### 🟢 Groupe A — Morts (suppression sèche)

**1 seul fichier confirmé**.

| Fichier | Indicateur |
|---|---|
| `fra/reporting/matter.xml` | Aucune vue ne fait `t.export(:matter)` ; aucun `config/aggregators/matter.xml` ; les occurrences du mot `matter` dans le code désignent des objets métier `Matter` (modèle `app/models/matter.rb`), pas un rapport |

#### 🔴 Groupe B — Vivants via UI (renderer global → Beardley)

**13 fichiers, 9 contrôleurs concernés**. Toolbar `t.export(:nature)` dans la vue → contrôleur sans `format.pdf` ODT → renderer global de `lib/reporting.rb` → `template.export()` → Beardley.

| Nature | Template XML/JRXML | Vue déclencheuse | Contrôleur à migrer |
|---|---|---|---|
| `animal_list` | `fra/.../animal_list.xml` | `views/backend/animals/index.html.haml:2` | `animals_controller.rb` |
| `animal_sheet` | `fra/.../animal_sheet.xml` | `views/backend/animals/show.html.haml:4` | `animals_controller.rb` |
| `deposit_list` | `fra/.../deposit_list.xml` | `views/backend/deposits/show.html.haml:2` | `deposits_controller.rb` |
| `cultivable_zone_sheet` | `fra/.../cultivable_zone_sheet.jrxml` | `views/backend/cultivable_zones/show.html.haml:3` | `cultivable_zones_controller.rb` |
| `outgoing_delivery_docket` | `fra/.../outgoing_delivery_docket.jrxml` | `views/backend/deliveries/show.html.haml:2` | `deliveries_controller.rb` |
| `journal_entry_sheet` | `fra/.../journal_entry_sheet.jrxml` | `views/backend/journal_entries/show.html.haml:4` | `journal_entries_controller.rb` |
| `purchases_invoice` | `fra/.../purchases_invoice.jrxml` | `views/backend/purchase_invoices/show.html.haml:5` | `purchase_invoices_controller.rb` |
| `entity_sheet` | (pas de JRXML dans le repo, template DB) | `views/backend/entities/show.html.haml:4` | `entities_controller.rb` |
| `products_sheet` | (pas de JRXML dans le repo, template DB) | `views/backend/products/index.html.haml:3` | `products_controller.rb` |
| `manure_management_plan_sheet` | (pas de JRXML dans le repo, template DB) | `views/backend/manure_management_plans/show.html.haml:3` | `manure_management_plans_controller.rb` |
| `sale` (eng, fallback) | `eng/.../sale.jrxml` | `views/backend/sales/show.html.haml` (fallback locale) | `sales_controller.rb` (déjà partiellement migré, ligne 100 `render pdf: @sales, with: params[:template]` traverse le renderer global) |

#### 🔴 Groupe B-bis — Vivants via Aggeratio / ExportJob

**2 fichiers**. Branchés sur `app/jobs/export_job.rb:23` (`template.export(aggregator.to_xml, ...)`). Déclenchement UI : page `/backend/exports`.

| Nature | Template | Agrégateur | Valeur réglementaire |
|---|---|---|---|
| `veterinary_booklet` | `fra/.../veterinary_booklet.jrxml` | `config/aggregators/veterinary_booklet.xml` | Carnet vétérinaire FR — Code Rural |
| `animal_husbandry_register` | `fra/.../animal_husbandry_register.xml` | `config/aggregators/animal_husbandry_register.xml` | Registre d'élevage FR — Code Rural |

> ⚠️ Forte valeur réglementaire FR. Toute régression bloque la production agricole. Tests de non-régression visuels obligatoires.

#### 🟠 Groupe C — Mixtes (chemin ODT partiel)

**3 fichiers**. Le contrôleur a un bloc explicite pour `format.odt` (ODT-natif via `Printers::*`), mais `format.pdf` continue de passer par le renderer global → Beardley.

| Nature | Vue / Contrôleur | État ODT | État PDF |
|---|---|---|---|
| `account_journal_entry_sheet` | `accounts_controller.rb:80-87` | ✅ `Printers::AccountJournalEntrySheetPrinter` + `account_journal_entry_sheet.odt` | ❌ Tombe sur `account_journal_entry_sheet.jrxml` via renderer global |
| `outgoing_payment_list__standard` | `outgoing_payment_lists_controller.rb:56` | ✅ `DocumentGenerator` pour le chemin actuel | ❌ Le bouton toolbar `t.export(:nature)` génère `format: :pdf` → renderer global → JRXML |
| `outgoing_payment_list__check_letter` | idem | idem | idem |

#### 🟠 Groupe D — Aggregators cachés de l'UI

**4 fichiers**. Listés dans `HIDDEN_AGGREGATORS` (`exports_controller.rb:24-27`) — masqués du menu Exports mais leurs définitions agrégateur + template Jasper sont toujours chargées. Statut runtime à confirmer en phase 0.

- `fr_pcg82_balance_sheet.jrxml` (référencé comme constante dans `app/services/printers/balance_sheet_printer.rb:9` → vérifier si printer le sélectionne réellement)
- `fr_pcg82_profit_and_loss_statement.jrxml`
- `fr_pcga_balance_sheet.jrxml` (constante `AGRI_PCG` ligne 8)
- `fr_pcga_profit_and_loss_statement.jrxml`

#### 📊 Synthèse 18 fichiers

| Groupe | Nb fichiers | Action |
|---|---|---|
| A — Morts | 1 | `rm` direct |
| B — UI via renderer global | 13 (dont 6 sans template repo, en DB seulement) | Créer Printer + ODT + `format.pdf` explicite |
| B-bis — Aggeratio | 2 | Réécrire en Printer + ODT, supprimer agrégateur |
| C — Mixtes | 3 | Couvrir le chemin `format.pdf` via Printer + supprimer JRXML |
| D — Cachés (statut indéterminé) | 4 | Audit phase 0 → soit suppression soit migration |

---

## 5. Architecture cible

```
┌────────────────┐  format.pdf/.odt  ┌────────────────────────────┐
│  Controller    │ ────────────────▶ │ Ekylibre::Reporting        │
│  respond_with  │                   │  .render(nature, resource) │  ← réécriture lib/reporting.rb
└────────────────┘                   └────────────────────────────┘
                                                  │ resolve printer via registry
                                                  ▼
                                   ┌──────────────────────────────┐
                                   │ Printers::<Nature>Printer    │
                                   └──────────────────────────────┘
                                                  │ generate(report)
                                                  ▼
                                   ┌──────────────────────────────┐
                                   │ ODFReport::Report (odf-report)│
                                   │  template = .odt              │
                                   └──────────────────────────────┘
                                                  │ ODT bytes
                                                  ▼
                                   ┌──────────────────────────────┐
                                   │ PdfConverter (soffice headless)│
                                   └──────────────────────────────┘
                                                  │ PDF bytes
                                                  ▼
                                          Document
```

**Disparaissent** : `Beardley::Report`, JVM, RJB, fallback `.xml/.jrxml` dans `TemplateFileProvider`, `DocumentTemplate#print/#export/#import_jasper`, `Aggeratio`, le monkey-patch `ActionController::Responder`.

**Subsistent** : `odf-report` (fork ekylibre), `soffice` headless, `Printers::*`, `DocumentGenerator`, `SignatureManager`.

---

## 6. Découpage en phases

### Phase 0 — Pré-requis & garde-fous (1–2 j)

| Tâche | Livrable | Risque/mitigation |
|---|---|---|
| Activer `DISABLE_JAVA=1` en staging et lancer tous les flux d'impression de la matrice section 4.2 | Liste des écrans qui crashent / retournent 500 | Permet de cartographier exhaustivement les appels Beardley non documentés |
| Snapshot des PDF produits actuellement pour **toutes** les natures Groupe B + B-bis sur un tenant de référence (`demo`, jeu de données réel) | Dossier `tmp/golden/` versionné hors git (S3) | Référence visuelle pour tests de non-régression Phase 3 |
| Ajouter une métrique Sidekiq + log structuré sur `ExportJob` ET sur le renderer `lib/reporting.rb` (compte d'appels par nature, durée, succès/échec) sur 2–4 semaines avant Phase 0bis | CSV : volume réel par nature | Évite de réécrire un rapport jamais déclenché ; valide ou invalide Groupe D |
| Audit prod : `SELECT nature, file_extension, COUNT(*) FROM document_templates WHERE file_extension = 'xml' GROUP BY 1,2` sur chaque tenant | CSV par tenant | Détermine si la migration nécessite une data migration tenant-par-tenant |
| Confirmer `soffice --version` dans l'image Docker actuelle et en CI | Note d'infra | Sinon ajouter `libreoffice-core libreoffice-writer fonts-dejavu fonts-liberation` au Dockerfile |
| Vérifier les 4 fichiers Groupe D : grep API/v1, API/v2, rake tasks, jobs pour usage runtime | Verdict mort/vivant | Détermine effort phase 2 |

**Quality gate phase 0** : la classification définitive (groupes A/B/B-bis/C/D) est signée par produit avant de toucher au code.

---

### Phase 0bis — Réécriture de `lib/reporting.rb` (2–3 j)

**Pré-condition** : Phase 0 terminée.

**Décision architecturale clé** : remplacer le renderer global "tout-pour-Beardley" par un renderer "tout-pour-ODT-via-registry" qui **lève une exception explicite** sur toute nature non encore migrée. Cela rend la migration **mécaniquement progressive** : à chaque ajout de Printer, une nature de plus est servie ODT-natif ; aucune nature ne peut tomber silencieusement sur Beardley.

1. Créer `app/services/ekylibre/reporting/printer_registry.rb` :
   ```ruby
   module Ekylibre::Reporting
     class PrinterRegistry
       @@map = {}
       def self.register(nature, printer_class); @@map[nature.to_sym] = printer_class; end
       def self.lookup!(nature)
         @@map[nature.to_sym] or raise NotMigrated, "No ODT printer for nature #{nature}"
       end
       class NotMigrated < StandardError; end
     end
   end
   ```

2. Réécrire `lib/reporting.rb` :
   - Les renderers `pdf/odt` appellent `PrinterRegistry.lookup!(template.nature)` et passent par `DocumentGenerator.generate_pdf/odt`.
   - Tant qu'aucun Printer n'est enregistré pour une nature, l'erreur explicite est levée — la route reste cassée pour cette nature jusqu'à sa migration.
   - **Garde-fou intérimaire** : un flag `ENV['LEGACY_BEARDLEY_FALLBACK']=1` permet de retomber sur `template.export()` pendant la migration, pour éviter de casser les utilisateurs avant que tous les Printers ne soient livrés. À retirer à la fin de la Phase 2.
   - Supprimer les formats `ods/docx/xlsx` du registre (Beardley les exposait ; aucun Printer ODT ne les fournit aujourd'hui → si vraiment utilisés, faire un audit avant retrait).

3. Enregistrer les Printers existants déjà fonctionnels :
   ```ruby
   # config/initializers/printer_registry.rb
   Ekylibre::Reporting::PrinterRegistry.register :sales_invoice, Printers::Sale::SalesInvoicePrinter
   # … 40 enregistrements correspondant aux 40 .odt déjà migrés
   ```

4. Patcher le monkey-patch `ActionController::Responder` : conserver le mécanisme (sinon `respond_with` casse), mais le faire passer par le nouveau registry.

5. Suite Minitest dédiée : pour chaque nature enregistrée, simuler un `GET .pdf` et vérifier que le renderer ne touche pas à Beardley (mock `Beardley::Report` pour faire péter le test si appelé).

**Quality gate phase 0bis** : tests verts ; smoke test manuel sur tenant `demo` des 40 rapports ODT-natifs déjà existants ; les 18 rapports XML/JRXML restants lèvent `NotMigrated` (ou tombent sur le fallback flaggé).

---

### Phase 1 — Suppression de `matter.xml` (0,5 j)

**Pré-condition** : Phase 0 a confirmé `matter.xml` comme mort.

1. `rm config/locales/fra/reporting/matter.xml`.
2. Vérifier qu'aucun tenant n'a `DocumentTemplate.where(nature: 'matter', managed: true)`. Si oui, migration : supprimer ces lignes.
3. Vérifier Onoma : si `matter` est listé dans `Onoma::DocumentNature`, retirer l'entrée ou la marquer inactive.

**Quality gate phase 1** : aucun test cassé ; aucun warning Onoma au boot.

---

### Phase 2 — Création des Printers + templates ODT pour Groupes B / B-bis / C / D (12–18 j)

> **Effort dominant.** Découpé par lot fonctionnel ; chaque lot est mergeable indépendamment dès qu'il est complet.

#### Lot 2.A — Élevage (4–6 j)

- `Printers::AnimalListPrinter` + `config/locales/fra/reporting/animal_list.odt`
- `Printers::AnimalSheetPrinter` + `animal_sheet.odt`
- `Printers::VeterinaryBookletPrinter` + `veterinary_booklet.odt` (datasource extraite de `config/aggregators/veterinary_booklet.xml`, requête registre soins par animal/période/acte vétérinaire)
- `Printers::AnimalHusbandryRegisterPrinter` + `animal_husbandry_register.odt` (entrées/sorties troupeau, naissances, morts, mouvements, conformité ICA)
- Ajout `format.pdf`/`format.odt` explicite dans `animals_controller.rb`
- Inscription au `PrinterRegistry`
- Suppression `config/aggregators/{veterinary_booklet,animal_husbandry_register}.xml`
- Tests printers + intégration contrôleur

**Validation** : diff visuel PDF golden vs nouveau, revue produit par support agricole FR.

#### Lot 2.B — Stocks & livraisons (3–4 j)

- `Printers::DepositListPrinter` + `deposit_list.odt`
- `Printers::OutgoingDeliveryDocketPrinter` + `outgoing_delivery_docket.odt`
- Ajout `format.pdf` dans `deposits_controller.rb`, `deliveries_controller.rb`
- Inscription registry, tests

#### Lot 2.C — Comptabilité (2–3 j)

- `Printers::JournalEntrySheetPrinter` + `journal_entry_sheet.odt`
- Couverture `format.pdf` pour `account_journal_entry_sheet` (Groupe C — l'ODT existe déjà, juste à enregistrer)
- Couverture `format.pdf` pour `outgoing_payment_list__*` (Groupe C — idem)
- Ajout `format.pdf` dans `journal_entries_controller.rb`
- Inscription registry, tests

#### Lot 2.D — Achats / parcelles / tiers (3–4 j)

- `Printers::PurchasesInvoicePrinter` + `purchases_invoice.odt`
- `Printers::CultivableZoneSheetPrinter` + `cultivable_zone_sheet.odt`
- `Printers::EntitySheetPrinter` + `entity_sheet.odt`
- `Printers::ProductsSheetPrinter` + `products_sheet.odt`
- `Printers::ManureManagementPlanSheetPrinter` + `manure_management_plan_sheet.odt`
- Ajout `format.pdf` dans contrôleurs respectifs
- Inscription registry, tests

#### Lot 2.E — Groupe D : `fr_pcg*` (1 j, conditionnel)

Si Phase 0 confirme un usage runtime :
- Vérifier si `Printers::BalanceSheetPrinter` / `Printers::IncomeStatementPrinter` actuels gèrent déjà les 4 plans comptables (`fr_pcg82`, `fr_pcg2023`, `fr_pcga`, `fr_pcga2023`) avec un seul template ODT générique → si oui, supprimer simplement les 4 JRXML.
- Sinon, créer les 4 ODT spécifiques.

Si Phase 0 confirme inactif : simple `rm` des 4 JRXML.

#### Lot 2.F — Locale anglaise `sale.jrxml` (0,5 j)

- Créer `config/locales/eng/reporting/sales_invoice.odt`, `sales_order.odt`, `sales_estimate.odt` (équivalents anglais des 3 templates FR existants), OU
- Confirmer que le `TemplateFileProvider` fallback (`eng → fra`) couvre tous les cas, et `rm sale.jrxml`.

**Quality gate phase 2** :
- Pour chaque Printer : golden test (`tmp/golden/` phase 0 vs rendu actuel) signé par produit.
- Performance : génération ne doit pas dépasser 1,5× la durée Beardley actuelle.
- Tests Minitest verts pour chacun des 9 contrôleurs migrés.

---

### Phase 3 — Suppression des dépendances (2 j)

**Pré-condition** : Phase 2 mergée, **flag `LEGACY_BEARDLEY_FALLBACK` désactivé** depuis ≥ 2 semaines en prod sans warning émis.

1. **Code Ruby** :
   - Retirer `DocumentTemplate#print`, `#export`, `#import_jasper`, `template_fallbacks` (`app/models/document_template.rb`).
   - Retirer le bloc `jasper_paths` et son fallback dans `TemplateFileProvider` (`lib/ekylibre/document_management/template_file_provider.rb:54-62`).
   - Mettre à jour le validateur d'extension fichier dans `DocumentTemplate` : `file_extension` ne supporte plus que `:odt`.
   - Retirer le fallback Beardley dans `lib/reporting.rb` ; retirer les formats inutilisés (`ods`, `docx`, `xlsx`) sauf preuve d'usage.
   - Supprimer `lib/aggeratio/`, `app/jobs/export_job.rb` (réécrit en Phase 2 si nécessaire pour async ODT), `app/controllers/backend/exports_controller.rb` (UI Aggeratio) — sous réserve qu'aucun client n'utilise les exports CSV/agrégateurs survivants.
   - Supprimer les 4 JRXML Groupe D si retenus comme morts.
   - Supprimer tous les JRXML/XML restants dans `config/locales/{eng,fra}/reporting/`.

2. **Migration de schéma** :
   ```ruby
   change_column_default :document_templates, :file_extension, from: 'xml', to: 'odt'
   ```
   Pour les `DocumentTemplate` `managed=false` (custom client) encore en XML : décision produit — soit migration forcée à `odt` avec rechargement source par défaut, soit inactivation pour traitement manuel.

3. **Gemfile** : supprimer les 9 gems listées section 2.1. Lancer `bundle lock`.

4. **Initializer** : supprimer `config/initializers/beardley.rb` et le dossier `config/reporting/beardley/`.

5. **Infra Docker** :
   - Mettre à jour `ghcr.io/ekylibre/docker-base-images/ruby2.6` (ou créer `ruby2.6-no-java`) pour retirer le JRE et les libs natives RJB.
   - Conserver `libreoffice-core` + `libreoffice-writer` + polices.
   - Retirer toute step `setup-java` en CI (GitHub Actions / GitLab CI).

6. **Documentation** :
   - Mettre à jour `CLAUDE.md` (section reporting : pipeline ODT-only, Printer + ODFReport).
   - Mettre à jour `docs/` sur la personnalisation des rapports : LibreOffice + `odf-report` syntax (`[[var]]`, sections, tables) au lieu de iReport/JasperSoft Studio.

**Quality gate phase 3** :
- `bundle exec rake test` vert.
- Image Docker `dev` rebuild OK, taille mesurée avant/après (objectif : −150 Mo minimum).
- Smoke test manuel des 43+ printers sur tenant `demo` (1 PDF + 1 ODT par nature).
- Bench charge sur génération PDF (50 simultanées) : pas de dégradation > 30 % vs baseline Beardley.

---

### Phase 4 — Cleanup tenants en production (rolling, hors release, 3 mois)

- Email/notification aux clients ayant des `DocumentTemplate` `managed=false, file_extension='xml'` actifs avec template non-trivial.
- Outil admin (`/admin/document_templates`) ou rake task pour lister par tenant les templates XML résiduels et proposer une suppression/conversion assistée.
- Sunset window de 3 mois : migration finale qui force l'inactivation des templates XML restants.

---

## 7. Risques & mitigations (révisés)

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Le flag `LEGACY_BEARDLEY_FALLBACK` masque des natures non migrées en prod | Élevée | Élevé | Métriques par nature en Phase 0bis ; alerte Sidekiq sur tout fallback ; bilan hebdo avant désactivation |
| Régression visuelle sur `veterinary_booklet` / `animal_husbandry_register` (forte mise en page Jasper) | Élevée | Élevé (réglementaire) | Golden snapshots + revue produit lot 2.A + plan de rollback (flag fallback rallumé) |
| Un nature Groupe D présumé mort est en réalité utilisé par un tenant client via API ou rake | Moyenne | Moyen | Audit prod phase 0 + télémétrie renderer par nature 2 sem. min. |
| `odf-report` (fork ekylibre) ne supporte pas une fonctionnalité Jasper utilisée (sous-totaux complexes, page break conditionnel) | Moyenne | Élevé | Spike technique en lot 2.A sur `veterinary_booklet` AVANT lots suivants ; alternative `sablon` (DOCX) ou contribution upstream `odf-report` |
| Suppression du JRE casse un autre composant (signature numérique, analyse PDF, traitement images) | Faible | Moyen | Grep `java\|javac\|jre\|jdk\|\.jar` exhaustif phase 3 ; tester `SignatureManager` workflow |
| Régression performance LibreOffice headless vs Beardley (JVM chaude) | Moyenne | Moyen | Pool de processus `soffice` pré-démarré ou jodconverter ; mesurer dès Phase 0 |
| Effort phase 2 sous-estimé (10 contrôleurs + 13 nouveaux Printers + 13 ODT) | Élevée | Calendrier | Découpage par lot mergeable ; pas de big-bang ; flag fallback comme filet de sécurité |
| Templates utilisateurs `.xml` orphelins après removal des méthodes `#print` | Certaine | Faible | Phase 4 dédiée + UI admin + sunset 3 mois |

---

## 8. Dépendances inter-phases

```
Phase 0 (audit + télémétrie)
   │
   ▼
Phase 0bis (réécriture lib/reporting.rb + registry + flag fallback)
   │
   ├──▶ Phase 1 (rm matter.xml)
   │
   ├──▶ Phase 2.A (élevage) ──┐
   │                          │
   ├──▶ Phase 2.B (stocks) ───┤
   │                          │
   ├──▶ Phase 2.C (compta) ───┼──▶ Phase 3 (removal deps) ──▶ Phase 4 (cleanup tenants)
   │                          │     (après 2 sem. sans fallback)
   ├──▶ Phase 2.D (achats) ───┤
   │                          │
   ├──▶ Phase 2.E (PCG) ──────┤
   │                          │
   └──▶ Phase 2.F (locale en) ┘
```

- Phase 0bis est **bloquante** pour toutes les phases 1+2.
- Les 6 lots de Phase 2 sont **parallélisables** sur 2–3 personnes une fois Phase 0bis livrée.
- Phase 3 **bloque sur** : tous les lots Phase 2 mergés + 2 semaines sans warning fallback en prod.

---

## 9. Checkpoints de validation

- [ ] **C0** Audit production terminé, classification définitive des 18 fichiers signée par produit.
- [ ] **C0bis** `lib/reporting.rb` réécrit, `PrinterRegistry` en place, 40 natures déjà migrées enregistrées, tests verts, flag `LEGACY_BEARDLEY_FALLBACK` documenté.
- [ ] **C1** `matter.xml` supprimé, tests verts.
- [ ] **C2.A** Lot élevage livré : 4 Printers + 4 ODT, golden tests OK, agrégateurs supprimés.
- [ ] **C2.B** Lot stocks & livraisons livré.
- [ ] **C2.C** Lot comptabilité livré (Groupe C couvert).
- [ ] **C2.D** Lot achats/parcelles/tiers livré.
- [ ] **C2.E** Groupe D tranché (suppression ou migration).
- [ ] **C2.F** Locale `eng` couverte ou `sale.jrxml` supprimé.
- [ ] **C3-prep** 14 jours en production avec `LEGACY_BEARDLEY_FALLBACK=0` sans warning émis dans Sidekiq/Rails logs.
- [ ] **C3** Gemfile sans `beardley*`/`rjb*`, `bundle install` propre en CI, image Docker rebuild sans JRE.
- [ ] **C4** Smoke test complet sur tenant `demo` (43 rapports × 2 formats).
- [ ] **C5** `CLAUDE.md` et docs mises à jour ; communication client envoyée (Phase 4).

---

## 10. Annexes — chemins absolus utiles

**Verrou architectural**
- `/home/djoulin/projects/ekylibre/lib/reporting.rb` — renderers globaux + monkey-patch Responder
- `/home/djoulin/projects/ekylibre/app/helpers/toolbar_helper.rb:34-54` — helper `t.export(:nature)`

**Beardley & Java**
- `/home/djoulin/projects/ekylibre/app/models/document_template.rb:139-170,307-354` — méthodes `#print`/`#export`/`#import_jasper`
- `/home/djoulin/projects/ekylibre/config/initializers/beardley.rb` — init RJB + classpath
- `/home/djoulin/projects/ekylibre/app/jobs/export_job.rb:23` — seul appelant runtime ExportJob/Aggeratio

**Pipeline ODT cible**
- `/home/djoulin/projects/ekylibre/lib/ekylibre/document_management/document_generator.rb:35-46`
- `/home/djoulin/projects/ekylibre/lib/ekylibre/document_management/template_file_provider.rb:28-63`
- `/home/djoulin/projects/ekylibre/lib/ekylibre/document_management/pdf_converter.rb:20-34`
- `/home/djoulin/projects/ekylibre/app/services/printers/printer_base.rb`

**Aggeratio**
- `/home/djoulin/projects/ekylibre/lib/aggeratio.rb`
- `/home/djoulin/projects/ekylibre/lib/aggeratio/` (5 fichiers)
- `/home/djoulin/projects/ekylibre/config/aggregators/{veterinary_booklet,animal_husbandry_register}.xml`
- `/home/djoulin/projects/ekylibre/app/controllers/backend/exports_controller.rb` (UI déclencheur)

**Templates**
- `/home/djoulin/projects/ekylibre/config/locales/fra/reporting/*.odt` (43 fichiers, cible)
- `/home/djoulin/projects/ekylibre/config/locales/fra/reporting/*.{jrxml,xml}` (17 fichiers à migrer/supprimer)
- `/home/djoulin/projects/ekylibre/config/locales/eng/reporting/sale.jrxml` (1 fichier)

**Vues backend déclenchant Beardley via renderer global**
- `app/views/backend/animals/index.html.haml:2` (`animal_list`)
- `app/views/backend/animals/show.html.haml:4` (`animal_sheet`)
- `app/views/backend/deposits/show.html.haml:2` (`deposit_list`)
- `app/views/backend/cultivable_zones/show.html.haml:3` (`cultivable_zone_sheet`)
- `app/views/backend/deliveries/show.html.haml:2` (`outgoing_delivery_docket`)
- `app/views/backend/journal_entries/show.html.haml:4` (`journal_entry_sheet`)
- `app/views/backend/purchase_invoices/show.html.haml:5` (`purchases_invoice`)
- `app/views/backend/entities/show.html.haml:4` (`entity_sheet`)
- `app/views/backend/products/index.html.haml:3` (`products_sheet`)
- `app/views/backend/manure_management_plans/show.html.haml:3` (`manure_management_plan_sheet`)

**Printers existants (43 classes)**
- `/home/djoulin/projects/ekylibre/app/services/printers/`

**Tests**
- `/home/djoulin/projects/ekylibre/test/models/document_template_test.rb:49-59`
