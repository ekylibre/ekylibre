# Workflow — Migration Highcharts → Apache ECharts

**Demande** : remplacer Highcharts par Apache ECharts dans Ekylibre, en limitant au maximum les régressions, et en **conservant l'interface du helper Ruby** (pas de modification des vues HAML).

**Stratégie** : Systematic. Helper Ruby préservé en signature et en nom, c'est la JSON émise qui change. Glue JS réécrite. Migration en une seule PR coordonnée pour éviter un état hybride coûteux à tester.

---

## 1. Inventaire vérifié

| Élément | Localisation | Détail |
|---|---|---|
| Package NPM | `package.json:11` | `highcharts@^9.3.2` |
| Chargement | Sprockets (pas Webpacker) | `app/assets/javascripts/application.js:65` → `chart/highcharts` |
| Glue JS | `app/assets/javascripts/chart/highcharts.js.coffee` (52 lignes) | Widget jQuery UI `$.widget "ui.highchart"` + binding `turbolinks:load`/`cocoon:after-insert`/`cell:load` |
| Modules chargés | `highcharts-more`, `data`, `drilldown`, `exporting`, `export-data`, `treemap`, `accessibility` | drilldown/exporting/treemap/data **chargés mais jamais appelés depuis les vues** — gain net à les laisser tomber |
| Helper Ruby | `app/helpers/charts_helper.rb` (250 lignes) | 14 méthodes générées dynamiquement via `TYPES` (ligne 25) + `COLORS` (148 entrées) + utilitaires (`lightness`, `contrasted_color`, `ligthen`, `formate_and_translate`, `normalize_serie`) |
| Signature helper | `#{type}_highcharts(series, options = {}, html_options = {})` | Émet `<div data-highcharts="<json>">` |
| i18n | `front-end.highcharts.*` | Labels d'export/UI (10 clés) — chargés via `Highcharts.setOptions({lang: I18n.t("front-end.highcharts")})` |
| Tests | `test/helpers/charts_helper_test.rb` | Classe vide, aucun test |

**Plugins** (`/home/djoulin/projects/ekylibre-plugins/`, 21 plugins scannés, **1 seul concerné**) :

| Plugin | Fichier | Type | Particularité |
|---|---|---|---|
| `ekylibre-economic` | `app/views/economic/simulators/_market_price.html.haml:49` | `spline_highcharts` | markers enabled |
| `ekylibre-economic` | `app/views/backend/cells/cash_forecast_cells/show.html.haml:3` | `column_highcharts` | **drilldown réel** (`drilldown: @drilldown`), stacking normal, label `"{total} €"` |
| `ekylibre-economic` | `app/views/backend/cells/economic_charges_by_activity_cells/show.html.haml:3` | `waterfall_highcharts` | stacking, dataLabels format `"{point.y:,.0f} €"` |
| `ekylibre-economic` | `app/assets/javascript/economic_cobble.js:81` | **JS direct** | `Highcharts.charts.find(c => c?.container?.matches('.cobble'))` puis `.series[i].update({data: ...})` — **bypasse le helper** pour muter une série en runtime |

Aucun plugin n'a de gem highcharts ou de package.json local, tous consomment le helper du core. **Trois découvertes qui modifient le plan initial** :
1. **Drilldown n'est pas mort** : 1 view réelle l'utilise (cash_forecast). Doit être traité.
2. **2 waterfalls dans le codebase**, pas 1 (le second est `economic_charges_by_activity_cells`).
3. **Pattern de mutation runtime côté JS** : `Highcharts.charts.find(...).series[i].update(...)`. ECharts n'a pas d'équivalent global comme `Highcharts.charts` — il faut un registre custom.

**Volumétrie utilisation totale (core + plugins)** : 54 appels dans 45 vues.

| Type Highcharts | Core | Plugins | Total | Type ECharts cible | Complexité |
|---|---|---|---|---|---|
| column | 20 | 1 (avec drilldown) | 21 | `bar` (vertical par défaut) | facile (sans drilldown) / **moyen** (avec) |
| pie | 13 | 0 | 13 | `pie` | facile |
| spline | 9 | 1 | 10 | `line` + `smooth: true` | facile |
| bar | 3 | 0 | 3 | `bar` + `xAxis.type='value'` + `yAxis.type='category'` | facile |
| area | 2 | 0 | 2 | `line` + `areaStyle: {}` | facile |
| bubble | 2 | 0 | 2 | `scatter` + `symbolSize` callback | moyen |
| waterfall | 1 | 1 | **2** | bar empilé avec série « support » invisible (recette standard) | **délicat** |
| line | 1 | 0 | 1 | `line` | trivial |
| areaspline / arearange / areasplinerange / columnrange / scatter / packedbubble | 0 | 0 | 0 | — | à droper |

**Modules à abandonner** : exporting (menu contextuel), treemap, data. **À conserver / réimplémenter** : drilldown (1 callsite réel dans `ekylibre-economic`), accessibility (ECharts a son propre support natif).

**License** : Highcharts est dual-license (commercial pour usage prod). ECharts est Apache 2.0 → **suppression d'une dette de licence** non gérée aujourd'hui.

---

## 2. Stratégie retenue

**Helper Ruby conservé en l'état au niveau de l'API publique** : noms de méthodes (`column_highcharts`, `pie_highcharts`, …) **inchangés**, signatures `(series, options = {}, html_options = {})` **inchangées**, palette `COLORS` et utilitaires (`contrasted_color`, etc.) **conservés**.

**Ce qui change à l'intérieur du helper** : la table de correspondance des types et le contenu JSON produit dans l'attribut HTML (qu'on renomme `data-echarts` pour éviter toute confusion runtime). Toutes les vues continuent d'appeler les mêmes méthodes Ruby, sans diff dans le HAML.

**Glue JS** : nouveau widget jQuery `$.widget "ui.echart"`, réplique exacte du pattern actuel (binding `turbolinks:load`/`cocoon:after-insert`/`cell:load`), en remplaçant `element.highcharts(options)` par `echarts.init(element[0]).setOption(options)` + gestion du resize.

**Alternatives écartées** :
- **Adaptateur runtime « Highcharts options → ECharts options » côté JS** : tentant pour ne rien changer côté Ruby, mais le mapping des `tooltip.pointFormat`, `plotOptions.{type}.stacking`, `dataLabels.formatter` est plein de pièges (closures côté Highcharts vs. formatter strings côté ECharts). Plus de surface de bug, moins maintenable.
- **Migration progressive avec nouveaux helpers `*_chart` en parallèle** : laisse le code dans un état hybride pendant des mois, double les chemins à tester, va à l'encontre de la demande « conservation du helper ».

**Renommage `_highcharts` → `_chart`** : *hors scope*. À faire éventuellement dans une PR séparée après stabilisation (54 appels à modifier mécaniquement, faisable au `sed`). On garde les noms actuels pour minimiser le diff de migration.

**Registre de charts pour mutation runtime** : `ekylibre-economic/app/assets/javascript/economic_cobble.js:81` utilise `Highcharts.charts.find(c => c?.container?.matches('.cobble'))` puis `.series[i].update({data: ...})`. ECharts n'a pas d'équivalent `echarts.instances` global. Solution intégrée au widget jQuery : maintenir une `WeakMap` côté glue (`instances = new WeakMap(); instances.set(domNode, chartInstance)`) et exposer `$.echartFor(selector)` qui renvoie l'instance ECharts. Le plugin `ekylibre-economic` est patché en parallèle pour utiliser `$.echartFor('.cobble').setOption({series: [{data: newData}]})`. Modification du plugin = 1 ligne. **Concertation requise avec l'équipe owner du plugin economic avant le merge.**

---

## 3. Phases d'implémentation

### Phase 1 — Ajout d'ECharts comme dépendance

**Fichier** : `package.json`

- Ajouter `"echarts": "^5.5.0"` (dernière 5.x stable, supporte tous nos types).
- **Ne pas supprimer `highcharts` dans la même PR** : on attend la validation manuelle (phase 5).
- `yarn install` dans le conteneur Docker. Vérifier que `node_modules/echarts/dist/echarts.min.js` est résolu par Sprockets (cf. comportement actuel pour Highcharts).

**Validation** : `require 'echarts'` (ou équivalent Sprockets) compile sans erreur.

---

### Phase 2 — Nouveau glue JS

**Nouveau fichier** : `app/assets/javascripts/chart/echarts.js.coffee` (~60 lignes)

Squelette à respecter (réplique du pattern actuel) :

```coffee
#= require echarts/dist/echarts.min

$.widget "ui.echart",
  options:
    # defaults injectés ici (theme couleurs, font, animations…)
  _create: ->
    options = $.extend(true, {}, @options, @element.data("echarts"))
    @chart = echarts.init(@element[0])
    @chart.setOption(options)
    $(window).on "resize.echart-#{@uuid()}", => @chart.resize()
  _destroy: ->
    $(window).off "resize.echart-#{@uuid()}"
    @chart?.dispose()

$.loadECharts = ->
  $("[data-echarts]:not(.echart-loaded)").each ->
    $(@).echart().addClass("echart-loaded")

$(document).on "turbolinks:load cocoon:after-insert cell:load", -> $.loadECharts()
```

**Différences importantes vs. Highcharts** :
- `echarts.init(dom)` exige une **taille définie** sur le `<div>` (height au minimum). Highcharts s'autorésout via mesure interne. → la classe CSS qui porte le helper doit avoir un `height` non nul. Vérifier dans `application.scss` qu'il y a un default genre `.chart { height: 320px; }`. Sinon ajouter une règle de fallback.
- `chart.resize()` à brancher sur `window.resize` ET sur les événements de cellule de dashboard (la "beehive" peut redimensionner ses cells). À vérifier en phase 4.
- Pas de `setOptions` global pour la i18n — ECharts attache la locale via `echarts.registerLocale` (ou via les options par-instance). On charge la locale française une fois au boot.

**Exposition d'un registre pour le pattern « mutation runtime »** (pour `ekylibre-economic`) :

```coffee
instances = new WeakMap()

$.widget "ui.echart",
  _create: ->
    @chart = echarts.init(@element[0])
    instances.set(@element[0], @chart)
    ...
  _destroy: ->
    instances.delete(@element[0])
    @chart?.dispose()

$.echartFor = (selector) ->
  el = $(selector)[0]
  return null unless el
  instances.get(el)
```

API d'usage côté plugin : `$.echartFor('.cobble')?.setOption({series: [{data: newData}]}, false, true)`. Le 3e arg `lazyUpdate: true` évite un re-render complet.

**Modules à requérir côté Sprockets** : juste `echarts/dist/echarts.min` couvre tous nos types. Pas besoin de `echarts-gl`, `echarts-stat`, `echarts-liquidfill`.

**i18n** :
- Importer `echarts/dist/i18n/langFR-obj` (ou équivalent) si la locale FR est utile pour les composants toolbox/dataView. Comme on n'expose ni toolbox ni dataView, la i18n actuelle (`front-end.highcharts.*`) **devient morte**. À documenter dans le PR description ; suppression effective en phase 5.

---

### Phase 3 — Refonte interne de `ChartsHelper`

**Fichier** : `app/helpers/charts_helper.rb`

**Conserver tel quel** :
- Constante `COLORS` (148 entrées)
- `lightness`, `contrasted_color`, `ligthen`, `formate_and_translate`, `normalize_serie`
- Toutes les **signatures publiques** des 14 méthodes (`column_highcharts(series, options, html_options)`, etc.)

**Modifier** :
- Constante `TYPES` (ligne 25) : conserver les clés (`:column`, `:pie`, …) mais leur associer désormais un mapping vers les types ECharts (`:bar`, `:pie`, …). Marquer `:areaspline`, `:arearange`, `:areasplinerange`, `:columnrange`, `:packedbubble`, `:scatter` comme **non implémentés** dans la migration initiale — lever une `NotImplementedError` claire si appelés (0 callsite aujourd'hui, donc safe). À ressortir au cas par cas si un besoin réel émerge.
- Méthode interne qui construit le hash d'options (recherche du nom : probablement `chart_for` ou un private partagé par les 14 méthodes générées via `define_method`). Refonte pour produire une structure ECharts :
  - `xAxis` / `yAxis` (au lieu de `xAxis` Highcharts qui a une sémantique proche mais des clés différentes : `categories` → `data`, `title.text` → `name`).
  - `series: [{ type:, name:, data:, … }]` — la forme est similaire mais : `stacking: 'normal'` → `stack: 'group'` (string commune aux séries empilées).
  - `tooltip` : Highcharts `pointFormat: '{point.y:1f} kg'` → ECharts `formatter: '{c} kg'` (template string simple) OU un `formatter` fonction si la complexité monte. **Décision** : produire des templates strings simples pour 90 % des cas, et tolérer un opt-out via `options[:tooltip][:formatter_raw]` qui passe la chaîne brute si l'appelant veut du JS custom.
  - `legend.enabled: true` → `legend: { show: true }`.
  - `dataLabels.enabled: true` → `label: { show: true }` sur la série concernée.
  - Couleurs : appliquer la palette `COLORS` filtrée via `theme_colors` (déjà présent côté helper) dans `color: [...]` au niveau racine des options.

**Renommage de l'attribut HTML** : `data-highcharts` → `data-echarts`. Cohérent avec le sélecteur du nouveau widget, isole les deux mondes si on veut un rollback rapide en phase 4.

**Mapping ciblé par type** (tableau d'implémentation) :

| Méthode Ruby | ECharts series.type | Options spécifiques à injecter |
|---|---|---|
| `line_highcharts` | `line` | — |
| `spline_highcharts` | `line` | `smooth: true` sur chaque série |
| `area_highcharts` | `line` | `areaStyle: {}` sur chaque série |
| `column_highcharts` | `bar` | — (vertical par défaut) |
| `bar_highcharts` | `bar` | `xAxis.type: 'value'`, `yAxis.type: 'category'` (axes inversés) |
| `pie_highcharts` | `pie` | `radius: '70%'`, `center: ['50%','50%']` |
| `bubble_highcharts` | `scatter` | `symbolSize: (val) => Math.sqrt(val[2]) * k` (k empirique) |
| `waterfall_highcharts` | `bar` empilé | série invisible « placeholder » + série « delta » avec `itemStyle.color` conditionnel (gain/perte). [Recette ECharts officielle](https://echarts.apache.org/examples/en/editor.html?c=bar-waterfall) |

**Coloration positif/négatif waterfall** : à coder dans le helper Ruby (calculer la série placeholder côté Ruby plutôt que côté JS — simplifie le widget, évite un cas spécial). 2 callsites à valider visuellement : `stock_in_ground_cobbles/show.html.haml` (core) et `economic_charges_by_activity_cells/show.html.haml` (plugin economic).

**Drilldown** (1 callsite plugin : `cash_forecast_cells/show.html.haml:3`) :

Highcharts drilldown : on clique sur une barre → la vue se met à jour avec une série sous-jacente passée dans `drilldown.series`. ECharts n'a pas de mécanique « drilldown » native portant le même nom, mais le pattern se reproduit avec `chart.on('click', handler)` + `chart.setOption({ series: [...] })`.

**Décision** : le helper accepte toujours l'option `drilldown:` (compat ascendante avec `column_highcharts(series, drilldown: data, ...)`). Le helper Ruby sérialise les séries de drilldown dans une clé custom de l'attribut JSON (ex. `data-echarts="{ ..., __drilldown: {<series_par_id>} }"`). La glue JS détecte cette clé custom, registre un listener `chart.on('click', ev => { ... })` qui swap les séries quand on clique sur une barre porteuse d'un `drilldown` id. Bouton « retour » à ajouter via `toolbox.feature.myBack` ou un simple `<button>` external.

**Effort** : ~30-50 lignes dans la glue JS, isolées dans une fonction `installDrilldown(chart, drilldownSpec)`. Pas trivial mais reproductible. À implémenter en s'appuyant sur la structure réelle de `@drilldown` envoyée par `cash_forecast_cells` (à inspecter en début de phase 3).

---

### Phase 3b — Patch du plugin `ekylibre-economic`

**Fichier** : `/home/djoulin/projects/ekylibre-plugins/ekylibre-economic/app/assets/javascript/economic_cobble.js`

Ligne 81 : remplacer le pattern Highcharts par le nouveau registre exposé en phase 2 :

```diff
- chart = Highcharts.charts.find(c => c?.container?.matches('.cobble'))
- chart.series[index].update({ data: newData })
+ chart = $.echartFor('.cobble')
+ chart?.setOption({ series: [{ data: newData }] }, false, true) if chart
```

L'API ECharts `setOption(opts, notMerge, lazyUpdate)` avec `notMerge=false` ne remplace que les champs fournis — équivalent fonctionnel d'`update`.

**Coordination** : ce patch vit dans un repo séparé (`ekylibre-plugins/ekylibre-economic`). À mentionner dans la PR core avec un lien vers la PR plugin. Le core ne doit pas être mergé avant que la PR plugin soit prête à merger en parallèle (sinon dashboards economic cassés en prod).

**Validation manuelle** : ouvrir la cobble `cash_forecast` (économique), déclencher l'événement qui mute la série (probablement un changement de filtre ou d'activité), vérifier que le graphe se met à jour sans erreur console.

---

### Phase 4 — Bascule du chargement et validation

**Fichier** : `app/assets/javascripts/application.js:65`

Remplacer `//= require chart/highcharts` par `//= require chart/echarts`.

**Validation manuelle obligatoire** sur les 45 vues qui utilisent le helper (42 core + 3 plugin economic). Pour ne pas y passer la semaine, prioriser par criticité :

1. **Pages plugin `ekylibre-economic`** (à risque max — combinent les cas les moins triviaux) :
   - `cash_forecast_cells/show.html.haml` → **drilldown** (cliquer sur une barre, vérifier le swap de séries, vérifier le retour arrière)
   - `economic_charges_by_activity_cells/show.html.haml` → **waterfall**
   - `economic/simulators/_market_price.html.haml` → spline avec markers + mutation runtime potentielle (cobble.js)
   - Vérifier explicitement la **mutation runtime** déclenchée depuis `economic_cobble.js` après le patch
2. **Le waterfall core** : `stock_in_ground_cobbles/show.html.haml` (sortie ECharts ressemble à la sortie Highcharts ?)
3. **Pages de dashboards (cells)** : `cash_variations_cells`, `stock_movements_cells`, `revenue_cells` — top des views chartées. ~10 cells à ouvrir.
4. **Show interventions** : `interventions/show.html.haml:42` (consommation carburant tracteur, série temporelle).
5. **Worker contracts** : `worker_contracts/show.html.haml:43` (pie).
6. Tournée rapide sur les pies et columns restantes : ouvrir 5-10 vues au hasard, vérifier qu'il n'y a pas de tooltip qui s'écroule.

**Script d'aide** (à ajouter dans la PR, optionnel) : un rake task qui liste tous les chemins d'URL où chaque vue est rendue, pour faciliter la tournée :
```ruby
# lib/tasks/charts_audit.rake
namespace :charts do
  task :audit do
    paths = ['app/views/**/*.haml', '/home/djoulin/projects/ekylibre-plugins/**/app/views/**/*.haml']
    paths.flat_map { |p| Dir.glob(p) }.each do |f|
      if (cnt = File.read(f).scan(/_highcharts/).count) > 0
        puts "#{cnt}  #{f}"
      end
    end
  end
end
```

**Critères de pass** par vue :
- Le graphe s'affiche
- Les axes/légende/tooltip ont les bonnes valeurs
- Les couleurs respectent la palette (vérifier 2-3 vues, pas besoin de toutes)
- Pas d'erreur JS console

---

### Phase 5 — Nettoyage (PR séparée, après validation)

À faire dans une **PR distincte** mergée 1-2 semaines après la PR de migration (laisser un filet de sécurité pour rollback rapide via revert) :

1. `package.json` : supprimer `highcharts`.
2. `yarn.lock` : régénérer.
3. Supprimer `app/assets/javascripts/chart/highcharts.js.coffee`.
4. Supprimer les clés i18n `front-end.highcharts.*` dans tous les locales (eng/fra). Note : la doc CLAUDE.md précise qu'il faut désactiver `Gemfile.local`/`Gemfile.plugins` avant `rake clean:locales`.
5. Mettre à jour la documentation interne (si quelqu'un a un Notion/wiki qui mentionne Highcharts).

---

## 4. Risques connus et mitigations

| Risque | Probabilité | Mitigation |
|---|---|---|
| Hauteur du `<div>` non définie en CSS → ECharts ne dessine pas | Élevée (Highcharts auto-mesurait) | Ajouter `[data-echarts] { min-height: 300px; }` dans `application.scss` en début de phase 4 |
| Cells redimensionnables (beehive dashboard) ne déclenchent pas `chart.resize()` | Moyenne | Le widget écoute déjà `cell:load`. Si insuffisant, brancher un `ResizeObserver` sur l'élément dans `_create` |
| Tooltip avec format `{point.y:1f} %{unit}` traduit imparfaitement en `{c}` | Moyenne | Implémenter un format-converter Ruby simple pour les 3 patterns rencontrés. Sinon fallback : on simplifie à `{c}` et le formatage avancé passe par un `formatter` JS injecté |
| Waterfall ne ressemble pas visuellement à l'ancien | Faible (2 views) | A/B visuel sur `stock_in_ground_cobbles/show.html.haml` (core) ET `economic_charges_by_activity_cells/show.html.haml` (plugin economic). Si trop différent, garder Highcharts pour ces seuls cas en feature flag temporaire le temps d'affiner |
| Drilldown ECharts ne reproduit pas fidèlement le UX Highcharts (transition animée, bouton « back » natif) | Moyenne | Implémenter une transition simple (re-`setOption` avec `animation: true`) + bouton retour custom. Tester sur `cash_forecast_cells`. Si insuffisant, considérer un fallback bar simple (sans drilldown) en mode dégradé |
| Registre `$.echartFor` n'est pas découvert par les plugins / le pattern n'est pas documenté | Faible | Documenter l'API dans un commentaire de tête du fichier `chart/echarts.js.coffee` + mentionner dans le CHANGELOG du core. La PR du plugin `ekylibre-economic` sert d'exemple de référence |
| PR core mergée avant PR plugin → dashboards economic cassés en prod | Élevée si pas coordonné | Coordination explicite des merges. Lister dans la description de la PR core la dépendance vers la PR plugin. Idéalement, déployer les deux dans la même fenêtre |
| Bubble `symbolSize` constant K à calibrer | Faible (2 views) | Tester avec les vraies données. Quitter `Math.sqrt(val[2]) * 5` comme point de départ |
| Stacking column : tooltip total empilé | Faible | ECharts gère via `tooltip.trigger: 'axis'` + axisPointer. À tester sur cash_variations_cells |
| Stimulus/Turbolinks réinit la page → double-init ECharts (memory leak) | Moyenne | Le widget marque `.echart-loaded` (cf. snippet phase 2) ET le `_destroy` appelle `chart.dispose()`. Vérifier qu'aucune cell ne recrée le DOM sans détruire l'instance |
| i18n morte non nettoyée crée du bruit | Faible | Phase 5 documentée ; bug ne bloque rien |
| Types non implémentés (`areaspline`, etc.) appelés par un plugin externe | Très faible | Aucun callsite identifié dans le code core. `NotImplementedError` claire si jamais |

---

## 5. Tests

Pas de tests automatisés sur les helpers actuellement (`test/helpers/charts_helper_test.rb` est vide). **On ne crée pas de fixture exhaustive dans cette PR**, mais on ajoute :

- 1 test minimal par méthode helper qui vérifie que la sortie HTML contient `data-echarts="<json valide>"` avec `series.type` attendu. ~15 lignes, démontre le contrat.
- **Pas de tests JS / capybara** : les system tests Ekylibre sont lourds et la valeur d'un test sur le rendu Canvas est faible. Validation manuelle via phase 4 suffit.

---

## 6. Arbre de dépendances

```
Phase 1 (yarn add)   ─┐
                      ├─► Phase 3  (helper Ruby) ─┐
Phase 2 (glue JS)   ──┤                            │
                      │                            ├─► Phase 4 (bascule + valid.) ─► Phase 5 (cleanup, PR séparée)
Phase 3b (plugin economic) ─────────────────────── ┤   ⚠ merger plugin+core ensemble
                      │                            │
Tests minimaux ────────────────────────────────────┘
```

Phases 1, 2, 3, 3b parallélisables. Phase 4 dépend du tout. Phase 5 attend la fenêtre de stabilisation. **Coordination cruciale entre la PR core et la PR `ekylibre-economic`** : merger les deux dans la même fenêtre.

---

## 7. Critères d'acceptation

1. ✅ Les **54 callsites** du helper (51 core + 3 plugin economic) continuent de fonctionner sans modification du HAML.
2. ✅ Les 8 types réellement utilisés (`column`, `pie`, `spline`, `bar`, `area`, `bubble`, `waterfall`, `line`) rendent un graphe visuellement équivalent (axes, légende, tooltip, couleurs).
3. ✅ Aucune erreur JS dans la console sur les pages de référence (cells dashboard, intervention show, worker contract show, stock_in_ground_cobbles, variants/shared/_show_stocks, **les 3 vues plugin economic**).
4. ✅ Les graphes survivent à un Turbolinks navigation back/forward sans double-instantiation.
5. ✅ Le helper accepte toujours `(series, options = {}, html_options = {})`.
6. ✅ Le drilldown sur `cash_forecast_cells` fonctionne (clic → swap de séries → retour).
7. ✅ La mutation runtime depuis `economic_cobble.js` via `$.echartFor('.cobble')` fonctionne.
8. ✅ `highcharts` est toujours présent dans `package.json` à la fin de la phase 4 (cleanup en phase 5).
9. ✅ La licence ECharts (Apache 2.0) est compatible AGPLv3 d'Ekylibre — vérifié.

---

## 8. Fichiers touchés (synthèse)

**PR core (`ekylibre`)** :

| Fichier | Phase | Action |
|---|---|---|
| `package.json` | 1 | Ajouter `echarts` |
| `app/assets/javascripts/chart/echarts.js.coffee` | 2 | Nouveau (avec `WeakMap` `instances` + `$.echartFor`) |
| `app/assets/javascripts/application.js` | 4 | `chart/highcharts` → `chart/echarts` |
| `app/helpers/charts_helper.rb` | 3 | Refonte interne (signatures conservées), `data-highcharts` → `data-echarts`, support `drilldown:` |
| `app/assets/stylesheets/...` (à identifier) | 4 | Ajouter `[data-echarts] { min-height: 300px; }` si besoin |
| `test/helpers/charts_helper_test.rb` | 3 | Tests minimaux (15 lignes) |
| `lib/tasks/charts_audit.rake` | 4 | Optionnel — aide à la tournée |
| **Aucune vue HAML** | — | Conservation stricte de l'API helper |

**PR plugin (`ekylibre-plugins/ekylibre-economic`)** :

| Fichier | Phase | Action |
|---|---|---|
| `app/assets/javascript/economic_cobble.js` | 3b | Ligne 81 : `Highcharts.charts.find(...)` → `$.echartFor('.cobble')` ; ligne 86 : `.series[i].update({data})` → `.setOption({series: [{data}]}, false, true)` |

**PR de cleanup (séparée, 1-2 semaines après merge)** :
- `package.json` : retirer `highcharts`
- `app/assets/javascripts/chart/highcharts.js.coffee` : supprimer
- `config/locales/{eng,fra}/*.yml` : supprimer `front-end.highcharts.*` (10 clés)

---

## 9. Prochaine étape

Lancer `/sc:implement claudedocs/workflow_highcharts_to_echarts.md` quand tu es prêt. La phase 4 (validation manuelle des 42 vues) est le gros morceau — prévoir une session dédiée plutôt que de l'intégrer dans un sprint chargé.

Question ouverte avant impl. : tu veux qu'on conserve les noms `*_highcharts` ou tu profites de la migration pour les renommer en `*_chart` (51 callsites à toucher, mécanique au `sed`) ? Je recommande **garder** pour limiter le diff ; le rename peut se faire dans une 3e PR cosmétique.
