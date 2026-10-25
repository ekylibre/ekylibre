# Interventions — performance de la page edit

Ce document décrit le diagnostic et les correctifs appliqués pour résoudre la
lenteur du formulaire d'édition d'intervention
(`/backend/interventions/:id/edit`), particulièrement sur les interventions
phytosanitaires comportant beaucoup de cibles (~80+).

## Symptôme

Sur l'édition d'une intervention phyto avec 85+ cibles, la page se fige
plusieurs secondes au chargement, et chaque modification (ajout d'une cible,
sélection d'un produit, changement de date) provoque une rafale d'appels XHR
qui rendent l'UI inutilisable pendant 5–10 secondes.

## Diagnostic

Deux endpoints AJAX sont déclenchés en cascade par le formulaire :

### `POST /backend/registered_phytosanitary_products/get_products_infos`

- **Côté JS** — chaque `selector:change` sur un input phytosanitaire déclenche
  `productsInfos.display()`. Pire, le handler suivant
  (`interventions_phyto.js.coffee:279-280`) re-déclenche **tous** les
  selectors d'inputs produit dès qu'**une** cible change :

  ```coffee
  $(document).on 'selector:change', "[data-selector-id='intervention_target_product_id']", ->
    $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')
  ```

  Avec N cibles × M inputs phyto, on obtient N×M requêtes identiques
  (l'endpoint envoie toujours l'état global du formulaire, le résultat est
  donc le même pour tous les appels).

- **Côté serveur** — `TargetZone.from_targets_data` faisait 2 `find_by` par
  cible (Plant + LandParcel sont en STI sur la table `products` donc le
  filtrage par `type` est obligatoire) → 174 SQL pour 87 cibles.

### `GET /backend/interventions/validate_reentry_delay`

- **Côté JS** — le debounce était cassé :

  ```coffee
  updateHarvestDelayWarnings = _.debounce ->   # wait=0 → ne déduplique que dans le même tick
  ```

  Et le handler ligne 1003 ne gardait pas `wasInitializing`, donc à
  l'initialisation des 87 selectors de cibles, 10+ requêtes
  `validate_reentry_delay` partaient en parallèle (~850 ms chacune).

- **Côté serveur** — `PhytoHarvestAdvisor#reentry_possible?` est appelée dans
  une boucle sur les parcels :

  ```ruby
  parcels.map do |parcel|                                # 87 itérations
    advisor_result = harvest_advisor.reentry_possible?(parcel, ...)
  end
  ```

  Chaque itération exécute :
  1. `get_product_id_from_target(target)` : 1–2 SQL (Plant#production /
     LandParcel#activity_production / `Plant.where(activity_production_id:)`)
  2. `get_spraying_intervention_on(targets)` : 1 SQL pour les interventions
  3. `interventions.map { |i| i.inputs.map(&:allowed_entry_factor) }` : N+1
     sur les `inputs` de chaque intervention

  Soit ~300–400 requêtes SQL par appel pour 85 parcels, et ce 10 fois de
  suite au chargement.

## Correctifs

### A. Vrai debounce + skip de l'initialisation sur `updateHarvestDelayWarnings`

`app/assets/javascripts/backend/interventions_base.js.coffee:1003-1057`

```coffee
$(document).on 'selector:change', ".nested-targets .intervention_targets_product", (event, _selectedElement, wasInitializing) ->
  return if wasInitializing
  updateHarvestDelayWarnings()

# ...

updateHarvestDelayWarnings = _.debounce(->
  # ...
, 400)
```

- 400 ms de debounce coalesce les rafales d'événements (init, ajouts groupés,
  retraits via cocoon).
- Le skip `wasInitializing` empêche le handler de se déclencher quand les
  selectors se peuplent depuis le HTML initial.

### B. Couper la cascade re-trigger et debouncer `productsInfos.display`

`app/assets/javascripts/backend/interventions_phyto.js.coffee`

```coffee
productsInfos =
  display: () ->
    @_debouncedDisplay ?= _.debounce(@_displayNow.bind(this), 250)
    @_debouncedDisplay()

  _displayNow: () ->
    # ...code original
```

Tous les chemins qui appelaient `productsInfos.display()` directement passent
maintenant par un debounce 250 ms partagé. Comme l'endpoint envoie toujours
l'état global du formulaire, coalescer N appels en un seul est sûr.

Les 4 handlers `selector:change` qui appelaient `productsInfos.display()` ou
le re-trigger en cascade gardent désormais `wasInitializing` :

```coffee
$(document).on 'selector:change', "[data-selector-id='intervention_target_product_id']", (event, _selectedElement, wasInitializing) ->
  return if wasInitializing
  $("[data-selector-id='intervention_input_product_id']").trigger('selector:change')
```

### C. Élimination du N+1 dans `TargetZone.from_targets_data`

`app/services/interventions/phytosanitary/models/target_zone.rb:21-39`

```ruby
def from_targets_data(targets_data)
  ids = targets_data.map { |data| data[:id] }.compact.uniq
  plants_by_id = Plant.where(id: ids).index_by(&:id)
  land_parcels_by_id = LandParcel.where(id: ids).index_by(&:id)

  targets_data.flat_map do |data|
    id = data[:id].to_i
    target = plants_by_id[id] || land_parcels_by_id[id]
    # ...
  end
end
```

2 requêtes set-based + lookup mémoire au lieu de 2×N `find_by`.

### D. Élimination du N+1 dans `PhytoHarvestAdvisor`

`app/services/interventions/phytosanitary/phyto_harvest_advisor.rb`

Deux nouvelles méthodes bulk qui retournent `{target_id => HarvestResult}` :

- `reentry_possible_for(targets, date, date_end:, ignore_intervention:)`
- `harvest_possible_for(targets, date, date_end:, ignore_intervention:)`

Stratégie de préchargement :

1. `ActiveRecord::Associations::Preloader` sur `:activity_production` pour
   tous les targets en 1 query.
2. `Plant.where(activity_production_id: ap_ids).pluck(:activity_production_id, :id)`
   pour résoudre les plants des LandParcels en 1 query.
3. `get_spraying_intervention_on(all_product_ids).includes(:inputs)` pour
   charger toutes les interventions phyto pertinentes + leurs inputs en 1
   query préchargée.
4. `InterventionTarget.where(intervention_id:, product_id:).pluck(...)` pour
   construire l'index `product_id → intervention_ids` en 1 query.
5. Itération en mémoire pour calculer le `HarvestResult` par target,
   réutilisant les helpers existants `reentry_possible_from_interventions?`
   et `harvest_possible_from_interventions?`.

L'API per-target (`reentry_possible?`/`harvest_possible?`) reste inchangée
pour les 3 autres callers (`activity_productions_controller`,
`plants_controller`, `land_parcels_controller`) qui n'ont qu'un target à la
fois.

`app/controllers/backend/interventions_controller.rb:624-672` —
`validate_harvest_delay` et `validate_reentry_delay` appellent désormais les
méthodes bulk.

## Mesures

Sanity-check via `rails runner` sur le tenant `ferme-des-loubes`,
intervention 34 (85 cibles trouvées) :

| Méthode | Temps | SQL queries | Résultat |
|---------|-------|-------------|----------|
| `reentry_possible?` (legacy, par target) | 322 ms | 379 | 85 possible |
| `reentry_possible_for` (bulk) | 82 ms | 8 | 85 possible |

- **47× moins** de requêtes SQL
- **~4× plus rapide** en cold-cache (bénéfice plus important sur HTTP réel
  où chaque query paie l'overhead réseau)
- **0 parcel divergent** : sémantique strictement identique

## Effet combiné A + B + C + D

- **A + B** : la cascade d'appels XHR au chargement / par interaction est
  éteinte. Au lieu de 10× `validate_reentry_delay` + N×M
  `get_products_infos` au chargement, on obtient 1 appel par endpoint après
  debounce.
- **C + D** : chaque appel restant passe d'environ 800 ms à ~100–150 ms
  côté serveur.

## Bugs annexes découverts pendant le diagnostic

### E. Bug latent dans `CropGroupParamsComputation`

`app/services/interventions/crop_group_params_computation.rb`

`#options` (ligne 16) protégeait déjà contre `target_parameter.nil?` avec
`return options if target_parameter.nil?`, mais `#rejected_crops` (ligne 47)
appelait `#matching_targets` (ligne 69) sans la même garde, qui faisait
crasher `target_parameter.filter` sur `NoMethodError` (`undefined method
'filter' for nil:NilClass`).

Ça crashait l'action `Backend::InterventionsController#new` pour toute
procédure dont `parameters_of_type(:target, true).first` est nil (ce qui
peut arriver en dev quand le registry Procedo n'est pas correctement
chargé, voir section F).

Fix symétrique :

```ruby
def rejected_crops
  @rejected_crops ||= target_parameter.nil? ? [] : crops.difference(matching_targets)
end

def matching_targets
  return Product.none if target_parameter.nil? || target_parameter.filter.blank?

  CropGroup.available_crops(crop_group_ids, target_parameter.filter)
end
```

### F. Race condition Procedo / autoloader en mode développement

`config/environments/development.rb` met `cache_classes = false`, et
`config/application.rb:37` ajoute `lib/` à `autoload_paths`. Quand le dev
sauve un fichier dans le projet, l'autoloader peut recharger des classes,
y compris `lib/procedo/formula/nodes.rb`.

Or les arbres de formules des procédures sont parsés **une seule fois au
boot** dans `config/initializers/procedo.rb`. Ils gardent une référence
vers les classes `Procedo::Formula::Nodes::*` originales. Après reload,
ces constantes pointent vers de nouvelles classes, et l'interpréteur
(`lib/procedo/engine/interpreter.rb`) fait des checks
`node.is_a?(Procedo::Formula::Language::Division)` qui résolvent vers les
**nouvelles** classes — et ne matchent plus les nœuds des arbres.

Symptôme : `compute.json` renvoie 500 `RuntimeError (Dont known how to
manage node: Procedo::Formula::Nodes::Division)` (ou `Conjunction`,
`ActorPresenceTest`, `EnvironmentVariable`...). En cascade, le hidden
`quantity_population` n'est jamais peuplé côté JS et la validation
`InterventionInput#quantity_population` `presence: true` échoue au submit
avec « Quantité population ne peut pas être vide ».

**Fix immédiat** : `docker compose -f docker/dev/docker-compose.yml restart app`

**Fixes durables (non implémentés)** :

1. Soustraire `lib/procedo/` de `autoload_paths` et l'ajouter à
   `eager_load_paths` uniquement → ces classes ne se rechargent plus.
2. Re-parser les procédures dans
   `Rails.application.reloader.to_prepare` → trees régénérés à chaque
   reload avec les classes courantes.

### G. Race condition `unserializeRecord` ↔ saisie utilisateur

`app/assets/javascripts/backend/interventions_base.js.coffee:128-145`

Quand l'utilisateur sélectionne un produit phyto puis tape rapidement
une quantité, deux requêtes `compute` peuvent être en vol simultanément.
La réponse de la première (envoyée avant que l'utilisateur ait saisi)
contient `quantity_value: ""`. `unserializeRecord` écrase alors le
champ avec une chaîne vide, faisant disparaître la quantité fraîchement
tapée.

Fix : deux gardes ajoutées dans la branche `else` finale :

```coffee
update = false if element.is(':focus')
update = false if (value is null or value is "") and element.val()? and element.val() isnt ""
```

- `:focus` → on ne touche pas à un champ que l'utilisateur édite à
  l'instant.
- Empty-overwrite-non-empty → on n'efface jamais une valeur saisie côté
  client en réponse à un blanchiment serveur (qui est en pratique
  toujours le signe d'une réponse périmée pour ce form).

### H. Annulation des XHR `productsInfos` obsolètes

`app/assets/javascripts/backend/interventions_phyto.js.coffee:18-37`

`productsInfos.display` partait potentiellement plusieurs requêtes en
parallèle sur des états successifs du formulaire — la dernière à
revenir gagnait, peu importe son ancienneté. Ajout d'un tracking de la
XHR en vol et d'un `abort()` avant chaque nouvelle requête, plus
debounce passé de 250 ms à 400 ms pour mieux coalescer les rafales
d'événements (sélection produit + usage + quantité dans la foulée) :

```coffee
productsInfos =
  display: () ->
    @_debouncedDisplay ?= _.debounce(@_displayNow.bind(this), 400)
    @_debouncedDisplay()

  _displayNow: () ->
    @_inFlight?.abort?()
    # ...
    @_inFlight = $.ajax(...).done(...).always(=> @_inFlight = null)
```

## Pour aller plus loin

Le bottleneck restant est exclusivement côté serveur. Mesure post-fix
sur intervention 34 :

```
POST /get_products_infos
Completed 200 OK in 4994ms (Views: 0.1ms | ActiveRecord: 66.7ms)
```

**5 secondes par appel, dont 67 ms en SQL** = 99 % du temps en code Ruby
pur. Les fixes JS éliminent les appels redondants (1 seul XHR au lieu de
N) et empêchent les réponses obsolètes d'écraser l'UI, mais chaque appel
restant prend toujours 5 s.

Pistes non implémentées :

- **Fix I — Intersection spatiale en SQL** dans `ApplicationFrequencyValidator`,
  `MaxApplicationValidator`, `NonTreatmentAreasValidator` :
  `select_with_shape_intersecting` et les `intersect?` en mémoire sur des
  `Charta::Geometry` parcourent N×M shapes en Ruby pur. Remplacer par
  `ST_Intersects` indexé devrait faire passer chaque appel de 5 s à
  ~100-200 ms. Refactor non-trivial des 3 validators.
- **Cache HTTP** : `get_products_infos` envoie le même payload tant que les
  inputs/usages n'ont pas changé. Un cache côté serveur clé-pair (state du
  formulaire → JSON) éliminerait les recalculs répétés sur des modifications
  qui ne touchent pas les inputs phyto.
- **Pagination/lazy-load des cibles** : pour les interventions avec 100+
  cibles, charger les warnings de réentrée à la demande (au scroll, ou par
  groupe) plutôt qu'en une fois.

---

# API mobile — création d'intervention (`POST /api/v2/interventions`)

> Surface différente des sections ci-dessus (page d'édition backend) : cette
> partie concerne l'endpoint API consommé par l'app **zero-mobile**, qui passe
> par `Interventions::Computation::Compute` puis
> `BuildInterventionInteractor#save!`.

## Bug #2660 — 400 « undefined method `unit' for nil:NilClass »

### Symptôme

Toute création d'intervention **spraying** depuis l'app mobile renvoyait
`400 Bad Request` avec `{ "errors": ["undefined method 'unit' for
nil:NilClass"] }`. L'interactor `BuildInterventionInteractor#run` rescue le
`StandardError` et n'en remonte que le message, sans backtrace — d'où la
difficulté de diagnostic.

Le déclencheur est la présence d'un **outil `sprayer`** dans le payload : aucun
autre test d'API n'en envoyait, et la régression #2661 (dispatch `Nodes::*`,
voir section F) passait à côté car son test n'a pas de `sprayer`.

### Diagnostic

Chaîne complète (reproduite sur le tenant `demo`, produit 332 = « Abacus »,
correspondant au log de prod) :

1. `Interventions::Computation::ComputeReadings#compute_parameter_readings`
   amorce **un reading par reading de référence** absent du paramètre, **sans
   valeur**. La référence `sprayer` (`config/procedures/spraying.xml`) en
   déclare trois : `nominal_storable_net_volume` + `application_width` (type
   **measure**) et `rows_count` (integer).

2. `Procedo::Engine::Intervention::Reading#to_hash`
   (`lib/procedo/engine/intervention/reading.rb`) avait un bug latent sur un
   reading **measure vide** :

   ```ruby
   if measure? && @value.present?   # faux quand la valeur est vide
     ...
   elsif geometry...                # faux
   else
     hash["#{datatype}_value".to_sym] = @value   # datatype == :measure → clé :measure_value !
   end
   ```

   Pour `datatype == :measure`, la colonne est `measure_value_value`, **pas**
   `measure_value`. Le `else` émettait donc `measure_value: nil` — le nom de
   l'agrégat `composed_of :measure_value` (`app/models/concerns/reading_storable.rb`).

3. À la construction du reading via `readings_attributes=`, le writer
   `composed_of` d'ActiveRecord (`aggregations.rb:276`, `allow_nil: false`)
   exécute `mapping.each { |k, v| self[k] = part.send(v) }` sur le `part` nil →
   **`nil.send(:unit)`** → l'erreur exacte.

Deux crashs latents se cachaient derrière : même en corrigeant l'étape 2,
`composed_of` (allow_nil false) construit `Measure.new(nil, nil)` (sans
dimension), donc `absolutize_measure` (`reading_storable.rb`) plante en
convertissant *none → volume* ; et un reading measure vide échoue de toute
façon `validates :measure_value, presence:`. **Tout reading vide viole sa
propre validation `presence`/`inclusion`** — les readings vides ne doivent donc
jamais être persistés.

### Correctif

`lib/procedo/engine/intervention/product_parameter.rb` — une garde dans les
deux boucles `@readings.each` (`#to_hash` **et** `#to_attributes`) :

```ruby
@readings.each do |id, reading|
  next unless reference.reading(reading.name)
  next if reading.value.blank?      # ← ignore les readings amorcés sans valeur
  hash[:readings_attributes] ||= {}
  hash[:readings_attributes][id] = reading.to_hash
end
```

- Sûr pour tous les datatypes : un reading vide, quel qu'en soit le type, échoue
  son validateur `presence`/`inclusion` ; le retirer est toujours correct.
- Les readings integer retombent sur `0` (non blank) et survivent ; les readings
  valués ne sont pas touchés.

Test de non-régression : `test/controllers/api/v2/interventions_controller/create_test.rb`
→ « create spraying intervention with sprayer tool (prunes empty measure
readings) » : poste un spraying avec outil `sprayer`, attend `201`, et vérifie
qu'aucun reading measure sans valeur n'est persisté.

### Note de données (sans rapport avec le bug)

Sur `demo`, le produit cible 31 est **mort le 2018-07-31** : une intervention
datée 2026 y déclenche légitimement la validation `target_dont_exist_after`.
C'est un artefact des données de test — le tenant réel de l'app mobile utilise
une cible vivante. À garder en tête si un *autre* 400 apparaît après ce
correctif.

## Idempotence & provider (rappel)

Le `create` est idempotent quand `provider.id` est fourni : si une intervention
existe déjà pour le triplet `(vendor, name, id)`, l'existante est renvoyée
(`200 OK`) au lieu d'en créer une seconde (`201 Created`). L'index expose le
bloc `provider` et accepte un filtre `provider_id`. Voir
`docs/api/openapi-v2.yaml` pour le contrat.
