# Workflow — Ajout d'un champ `name` éditable sur `Intervention`

> **Statut** : Plan d'implémentation (aucune modification de code dans ce document)
> **Auteur** : Claude Code · 2026-05-31
> **Branche cible** : `5.0-beta`
> **Objectif** : permettre à l'utilisateur de nommer une intervention via l'UI. Si le champ est laissé vide, le modèle remplit automatiquement avec `"<procedure humanisée> <number>"` à la sauvegarde.
> **Étape suivante** : `/sc:implement claudedocs/workflow_intervention_name_field.md`

---

## 1. TL;DR

- 1 migration `add_column :interventions, :name, :string`.
- 1 `before_validation` dans `app/models/intervention.rb` qui remplit `self.name` quand il est blank.
- 1 modification de la méthode `Intervention#name` existante (ligne 699-702) — **collision à gérer** : la méthode actuelle calcule un label à la volée ; après migration, elle doit retourner la valeur de colonne (et conserver le calcul comme fallback en lecture si la colonne est vide, par exemple sur des enregistrements legacy non encore re-sauvés).
- 1 ajout `f.input :name` dans le formulaire HAML.
- Mise à jour des locales `eng`/`fra` (le helper `Clean::Locales` regenère automatiquement les clés).
- Fixtures de test à compléter.
- **Pas d'impact** sur les vues d'affichage (`show`, `index`, modals, cells) qui appellent déjà `@intervention.name` — elles bénéficient transparentment.

---

## 2. Risque clé — collision méthode `#name` vs colonne `name`

`app/models/intervention.rb:699-702` (état actuel) :

```ruby
def name
  tc(:name, intervention: (procedure ? procedure.human_name : "procedures.#{procedure_name}".t(default: procedure_name.humanize)), number: number)
end
```

Après ajout de la colonne, ActiveRecord génère un accesseur `#name` qui sera **masqué** par cette méthode. Deux choix :

| Option | Implémentation | Avantage | Inconvénient |
|---|---|---|---|
| **A — Remplir et lire la colonne** | Renommer l'ancien calcul en `default_name` (privé). La méthode `#name` retourne `self[:name].presence \|\| default_name`. Le `before_validation` fait `self.name ||= default_name`. | Cohérent : l'utilisateur voit toujours quelque chose, même sur d'anciens enregistrements jamais re-sauvegardés | Le lecteur fait un mini-fallback à chaque appel sur les vieux records |
| **B — Backfill data migration** | Idem A, plus une data migration qui peuple `name` pour tous les records existants à `null` | Lecture pure ensuite, plus de fallback | Migration plus longue (touche potentiellement des millions de lignes par tenant) |

> **Recommandation : Option A en première intention** (le fallback en lecture est gratuit, et la prochaine modification de chaque intervention persistera la valeur). **Option B uniquement** si une feature ultérieure dépend de filtres/recherches SQL sur `name`.

---

## 3. Inventaire des changements

| # | Fichier | Action |
|---|---|---|
| 1 | `db/migrate/YYYYMMDDHHMMSS_add_name_to_interventions.rb` | Créer la migration |
| 2 | `db/structure.sql` | Régénéré automatiquement par `rake db:migrate` (ne pas éditer à la main — cf. CLAUDE.md) |
| 3 | `app/models/intervention.rb` | Ajouter `before_validation :set_default_name` (ou bloc) + adapter la méthode `#name` existante |
| 4 | `app/views/backend/interventions/_form.html.haml` | Ajouter `= f.input :name` dans la section description |
| 5 | `config/locales/eng/models.yml` | Ajouter la clé `interventions.attributes.name` (sous `attributes:` du modèle) |
| 6 | `config/locales/fra/models.yml` | Idem en français |
| 7 | `test/fixtures/interventions.yml` | Ajouter `name:` sur les fixtures (optionnel — peut rester `nil` pour tester l'auto-remplissage) |
| 8 | `test/models/intervention_test.rb` | Ajouter 2 cas de test (auto-fill quand blank ; conservation quand fourni) |
| 9 | Contrôleur backend `interventions_controller.rb` | Whitelister `:name` dans `intervention_params` |
| 10 | (à vérifier) Serializer API v1/v2 | Whitelister `name` si une whitelist explicite existe |

---

## 4. Détails par fichier

### 4.1 Migration

Nouveau fichier `db/migrate/YYYYMMDDHHMMSS_add_name_to_interventions.rb` :

```ruby
class AddNameToInterventions < ActiveRecord::Migration[5.2]
  def change
    add_column :interventions, :name, :string
  end
end
```

- **Pas d'index** : `name` n'est utilisé que pour l'affichage ; aucune requête de filtrage prévue. Ajouter un index plus tard si une recherche full-text est introduite.
- **Pas de `null: false`** : la colonne est facultative en POST (l'auto-fill agit en `before_validation`, donc la valeur en DB ne sera jamais NULL côté écriture future, mais les anciens enregistrements peuvent rester NULL jusqu'à modification — d'où le besoin du fallback en lecture, cf. Option A).
- **Pas de default SQL** : la valeur calculée dépend de `procedure_name` et `number`, donc impossible à figer en `DEFAULT`. C'est le rôle du callback Ruby.
- **Multi-tenant** : `rake tenant:migrate` (cf. CLAUDE.md) pour propager sur tous les schémas tenants après `rake db:migrate`.

### 4.2 Modèle — `app/models/intervention.rb`

**Modifications** :

1. **Ajouter un callback** près de `before_validation :set_number, on: :create` (vers la ligne 144) :
   ```ruby
   before_validation :set_default_name
   ```

2. **Refactorer la méthode `#name` existante** (lignes 699-702) :
   ```ruby
   def name
     self[:name].presence || default_name
   end

   private

   def default_name
     procedure_label = procedure ? procedure.human_name : "procedures.#{procedure_name}".t(default: procedure_name.humanize)
     tc(:name, intervention: procedure_label, number: number)
   end

   def set_default_name
     self[:name] = default_name if self[:name].blank? && procedure_name.present?
   end
   ```

   - Lire `self[:name]` (et non `name`) pour court-circuiter la méthode `#name` redéfinie et éviter une récursion.
   - `set_default_name` s'exécute en `before_validation` (pas seulement `on: :create`) pour qu'un utilisateur qui vide le champ en édition retombe sur la valeur calculée.
   - `procedure_name.present?` garde contre une intervention créée sans procédure (cas exotique mais possible via API) — sinon `tc(:name, ...)` lève sur `procedure_name.humanize`.

3. **Vérifier les usages internes existants de `#name`** (audit déjà fait) :
   - `_compare_planned_with_realised_modal.haml:2`
   - `_selection_modal.html.haml:18`
   - `_details_modal.html.haml:1`
   - `cells/last_intervention_cells/show.html.haml:29`
   - `helpers/activity_productions_helper.rb:44,82`
   - `helpers/interventions_helper.rb:108`

   **Aucun changement requis** sur ces fichiers : ils continuent d'appeler `.name`, qui retourne désormais soit la valeur user, soit le fallback calculé. Comportement strictement équivalent ou amélioré.

### 4.3 Vue — `app/views/backend/interventions/_form.html.haml`

Insérer **après la ligne `= f.input :description`** (vers la ligne 44, dans le `field_set` principal) :

```haml
= f.input :name, hint: :intervention_name_hint.tl
```

- Champ texte simple (SimpleForm détectera `string`).
- `hint` (i18n) précise « laissez vide pour générer automatiquement ».
- Optionnellement, placer le champ **avant** `:description` pour qu'il apparaisse en tête de formulaire (UX : c'est le label que l'utilisateur verra partout) — décision à arbitrer par produit.

### 4.4 Contrôleur — `app/controllers/backend/interventions_controller.rb`

Whitelister `:name` dans la méthode `intervention_params` (ou équivalent). À vérifier au moment de l'implémentation : si le contrôleur utilise `permitted_params` génériques basés sur les attributs du modèle, aucun changement nécessaire. Sinon ajouter `:name` à la liste explicite.

### 4.5 i18n — `config/locales/{eng,fra}/models.yml`

Sous la section `interventions.attributes` (ou `intervention.attributes` selon la convention en place — l'audit montre une clé existante `intervention.name` utilisée comme **template** par `tc(:name, ...)`). Décision :

- **Renommer la clé template** : `intervention.name` → `intervention.default_name_format` (pour éviter la confusion avec l'attribut).
- **Ajouter l'attribut** : `interventions.attributes.name: "Name"` (eng) / `"Nom"` (fra).
- **Mettre à jour la méthode `default_name`** pour appeler `tc(:default_name_format, ...)` au lieu de `tc(:name, ...)`.

Procédure standard du repo (CLAUDE.md) :
```bash
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake clean:locales
```
Cette tâche réordonne les clés et marque les manquantes avec `# `. Compléter ensuite les traductions humanisées.

**Hint i18n** : ajouter `interventions.intervention_name_hint` (ou clé équivalente selon convention vues) :
- eng : `"Leave empty to auto-generate from procedure and number."`
- fra : `"Laisser vide pour générer automatiquement depuis la procédure et le numéro."`

### 4.6 Fixtures — `test/fixtures/interventions.yml`

**Ne pas** ajouter `name:` aux fixtures existantes — laisser à `nil` permet de tester le fallback de lecture (les fixtures simulent des enregistrements legacy). Ajouter **une nouvelle fixture** avec `name: "Custom label"` pour tester le chemin "valeur utilisateur conservée".

### 4.7 Tests — `test/models/intervention_test.rb`

Ajouter 3 cas Minitest :

```ruby
def test_name_is_auto_filled_when_blank
  intervention = Intervention.new(procedure_name: 'plowing', number: '42', ...)
  intervention.valid?
  assert_equal "Plowing #42", intervention.name  # selon i18n eng
end

def test_name_keeps_user_value_when_provided
  intervention = Intervention.new(procedure_name: 'plowing', number: '42', name: "Champ Nord", ...)
  intervention.valid?
  assert_equal "Champ Nord", intervention.name
end

def test_legacy_record_with_nil_name_falls_back_to_default
  intervention = interventions(:interventions_001)
  intervention.update_column(:name, nil)  # bypass callbacks pour simuler un record pré-migration
  assert_equal intervention.send(:default_name), intervention.reload.name
end
```

### 4.8 API JSON

Vérifier `app/controllers/api/v1/interventions_controller.rb` et v2. Si une whitelist d'attributs est explicite (`only:` / `attributes:` dans un serializer), ajouter `:name`. Si la sérialisation est automatique (`respond_with(@intervention)`), aucune action.

---

## 5. Phases d'exécution

### Phase 1 — Migration (15 min)
1. Créer `db/migrate/YYYYMMDDHHMMSS_add_name_to_interventions.rb`.
2. `docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake db:migrate`.
3. `docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake tenant:migrate` (propagation tenants).
4. Vérifier que `db/structure.sql` a été régénéré et committer la version générée.

**Quality gate** : la table `interventions` a bien la colonne `name VARCHAR` ; les tenants existants l'ont aussi.

### Phase 2 — Modèle & callback (30 min)
1. Modifier `app/models/intervention.rb` selon section 4.2.
2. Vérifier qu'aucun test existant ne casse : `docker compose ... exec app bundle exec ruby -Itest test/models/intervention_test.rb`.
3. Tester en console :
   ```ruby
   i = Intervention.new(procedure_name: 'plowing', number: '999')
   i.valid?  # déclenche before_validation
   i.name    # doit retourner "Plowing #999" (ou équivalent fra)
   i.name = "Mon label"; i.valid?
   i.name    # doit retourner "Mon label"
   ```

**Quality gate** : 3 nouveaux tests verts ; ancienne suite verte.

### Phase 3 — Vue & contrôleur (20 min)
1. Ajouter `f.input :name` dans `_form.html.haml`.
2. Whitelister `:name` dans `interventions_controller.rb` si nécessaire.
3. Test manuel UI : créer une intervention sans nom → vérifier l'auto-fill ; éditer pour donner un nom → vérifier la persistance.

**Quality gate** : aller-retour formulaire OK, deux scénarios (vide + rempli) validés.

### Phase 4 — i18n (15 min)
1. Renommer la clé template `intervention.name` → `intervention.default_name_format` dans eng + fra.
2. Ajouter l'attribut `interventions.attributes.name`.
3. Ajouter le hint formulaire.
4. `rake clean:locales` pour vérifier/réordonner.

**Quality gate** : pas de clé `# ` non humanisée critique introduite ; UI eng et fra cohérentes.

### Phase 5 — API (5 min, conditionnel)
1. Si serializer explicite : ajouter `:name`.
2. Test : `curl /api/v1/interventions/<id>.json` → vérifier la présence de `name`.

---

## 6. Risques & mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Collision méthode `#name` ↔ accesseur colonne provoquant récursion infinie | Moyenne | Élevé | Lire `self[:name]` (pas `name`) dans les méthodes ; couvrir par test unitaire |
| La clé i18n `intervention.name` est référencée ailleurs comme template | Moyenne | Moyen | Grep avant renommage : `tc(:name`, `t('interventions.name'`, `t('intervention.name'` |
| Performance Intervention#save déjà coûteuse (cf. CLAUDE.md — 30-100+ SQL par save) | Faible (impact) | Faible | Le callback `set_default_name` est pure-ruby, aucun SQL ajouté |
| Anciennes interventions affichent vide en cas de bug du fallback | Faible | Moyen | Fallback `default_name` garde le calcul à la volée ; data migration optionnelle (Option B) si besoin futur |
| Conflit avec un plugin qui surcharge `Intervention` (Gemfile.local) | Faible | Moyen | Vérifier `Gemfile.local` actif avant merge ; tester avec plugins activés |

---

## 7. Checkpoints de validation

- [ ] **C1** Migration créée, `db/structure.sql` régénéré, `rake db:migrate` + `rake tenant:migrate` OK
- [ ] **C2** Modèle modifié, 3 tests verts, suite Intervention complète verte
- [ ] **C3** Formulaire affiche le champ, scénarios vide + rempli OK en UI
- [ ] **C4** i18n eng + fra à jour, hint visible dans le formulaire
- [ ] **C5** API JSON retourne `name` (si applicable)
- [ ] **C6** Aucune régression sur les vues `show`/`index`/modals/cells qui consomment déjà `.name`

---

## 8. Annexes — chemins absolus utiles

- Modèle : `/home/djoulin/projects/ekylibre/app/models/intervention.rb` (méthode `#name` ligne 699-702 ; callbacks à partir de ligne 144)
- Vue formulaire : `/home/djoulin/projects/ekylibre/app/views/backend/interventions/_form.html.haml` (insertion après la ligne 44)
- Contrôleur : `/home/djoulin/projects/ekylibre/app/controllers/backend/interventions_controller.rb`
- Schéma : `/home/djoulin/projects/ekylibre/db/structure.sql:1588-1624` (table `interventions`)
- Migrations existantes (modèle de style) : `/home/djoulin/projects/ekylibre/db/migrate/`
- Locales : `/home/djoulin/projects/ekylibre/config/locales/eng/models.yml`, `/home/djoulin/projects/ekylibre/config/locales/fra/models.yml`
- Fixtures : `/home/djoulin/projects/ekylibre/test/fixtures/interventions.yml`
- Tests : `/home/djoulin/projects/ekylibre/test/models/intervention_test.rb`
- Vues consommatrices de `#name` (aucune modif requise) :
  - `app/views/backend/interventions/_compare_planned_with_realised_modal.haml:2`
  - `app/views/backend/interventions/_selection_modal.html.haml:18`
  - `app/views/backend/interventions/_details_modal.html.haml:1`
  - `app/views/backend/cells/last_intervention_cells/show.html.haml:29`
  - `app/helpers/activity_productions_helper.rb:44,82`
  - `app/helpers/interventions_helper.rb:108`
