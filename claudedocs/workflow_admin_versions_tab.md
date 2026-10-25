# Workflow — Onglet « Versions » dans /admin

**Statut** : Plan uniquement (à exécuter via `/sc:implement`)
**Auteur** : Claude Code — `/sc:workflow`
**Date** : 2026-06-22
**Branche cible** : `5.0-beta`

---

## 1. Objectif

Ajouter, dans l'interface d'administration `/admin`, un nouvel onglet **Versions** affichant :

1. La version actuelle d'Ekylibre (lue depuis le fichier `VERSION` via `Ekylibre::VERSION`).
2. La liste de tous les plugins chargés depuis `Gemfile.local` ou `Gemfile.prod` dont la source est de la forme `https://github.com/ekylibre/<slug>` (qu'il s'agisse de `git:` ou `github:`).

Pour chaque plugin : nom de la gem, slug GitHub, branche / révision verrouillée, et version (si exposée par la gem chargée).

---

## 2. Contraintes & contexte du dépôt

- `/admin` est servi par `Admin::BaseController` (`app/controllers/admin/base_controller.rb`) avec auth HTTP Basic et layout `admin` (sans tenant Apartment, hors elevator).
- Toute la page admin actuelle est **une seule vue à onglets CSS-only** : `app/views/admin/tenants/index.html.haml` (882 lignes, 4 onglets : Tenants / Démo / Restaurer / Lexicon). Le mécanisme repose sur `<input type="radio" name="admin-tab">` + sélecteurs `:checked ~`.
- Les Gemfiles d'extension sont chargés dynamiquement par `Gemfile:267-273` :
  ```ruby
  gemfiles = Dir.glob('{plugins/*/Gemfile,Gemfile.*}')
  ```
  → **`Gemfile.local` ET `Gemfile.prod`** (s'il existe) sont tous deux pris en compte.
- Les plugins Ekylibre déclarés actuellement (cf. `Gemfile.local`) utilisent deux formes :
  - `gem 'foo', git: 'https://github.com/ekylibre/<slug>.git', branch: '...'`
  - `gem 'bar', github: 'ekylibre/<slug>', branch: '...'` (résolu par `git_source(:github)` en `https://github.com/.../...git`)
  - **À ignorer** : entrées avec `path:` (plugins montés en local), gems hors org `ekylibre`.
- Source de la version Ekylibre : `lib/ekylibre/version.rb` → `Ekylibre::VERSION` (lit `VERSION` à la racine, actuellement `5.0-beta`).
- L'admin est entièrement en français (UI), pas de I18n (chaînes en dur dans la vue actuelle).

### Source de vérité pour la liste des plugins

Trois options évaluées :

| Source | Avantages | Inconvénients | Décision |
|---|---|---|---|
| Parsing brut de `Gemfile.local` / `Gemfile.prod` | Filtre exactement ce que demande l'énoncé | Réimplémente le parser Bundler, fragile (DSL, commentaires, `path:`/`git:`) | ❌ |
| `Bundler.locked_gems.sources` (lecture de `Gemfile.lock`) | Données déjà résolues (revision, branch, URI) | Ne dit pas dans quel Gemfile la gem est déclarée | ⚠️ Complément |
| `Bundler.definition.dependencies` + `.specs` (mémoire du process) | Expose `dependency.source` (instance `Bundler::Source::Git`) et `gemfile` (path du fichier d'origine) | Nécessite `Bundler.setup` déjà fait (toujours vrai en runtime Rails) | ✅ **Retenu** |

**Approche choisie** : itérer `Bundler.definition.dependencies`, filtrer celles dont `dep.source.is_a?(Bundler::Source::Git)` ET dont `dep.source.uri` matche `%r{\Ahttps://github\.com/ekylibre/}`, ET dont `dep.gemfile.to_s.end_with?('Gemfile.local', 'Gemfile.prod')` (le `gemfile` est tracé par Bundler lors de l'`eval_gemfile`). Ensuite on enrichit avec `Bundler.definition.specs[dep.name].first` pour la version et la revision verrouillée.

---

## 3. Découpage de l'implémentation

### Phase 1 — Backend : service de collecte

**Fichier neuf** : `app/services/admin/plugins_inspector.rb`

Responsabilités :
- Exposer une classe `Admin::PluginsInspector` avec une méthode `#call` retournant un `Struct` :
  ```ruby
  Result = Struct.new(:ekylibre_version, :plugins, keyword_init: true)
  Plugin = Struct.new(:name, :slug, :gemfile, :branch, :revision, :short_revision, :gem_version, :uri, keyword_init: true)
  ```
- Logique :
  1. `ekylibre_version = Ekylibre::VERSION.to_s.strip`
  2. `Bundler.definition.dependencies.select { |d| eligible_source?(d) && eligible_gemfile?(d) }`
  3. Pour chaque dep, croiser avec `Bundler.definition.specs[dep.name]` pour récupérer `version`, `revision`, `branch`.
  4. Trier par `slug` alpha croissant.
- Méthodes privées :
  - `eligible_source?(dep)` : `dep.source.is_a?(Bundler::Source::Git)` et URI matche `%r{\Ahttps?://github\.com/ekylibre/([\w.-]+?)(?:\.git)?\z}` → mémoriser le slug en groupe capturant.
  - `eligible_gemfile?(dep)` : `File.basename(dep.gemfile.to_s)` ∈ `%w[Gemfile.local Gemfile.prod]`.
- Robustesse :
  - Toutes les lookups Bundler dans des `rescue StandardError` qui dégradent vers `nil` (pas de crash de la page admin si Bundler indisponible).
  - Pas de cache : 1× au load de la page, l'inspection prend < 50 ms et permet de voir l'effet d'un `bundle install` sans redémarrer.

**Tests** (`test/services/admin/plugins_inspector_test.rb`) :
- Cas heureux : avec le `Gemfile.local` réel du dépôt, on doit récupérer au moins `ekylibre-baqio`, `ekylibre-banking`, `weenat`, `sencrop`, etc.
- Filtrage : un `gem 'foo', path: '...'` ne doit pas remonter ; un `gem 'rails'` (source rubygems) non plus.
- Tri : ordre alpha sur `slug`.
- Aucune dep réseau : pas de stub HTTP, on lit l'état Bundler en mémoire.

---

### Phase 2 — Backend : exposition dans le controller

**Choix d'implémentation** : créer un controller dédié pour éviter de gonfler `TenantsController`.

**Fichier neuf** : `app/controllers/admin/versions_controller.rb`

```ruby
class Admin::VersionsController < Admin::BaseController
  def show
    result = Admin::PluginsInspector.new.call
    @ekylibre_version = result.ekylibre_version
    @plugins = result.plugins
  end
end
```

**Routes** (`config/routes.rb:8-30`, dans `namespace :admin do`) — ajouter :
```ruby
get 'versions', to: 'versions#show', as: :versions
```

→ URL finale : `GET /admin/versions`.

**Pourquoi un controller séparé** : permet, plus tard, d'ajouter d'autres vues (changelog, statut Sidekiq, etc.) sans recharger toute la page Tenants. Le coût est faible (5 lignes de controller + 1 ligne de route).

---

### Phase 3 — Vue : intégration dans l'onglet existant

**Décision UX** : la page admin actuelle est mono-vue (`tenants#index`) avec 4 onglets CSS. Pour rester cohérent avec l'existant, **on ajoute un 5ᵉ onglet « Versions »** dans la même vue plutôt que de créer une route séparée.

Conséquence sur la Phase 2 : on **ne crée pas** de route `/admin/versions` séparée ; on charge les données depuis `Admin::TenantsController#index` (méthode `load_versions_data` privée qui appelle `Admin::PluginsInspector`).

⚠️ **Arbitrage à valider lors de `/sc:implement`** :
- **Option A (recommandée)** — 5ᵉ onglet dans `tenants#index` : cohérent avec l'UX actuelle, pas de route nouvelle, panneau visible sans changer de page. Coût : +1 méthode privée dans `TenantsController`.
- **Option B** — route + vue dédiée `/admin/versions` : plus propre architecturalement, mais casse le pattern « tout en onglets » et oblige à dupliquer la chrome (titre, layout). Suggéré uniquement si on prévoit d'autres pages admin à court terme.

→ **Plan finalisé sur l'Option A**. Phase 2 simplifiée :

**Modification de `app/controllers/admin/tenants_controller.rb`** :
- Ajouter dans `index` (après `load_lexicon_data`) :
  ```ruby
  load_versions_data
  ```
- Ajouter en `private` :
  ```ruby
  def load_versions_data
    result = Admin::PluginsInspector.new.call
    @ekylibre_version = result.ekylibre_version
    @plugins = result.plugins
  rescue StandardError => e
    Rails.logger.warn("[Admin::Versions] #{e.class}: #{e.message}")
    @ekylibre_version = Ekylibre::VERSION rescue nil
    @plugins = []
  end
  ```

**Modification de `app/views/admin/tenants/index.html.haml`** :

1. **Ligne 13-23 (CSS)** — ajouter `#tab-versions` aux sélecteurs `:checked ~` :
   ```css
   #tab-tenants:checked ~ .tabs-nav label[for="tab-tenants"],
   ...
   #tab-versions:checked ~ .tabs-nav label[for="tab-versions"] { ... }
   #tab-tenants:checked ~ #panel-tenants,
   ...
   #tab-versions:checked ~ #panel-versions { display: block; }
   ```

2. **Ligne 87-90 (radios)** — ajouter :
   ```haml
   %input#tab-versions.tab-radio{ type: 'radio', name: 'admin-tab' }
   ```

3. **Ligne 92-96 (nav)** — ajouter :
   ```haml
   %label{for: 'tab-versions'} Versions
   ```

4. **À la fin de la vue (après `#panel-lexicon`)** — ajouter :
   ```haml
   #panel-versions.tab-panel
     %h1 Versions
     #versions-card
       %h3 Ekylibre
       .versions-meta
         %span.label Version actuelle
         %span.value.active= @ekylibre_version.presence || 'inconnue'

       .versions-section
         %h3 Plugins ekylibre/* chargés
         - if @plugins.blank?
           %p.empty Aucun plugin ekylibre/* détecté dans Gemfile.local ou Gemfile.prod.
         - else
           %table
             %thead
               %tr
                 %th Nom
                 %th Slug GitHub
                 %th Branche
                 %th Révision
                 %th Version gem
                 %th Source
             %tbody
               - @plugins.each do |p|
                 %tr
                   %td= p.name
                   %td
                     %a{href: p.uri, target: '_blank', rel: 'noopener'}= p.slug
                   %td= p.branch.presence || '—'
                   %td
                     - if p.short_revision.present?
                       %code{title: p.revision}= p.short_revision
                     - else
                       —
                   %td= p.gem_version.presence || '—'
                   %td= File.basename(p.gemfile.to_s)
   ```

5. **CSS additionnel** (à insérer dans le bloc `:css` du haut, après le `#lexicon-card`) :
   ```css
   #versions-card { background:white; border-radius:6px; box-shadow:0 1px 3px rgba(0,0,0,.1); padding:24px; }
   #versions-card h3 { margin: 0 0 12px; font-size: 1.05em; color:#333; }
   .versions-meta { font-size: 0.95em; margin-bottom: 8px; }
   .versions-meta .label { color:#666; display:inline-block; min-width: 180px; }
   .versions-meta .value { font-weight: 600; color:#333; }
   .versions-meta .value.active { color:#4a7c59; }
   .versions-section { border-top:1px solid #eee; margin-top:18px; padding-top:18px; }
   #versions-card table code { font-family: monospace; background:#f5f5f5; padding:2px 6px; border-radius:3px; font-size:0.85em; }
   #versions-card .empty { color:#888; font-style:italic; }
   ```

---

### Phase 4 — Tests

**Modèle / service** (`test/services/admin/plugins_inspector_test.rb`) :
- `test_filters_to_ekylibre_github_sources`
- `test_filters_to_gemfile_local_and_gemfile_prod_only`
- `test_excludes_path_sources` (les `gem 'idea', path: '/ekylibre-plugins/...'` ne doivent PAS apparaître)
- `test_sorts_plugins_by_slug`
- `test_exposes_ekylibre_version`

**Controller** (`test/controllers/admin/tenants_controller_test.rb`) :
- `test_index_assigns_ekylibre_version_and_plugins`

Pas de test fonctionnel JS — l'onglet est CSS-only.

---

### Phase 5 — Vérification manuelle

```bash
docker compose -f docker/dev/docker-compose.yml up -d
# Naviguer → http://localhost:3000/admin
# Auth basic (ADMIN_USERNAME / ADMIN_PASSWORD du .env)
# Cliquer sur l'onglet "Versions"
# Vérifier :
#   - "Version actuelle" = contenu de VERSION (actuellement 5.0-beta)
#   - Le tableau liste au minimum : ekylibre-baqio, ekylibre-ednotif,
#     ekylibre-banking, ekylibre-qonto, ekylibre-samsys, weenat,
#     sencrop, ekylibre-economic, ekylibre-natuition.
#   - Les gems en `path:` (hajimari, idea, ekylibre_ekyviti,
#     agro_monitoring, ekylibre-traccar, ekylibre_hve) sont ABSENTS.
#   - Les liens GitHub s'ouvrent dans un nouvel onglet.
#   - Le sélecteur d'onglet « Versions » bascule bien le panneau visible.
```

---

## 4. Risques & points d'attention

1. **`Bundler.definition.dependencies[i].gemfile`** : ce champ existe depuis Bundler 1.13. Le dépôt utilise Ruby 2.6.6 → Bundler ≥ 2.1, donc OK. Tester quand même en `rescue` au cas où une dep n'aurait pas `.gemfile`.
2. **Plugins déclarés via `gem '...', github: 'ekylibre/...'`** : la DSL `git_source(:github)` (Gemfile:5-8) les normalise en `https://github.com/ekylibre/<slug>.git`. Le regex de filtrage doit donc tolérer le suffixe `.git` optionnel.
3. **Gems sans branch explicite** : Bundler peut renvoyer `nil` pour `branch`. La vue affiche `—` dans ce cas.
4. **Performance** : l'inspection ajoute ~30 ms au load de `/admin`. Acceptable (pas de cache nécessaire).
5. **Sensibilité** : aucune donnée privée exposée (les URLs github.com/ekylibre/ sont publiques). Conformité OK.

---

## 5. Critères d'acceptation

- [ ] L'onglet « Versions » apparaît à droite de « Lexicon » dans `/admin`.
- [ ] La version Ekylibre affichée correspond au contenu du fichier `VERSION` à la racine.
- [ ] Le tableau liste exactement les gems déclarées dans `Gemfile.local` ou `Gemfile.prod` avec `git: 'https://github.com/ekylibre/...'` (ou équivalent `github:`).
- [ ] Les gems déclarées en `path:` n'apparaissent pas, même si elles sont dans les mêmes Gemfiles.
- [ ] Le tableau affiche : nom, slug (cliquable → GitHub), branche, révision courte (avec hash complet en `title`), version gem, fichier source (`Gemfile.local` ou `Gemfile.prod`).
- [ ] Tests verts : `bundle exec ruby -Itest test/services/admin/plugins_inspector_test.rb` + `test/controllers/admin/tenants_controller_test.rb`.
- [ ] Aucune régression sur les 4 onglets existants (radio default reste sur Tenants).

---

## 6. Récapitulatif des fichiers touchés

| Type | Chemin | Action |
|---|---|---|
| Service | `app/services/admin/plugins_inspector.rb` | **Créer** |
| Controller | `app/controllers/admin/tenants_controller.rb` | **Modifier** (ajout `load_versions_data`) |
| Vue | `app/views/admin/tenants/index.html.haml` | **Modifier** (radio + nav + panel + CSS) |
| Test | `test/services/admin/plugins_inspector_test.rb` | **Créer** |
| Test | `test/controllers/admin/tenants_controller_test.rb` | **Modifier** (assert `@plugins`, `@ekylibre_version`) |

**Aucune migration**, aucun changement de routes (Option A), aucune nouvelle dépendance.

---

## 7. Étape suivante

Lancer `/sc:implement` en pointant ce document pour exécuter les phases dans l'ordre :
1. Service + tests service
2. Controller (méthode privée)
3. Vue (radio, nav, panel, CSS)
4. Tests controller
5. Vérification manuelle dans le navigateur
