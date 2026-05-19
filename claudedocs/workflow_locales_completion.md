# Workflow — Réordonnancement & complétion des traductions

**Date**: 2026-05-19
**Branche**: 5.0-beta
**Périmètre**: `config/locales/**` et `lib/clean/locales.rb`
**Stratégie**: systematic / depth: deep
**Statut**: PLAN UNIQUEMENT — aucune exécution. Voir `/sc:implement` pour passer à la mise en œuvre.

---

## 1. Contexte & état des lieux

### 1.1 Inventaire des locales (sortie filesystem)

| Locale | Fichiers `.yml` | Taille | Statut |
|--------|-----------------|--------|--------|
| `fra`  | 21              | 5,2 M  | **Référence** — la plus complète (inclut `exchangers/`, `help/`, `reporting/`) |
| `eng`  | 19              | 880 K  | Sous-ensemble proche |
| `ita`  | 15              | 344 K  | Sous-ensemble basique |
| `por`  | 15              | 340 K  | Sous-ensemble basique |
| `cmn`  | 15              | 312 K  | Sous-ensemble basique |
| `jpn`  | 15              | 340 K  | Sous-ensemble basique |
| `arb`  | 15              | 472 K  | Sous-ensemble basique (2 placeholders `(((…)))`) |
| `deu`  | 15              | 332 K  | Sous-ensemble basique |
| `spa`  | 15              | 352 K  | Sous-ensemble basique |

> Le glob de `clean_from!` est `Dir.glob('config/locales/<ref>/*.yml')`. Avec `fra` comme référence, **toutes** les locales devraient recevoir les 21 fichiers — il existe donc une dérive entre l'état réel et l'état attendu.

### 1.2 Fichiers présents uniquement dans `fra`

- `email_templates.yml`
- `xsd_errors.yml`
- Le sous-dossier `exchangers/` (non capturé par le glob `*.yml`)

### 1.3 Fichiers présents dans `fra` + `eng` mais absents ailleurs

- `interbank_transaction_codes.yml`
- `lexicon.yml`
- `nomenclatures.yml`
- `tooltips.yml`

### 1.4 Niveau de complétion (lignes commentées `# clé:` ≈ traductions manquantes)

| Locale | Lignes manquantes (approx.) |
|--------|-----------------------------|
| fra    | 248 (placeholders internes) |
| eng    | 1 463 |
| arb    | 1 735 (+ 2 marqueurs `(((…)))`) |
| por    | 1 902 |
| jpn    | 1 915 |
| spa    | 1 915 |
| cmn    | 1 938 |
| ita    | 1 964 |
| deu    | 2 098 |

**Hotspots par fichier** (toutes locales sauf fra/eng) :
1. `action.yml` — 1100-1280 lignes manquantes
2. `models.yml` — 480-650 lignes manquantes
3. `access.yml` — 6-15 lignes manquantes
4. `support.yml` — 2-5 lignes manquantes

### 1.5 Module `Clean::Locales` — méthodes existantes

`lib/clean/locales.rb` (793 lignes) expose :

- `Translation#clean!` → régénère, pour la locale de référence, les fichiers gérés par méthodes dédiées :
  - `clean_access!`, `clean_action!`, `clean_aggregators!`, `clean_enumerize!`, `clean_exchangers!`, `clean_models!`, `clean_nomenclatures!`, `clean_procedures!`
  - + `clean_file!` (pass-through trié) sur : `devise`, `devise.views`, `exceptions`, `formats`, `mailers`, `support`
- `Translation#clean_from!(ref_locale)` → pour chaque locale ≠ référence :
  - Itère sur `Dir.glob('config/locales/<ref>/*.yml')`
  - Crée le fichier cible vide s'il n'existe pas
  - Appelle `Clean::Support.hash_diff` → marque les clés manquantes avec `missing_prompt` (`'# '`)
- `Clean::Locales.run!(reference = I18n.default_locale)` → orchestrateur

**Fichiers présents dans `fra` mais NON traités par `clean!`** (donc passent en pass-through implicite via `clean_from!` mais ne sont jamais triés/régénérés pour `fra`) :

- `email_templates.yml`
- `interbank_transaction_codes.yml`
- `lexicon.yml`
- `navigation.yml`
- `tooltips.yml`
- `transitions.yml`
- `xsd_errors.yml`
- Le contenu du sous-dossier `exchangers/` (le glob `*.yml` ne descend pas)

### 1.6 Tâche Rake

`lib/tasks/clean/locales.rake` :

```ruby
namespace :clean do
  desc 'Update and sort translation files'
  task locales: :environment do
    Clean::Locales.run!
  end
end
```

---

## 2. Objectifs

| # | Objectif | Mesure d'acceptation |
|---|----------|----------------------|
| O1 | **Réordonner** tous les YAML de `config/locales/<loc>/*.yml` de manière déterministe | Diff `git` ne montre plus que des réordonnancements lors de la 2ᵉ exécution consécutive de `rake clean:locales` |
| O2 | **Synchroniser le jeu de fichiers** entre toutes les locales (chaque locale possède la même liste que `fra`) | `ls config/locales/<loc>` renvoie le même set pour les 9 locales |
| O3 | **Compléter les traductions manquantes** pour `eng` à 100 %, puis les autres locales par priorité décroissante | Compteurs `missing_prompt` lignes = 0 par locale traitée |
| O4 | **Adapter `lib/clean/locales.rb`** pour couvrir les fichiers actuellement non traités et le sous-dossier `exchangers/` | Méthodes `clean_*` dédiées ajoutées ou `clean_file!` étendu ; nouveau test idempotence |
| O5 | **Pas de régression** : aucune clé existante n'est perdue, le rendu UI reste identique pour les locales déjà complètes | Tests Minitest verts ; capture visuelle de quelques pages backend par locale |

---

## 3. Phases d'exécution

### Phase 0 — Préparation & filet de sécurité

1. **Branche dédiée** depuis `5.0-beta` : `chore/locales-completion`.
2. **Snapshot** de `config/locales/` (commit baseline) pour pouvoir mesurer le diff fonctionnel par phase.
3. **Smoke test** : démarrer l'app Docker et basculer la locale (fra/eng/ita) sur une page représentative (`/backend/dashboards`, `/backend/products`, `/backend/interventions/new`).
4. **Mesure initiale** : générer `claudedocs/locales_baseline.txt` avec, par locale et par fichier, le nombre de lignes commentées et le total.

**Sortie** : baseline reproductible, branche prête.

---

### Phase 1 — Audit & extension de `lib/clean/locales.rb`

> Objectif : avant de toucher au contenu, fiabiliser l'outil qui le produit. C'est lui qui définit l'ordre canonique.

#### 1.1 Couverture des fichiers orphelins

Ajouter dans `Translation#clean!` (après la liste actuelle) des appels `clean_file!` pour les fichiers passe-through actuellement orphelins :

```ruby
clean_file! 'email_templates'
clean_file! 'interbank_transaction_codes'
clean_file! 'lexicon'
clean_file! 'navigation'
clean_file! 'tooltips'
clean_file! 'transitions'
clean_file! 'xsd_errors'
```

Critère de décision par fichier :
- Si le fichier n'a **pas** de source dynamique (ex : `xsd_errors.yml`, `interbank_transaction_codes.yml`, `email_templates.yml`) → `clean_file!` (tri + comptage) suffit.
- Si le fichier reflète un état runtime (`navigation.yml` ↔ menu, `tooltips.yml` ↔ vues) → envisager une méthode dédiée `clean_navigation!` / `clean_tooltips!` qui parcourt la source de vérité (cf. `Clean::Support.look_for_*`).

#### 1.2 Sous-dossier `exchangers/`

Étendre `clean_from!` pour gérer les fichiers à un niveau imbriqué :

```ruby
Dir.glob(Rails.root.join('config', 'locales', reference_locale.to_s, '**', '*.yml')).sort.each do |reference_path|
  relative = reference_path.sub("#{Rails.root.join('config', 'locales', reference_locale.to_s)}/", '')
  target_path = Rails.root.join('config', 'locales', locale.to_s, relative)
  FileUtils.mkdir_p(target_path.dirname)
  # ... même logique qu'aujourd'hui
end
```

Et écrire la méthode `clean_exchangers_subdir!` (ou intégrer dans `clean_exchangers!`) qui itère sur les exchangers et produit un fichier par exchanger sous `<loc>/exchangers/<name>.yml`. Vérifier au préalable la convention utilisée pour les fichiers existants dans `fra/exchangers/`.

#### 1.3 Idempotence

Ajouter (ou compléter) un test Minitest sous `test/lib/clean/locales_test.rb` :

- Cas 1 : exécuter `Clean::Locales.run!` deux fois, le 2ᵉ run ne doit produire **aucun diff**.
- Cas 2 : injecter une clé fictive `labels.foo_bar` dans un fichier source (vue HAML) et vérifier qu'elle apparaît dans `fra/action.yml` sous `labels:` après exécution.
- Cas 3 : retirer une clé orpheline et vérifier qu'elle est marquée `#?` ou retirée selon la politique en vigueur.

#### 1.4 Robustesse

- `load_file` capture toutes les exceptions silencieusement (`rescue ... {}`). À remplacer par un `rescue Psych::SyntaxError => e ; warn(...) ; {}` pour signaler les YAML cassés.
- `private def self.translate_or_nil` (ligne 47) déclare `def self.` à l'intérieur d'un `private def …` : à corriger en `private def translate_or_nil(*args)` (méthode d'instance) — comportement actuel possiblement non-private.
- Ajout d'un mode `--dry-run` à la tâche rake pour produire un rapport sans écrire.

#### 1.5 Préserver la rétrocompat

- L'API publique (`Clean::Locales.run!`, méthodes d'instance utilisées par les rake tasks) reste inchangée.
- Les fichiers générés gardent leur structure top-level (`<locale>:\n …`) — c'est ce qui est attendu par Rails I18n.

**Sortie phase 1** : tool fiabilisé, capable de générer une sortie déterministe couvrant l'ensemble du périmètre.

---

### Phase 2 — Régénération de la référence (`fra`)

> Important : `fra` est traité différemment des autres. `clean!` régénère les fichiers via méthodes dédiées et **introduit** les nouvelles clés depuis le code (labels HAML, notifications, REST actions, etc.). C'est l'étape qui définit la "vérité" à propager.

1. Lancer dans le container Docker :
   ```
   docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake clean:locales
   ```
2. Revue manuelle du diff `git diff config/locales/fra/` :
   - Nouvelles clés (`# nouvelle_cle:`) → à traduire en français immédiatement, c'est la source.
   - Clés orphelines marquées `#?` → décider suppression vs conservation.
3. Compléter les 248 entrées manquantes de `fra` (placeholders internes). Itérer par fichier : `action.yml` (75) → `models.yml` (150) → autres.
4. Commit : `chore(locales): regenerate fra reference and fill missing keys`.

**Checkpoint** : `fra` est à 100 %, structure définitive arrêtée.

---

### Phase 3 — Propagation de la structure aux locales secondaires

1. Lancer `rake clean:locales` à nouveau — `clean_from!(:fra)` s'exécute pour chacune des 8 autres locales.
2. Résultats attendus :
   - Création des fichiers manquants : `email_templates.yml`, `interbank_transaction_codes.yml`, `lexicon.yml`, `nomenclatures.yml`, `tooltips.yml`, `xsd_errors.yml` (+ sous-dossier `exchangers/` après extension du glob en phase 1.2) pour les 7 locales lacunaires.
   - Ajout des clés manquantes commentées avec `# ` dans chaque fichier.
3. Commit : `chore(locales): sync file structure across all locales from fra`.

**Checkpoint** :
- `ls config/locales/<loc>` identique pour toutes les locales.
- Le diff de la 2ᵉ exécution est vide → ordonnancement stable.

---

### Phase 4 — Complétion des traductions

> Ordre de priorité fondé sur les usages métier et la complétude actuelle.

#### 4.1 Priorisation (proposée)

| Lot | Locale(s) | Justification |
|-----|-----------|---------------|
| L1  | `eng`     | Locale internationale par défaut, déjà la plus avancée |
| L2  | `spa`, `por` | Forte base d'utilisateurs agricoles hispano/lusophones |
| L3  | `deu`, `ita` | Marchés européens existants |
| L4  | `cmn`, `jpn`, `arb` | Locales étendues, vérification RTL pour `arb` |

#### 4.2 Sources de traduction (à valider avec le métier)

Options à présenter :
- A. **Traduction humaine ciblée** — traducteurs internes / partenaires (qualité maximale, lent).
- B. **DeepL/MT pré-traduction** puis revue humaine — bon compromis.
- C. **Mémoire de traduction existante** — exporter `fra` + `eng` complets, alimenter une TM (Trados/Crowdin) puis ré-importer.
- D. **Crowdin / Phrase** — workflow continu, suppose une intégration CI.

> ⚠ Cette décision n'est pas tranchée dans le code ; à arbitrer avec l'équipe avant exécution.

#### 4.3 Pour `arb` (RTL)

- Vérifier que `i18n.rb` déclare `dir: 'rtl'` et que les vues backend gèrent les CSS direction-aware.
- Résoudre les 2 placeholders `(((…)))` détectés.

#### 4.4 Pour chaque locale

Boucle :
1. Choisir un fichier (commencer par les plus impactants : `action.yml`, `models.yml`, `access.yml`).
2. Décommenter et traduire les clés `# clé:`.
3. Relancer `rake clean:locales` après chaque fichier → garantit le tri stable.
4. Lancer `bundle exec rake test` (ciblé sur les helpers I18n s'il en existe).
5. Smoke test UI dans la locale.
6. Commit par fichier ou par bloc cohérent.

**Checkpoint par locale** : `grep -cE "^\s*#\s+[a-zA-Z_]" config/locales/<loc>/*.yml` = 0.

---

### Phase 5 — Validation finale

1. **Idempotence** : `rake clean:locales` exécuté deux fois → 2ᵉ run vide.
2. **Tests** :
   ```
   docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake test
   ```
3. **Test I18n statique** : script de vérif (existe-t-il déjà via `i18n-tasks` ? sinon en créer un ad-hoc) qui détecte :
   - Clés utilisées dans le code mais absentes dans toutes les locales.
   - Clés présentes dans `fra` mais absentes dans une autre (alors qu'elles devraient être marquées `# `).
4. **Validation visuelle** par locale sur les pages clés (dashboard, intervention, comptabilité, lexicon admin).
5. **Documentation** : mise à jour du `CLAUDE.md` (section "Translations" à créer) avec :
   - Workflow de mise à jour (`rake clean:locales`).
   - Convention `missing_prompt`.
   - Pipeline de traduction adopté.
6. **PR finale** vers `5.0-beta` : titre `chore(locales): re-order and complete translations across all locales`.

---

## 4. Dépendances & ordre canonique

```
Phase 0 (prep)
   └─> Phase 1 (clean/locales.rb extension)
          └─> Phase 1 tests verts
                 └─> Phase 2 (fra regen + completion)
                        └─> Phase 3 (propagation structure)
                               └─> Phase 4 (traductions par lot L1→L4)
                                      └─> Phase 5 (validation)
```

- Les lots L1-L4 de la phase 4 sont **parallélisables** (locales indépendantes) une fois la phase 3 terminée.
- Tout changement en phase 4 sur une locale `<loc>` doit être suivi d'un `rake clean:locales` pour rester en forme canonique.

---

## 5. Risques & mitigations

| Risque | Impact | Mitigation |
|--------|--------|------------|
| `clean!` introduit de nouvelles clés non encore présentes → diff massif en `fra` | Moyen — risque de bruit | Exécuter Phase 2 en isolation, commit dédié, revue ligne à ligne |
| Le glob étendu `**/*.yml` capture des fichiers internes inattendus | Moyen | Exclure explicitement les patterns `.swp`, `.bak` et tester sur un dossier vide d'abord |
| Traduction MT de mauvaise qualité accept sans revue | Élevé — UX dégradée | Imposer revue humaine pour tout texte visible utilisateur ; tagger les fichiers MT |
| Suppression accidentelle de clés `#?` encore utilisées | Élevé | `Clean::Support.look_for_labels` couvre les vues mais pas le JS — checker `app/assets/javascripts/` |
| `arb` RTL casse certains composants | Moyen | Tester chaque page principale après merge |
| Performance : `clean!` est lourd, 9 locales × ~20 fichiers | Faible | Acceptable (tâche manuelle), garder logs |
| Plugins activés bloquent `clean!` (cf. ligne 53 — `raise 'Cannot clean locales if plugins are activated'`) | Moyen | Désactiver temporairement `Gemfile.local`/`Gemfile.plugins` durant l'exécution |
| `private def self.translate_or_nil` malformé (l.47) | Faible — bug latent | Corriger en phase 1.4 |

---

## 6. Livrables

- `lib/clean/locales.rb` étendu (phases 1.1-1.4) + tests.
- `config/locales/fra/**` régénéré et complété (phase 2).
- `config/locales/<loc>/**` synchronisés en structure (phase 3) + complétés (phase 4).
- `claudedocs/locales_baseline.txt` (avant) & `claudedocs/locales_final.txt` (après) pour audit.
- Section "Translations" ajoutée à `CLAUDE.md`.
- PR vers `5.0-beta`.

---

## 7. Décisions ouvertes à arbitrer avant `/sc:implement`

1. **Source de traduction** (4.2) : fra et eng sont la référence. MT+revue, TM, et plateforme Crowdin
2. **Politique des clés orphelines** (`#?` dans la sortie de `clean!`) : conservation indéfinie
3. **Périmètre des fichiers orphelins** (phase 1.1) : certains méritent une méthode dédiée (`clean_navigation!`, `clean_tooltips!`) avec source dynamique
4. **Sous-dossier `exchangers/`** : convention exacte (un fichier par exchanger ? un fichier global ?) — à vérifier sur `fra/exchangers/`.
5. **Cible de complétion** : 100 % `eng` et `fra` + 80 % seuil pour les autres

---

## 8. Prochaine étape

Une fois les arbitrages du §7 actés, lancer :

```
/sc:implement claudedocs/workflow_locales_completion.md --phase 1
```

puis itérer phase par phase.
