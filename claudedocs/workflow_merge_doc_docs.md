# Workflow — Fusion des répertoires `doc/` et `docs/`

**Date :** 2026-05-30
**Branche :** `5.0-beta`
**Stratégie :** systematic
**Type :** réorganisation de documentation (zéro impact code)
**Cible retenue :** fusion dans **`docs/`** — suppression de `doc/` à la fin
**Specs API :** conserver toutes les specs **côte à côte** (`openapi-v2.yaml` + `v1.yaml` + `v2.yaml`)

> ⚠️ **Plan uniquement.** Ce document décrit l'exécution. Aucune commande n'a été lancée.
> Étape suivante : `/sc:implement claudedocs/workflow_merge_doc_docs.md`.

---

## 1. État des lieux

### `doc/` (2,2 Mo — ancien, EN + exports wiki Atlassian)
| Fichier | Nature |
|---|---|
| `doc/index.md` | Sommaire (table des matières) |
| `doc/Installation.md` | Page d'installation (liens wiki) |
| `doc/Installation/Eky-Ekylibre.md` | Install Eky/Ekylibre |
| `doc/Installation/Global/Ubuntu 20.04 LTS.md` | Install Ubuntu (espace dans le nom) |
| `doc/git.md`, `doc/ui.md`, `doc/components.md`, `doc/beehive_custom_cell.md` | Guides dev |
| `doc/guides/helpers.md`, `doc/guides/aggregator.md` | Guides dev |
| `doc/api/V1.yaml` (2885 l.), `doc/api/V2.yaml` (2668 l.) | Specs Stoplight/Swagger |
| `doc/screenshots/screens.png`, `screens.jpg` | Captures (référencées par README) |
| `doc/help_doc/fra.pdf` | Doc utilisateur PDF |
| `doc/.gitignore` | `/rdoc` |

### `docs/` (160 Ko — récent 2026, FR)
| Fichier | Nature |
|---|---|
| `docs/db.md` | Schéma base de données |
| `docs/v6-brainstorm.md` | Planning v6 |
| `docs/algo/interventions.md` | Algo interventions |
| `docs/analysis/{README,synthesis,security,performance,architecture,quality}.md` | Audit (6 fichiers **cross-liés**) |
| `docs/api/README.md` | Doc API v2 (liens relatifs) |
| `docs/api/openapi-v2.yaml` (1010 l.) | Spec OpenAPI 3.0 |

### Contraintes de cohérence (références à corriger)
- **`README.md`** (racine) pointe dans `doc/` :
  - L.12 — URLs raw GitHub des captures `doc/screenshots/screens.{jpg,png}`
  - L.18 — `./doc/Installation/Global/Ubuntu 20.04 LTS.md`
  - L.22 — `./doc/Installation/Eky-Ekylibre.md`
- **`docs/analysis/README.md`** — liens relatifs internes (`synthesis.md`, etc.) → **le dossier `analysis/` doit bouger en bloc** (aucun lien ne casse).
- **`docs/api/README.md`** — référence `docs/api/openapi-v2.yaml` → le fichier **reste dans `docs/api/`** : chemins inchangés.
- **`doc/index.md`** — liens vers `Installation.md`, `git.md`, `ui.md`, `components.md`, `../docker/README.md`.
- ✅ **Aucune référence dans le code** (`.rb`, `.rake`, `.yml`, `.yaml` applicatifs) — vérifié par grep. Pas de risque de rupture applicative.

---

## 2. Arborescence cible (`docs/`)

```
docs/
├── index.md                          # sommaire maître (réécriture de doc/index.md + sections docs/)
├── installation/
│   ├── README.md                     # ← doc/Installation.md
│   ├── eky-ekylibre.md               # ← doc/Installation/Eky-Ekylibre.md
│   └── ubuntu-20.04-lts.md           # ← doc/Installation/Global/Ubuntu 20.04 LTS.md  (renommé, sans espace)
├── guides/
│   ├── git.md                        # ← doc/git.md
│   ├── ui.md                         # ← doc/ui.md
│   ├── components.md                 # ← doc/components.md
│   ├── beehive-custom-cell.md        # ← doc/beehive_custom_cell.md
│   ├── helpers.md                    # ← doc/guides/helpers.md
│   └── aggregator.md                 # ← doc/guides/aggregator.md
├── development/
│   ├── db.md                         # ← docs/db.md
│   └── algo/
│       └── interventions.md          # ← docs/algo/interventions.md
├── api/
│   ├── README.md                     # ← docs/api/README.md  (compléter : citer v1/v2)
│   ├── openapi-v2.yaml               # ← docs/api/openapi-v2.yaml  (inchangé)
│   ├── v1.yaml                       # ← doc/api/V1.yaml  (minuscule)
│   └── v2.yaml                       # ← doc/api/V2.yaml  (minuscule)
├── analysis/                         # ← docs/analysis/  (déplacé EN BLOC, liens internes intacts)
│   ├── README.md
│   ├── synthesis.md
│   ├── security.md
│   ├── performance.md
│   ├── architecture.md
│   └── quality.md
├── planning/
│   └── v6-brainstorm.md              # ← docs/v6-brainstorm.md
└── assets/
    ├── screenshots/
    │   ├── screens.png               # ← doc/screenshots/screens.png
    │   └── screens.jpg               # ← doc/screenshots/screens.jpg
    └── help/
        └── fra.pdf                   # ← doc/help_doc/fra.pdf
```

**Principes de regroupement :**
- `installation/` `guides/` `development/` `api/` `analysis/` `planning/` `assets/` — par **intention** (installer, développer, intégrer, auditer, planifier, ressources).
- `analysis/` conservé tel quel pour ne casser aucun lien interne.
- Noms **kebab-case minuscule, sans espace** (`ubuntu-20.04-lts.md`, `beehive-custom-cell.md`) — robustesse URLs/Git.
- Binaires regroupés sous `assets/`.

---

## 3. Phases & dépendances

```
P0 Préparation ─▶ P1 Déplacements git mv ─▶ P2 Correction des liens ─▶ P3 Suppression doc/ ─▶ P4 Validation
   (snapshot)        (history-preserving)      (README + index + api)     (cleanup)            (liens + git)
```

| Phase | Dépend de | Parallélisable |
|---|---|---|
| P0 Préparation | — | — |
| P1 Déplacements | P0 | les `git mv` entre eux : oui |
| P2 Correction liens | P1 | par fichier : oui |
| P3 Suppression `doc/` | P1, P2 | — |
| P4 Validation | P3 | checks entre eux : oui |

---

## 4. Étapes détaillées

### Phase 0 — Préparation
- [ ] **0.1** Travailler sur une branche dédiée : `git switch -c chore/merge-doc-docs`
- [ ] **0.2** Confirmer arbre propre hormis `db/structure.sql` déjà modifié (le laisser de côté / ne pas l'inclure dans ce commit).
- [ ] **0.3** Geler la liste des fichiers (cf. §1) comme référence de complétude.

### Phase 1 — Déplacements (utiliser `git mv` pour préserver l'historique)
> Tous les `mv` ciblent l'arborescence du §2. Créer les dossiers cibles au besoin.

- [ ] **1.1 Installation**
  - `git mv doc/Installation.md docs/installation/README.md`
  - `git mv doc/Installation/Eky-Ekylibre.md docs/installation/eky-ekylibre.md`
  - `git mv "doc/Installation/Global/Ubuntu 20.04 LTS.md" docs/installation/ubuntu-20.04-lts.md`
- [ ] **1.2 Guides**
  - `git mv doc/git.md docs/guides/git.md`
  - `git mv doc/ui.md docs/guides/ui.md`
  - `git mv doc/components.md docs/guides/components.md`
  - `git mv doc/beehive_custom_cell.md docs/guides/beehive-custom-cell.md`
  - `git mv doc/guides/helpers.md docs/guides/helpers.md`
  - `git mv doc/guides/aggregator.md docs/guides/aggregator.md`
- [ ] **1.3 Development** (réorg interne `docs/`)
  - `git mv docs/db.md docs/development/db.md`
  - `git mv docs/algo/interventions.md docs/development/algo/interventions.md` (puis `rmdir docs/algo`)
- [ ] **1.4 API** (conserver tout côte à côte)
  - `git mv doc/api/V1.yaml docs/api/v1.yaml`
  - `git mv doc/api/V2.yaml docs/api/v2.yaml`
  - `docs/api/openapi-v2.yaml` et `docs/api/README.md` : inchangés de place.
- [ ] **1.5 Planning**
  - `git mv docs/v6-brainstorm.md docs/planning/v6-brainstorm.md`
- [ ] **1.6 Assets**
  - `git mv doc/screenshots/screens.png docs/assets/screenshots/screens.png`
  - `git mv doc/screenshots/screens.jpg docs/assets/screenshots/screens.jpg`
  - `git mv doc/help_doc/fra.pdf docs/assets/help/fra.pdf`
- [ ] **1.7 `analysis/`** — déjà sous `docs/analysis/`, **ne pas toucher**.
- [ ] **1.8 `.gitignore`** — fusionner la règle `/rdoc` de `doc/.gitignore` dans `docs/.gitignore` (ou `.gitignore` racine), puis laisser `doc/.gitignore` être supprimé en P3.

### Phase 2 — Correction des liens & sommaires
- [ ] **2.1 `README.md` (racine)** — 3 corrections :
  - L.12 captures : `.../doc/screenshots/screens.jpg` → `.../docs/assets/screenshots/screens.jpg` (idem `.png`).
  - L.18 : `./doc/Installation/Global/Ubuntu 20.04 LTS.md` → `./docs/installation/ubuntu-20.04-lts.md`
  - L.22 : `./doc/Installation/Eky-Ekylibre.md` → `./docs/installation/eky-ekylibre.md`
- [ ] **2.2 `docs/index.md` (nouveau sommaire maître)** — fusionner le contenu de `doc/index.md` et ajouter les sections propres à `docs/`. Mettre à jour les liens vers les nouveaux chemins :
  - Installation → `installation/README.md`
  - Git/UI/Components → `guides/git.md`, `guides/ui.md`, `guides/components.md`
  - `../docker/README.md` → inchangé (même profondeur depuis `docs/`)
  - Ajouter : `development/db.md`, `development/algo/interventions.md`, `analysis/README.md`, `planning/v6-brainstorm.md`, `api/README.md`.
- [ ] **2.3 `docs/api/README.md`** — chemins `docs/api/openapi-v2.yaml` inchangés ; **ajouter** une mention des specs Stoplight historiques `v1.yaml` / `v2.yaml` (statut : legacy/référence).
- [ ] **2.4 `docs/installation/README.md`** — vérifier que les liens wiki internes pointant vers Ubuntu/Eky sont cohérents avec les nouveaux noms de fichiers (mettre à jour si liens relatifs).
- [ ] **2.5 `docs/analysis/*`** — liens internes inchangés (dossier déplacé en bloc). Aucune action sauf vérification.

### Phase 3 — Suppression de `doc/`
- [ ] **3.1** Vérifier que `doc/` ne contient plus que `.gitignore` (déjà fusionné) après les `git mv`.
- [ ] **3.2** `git rm doc/.gitignore` puis confirmer `doc/` vide.
- [ ] **3.3** `git status` : aucun fichier résiduel sous `doc/`.

### Phase 4 — Validation
- [ ] **4.1 Complétude** — chaque fichier du §1 a une destination dans `docs/` (16 + 11 = 27 entrées suivies).
- [ ] **4.2 Liens morts** — scanner les `.md` de `docs/` :
  - `grep -rInE '\]\((\./)?[A-Za-z]' docs/ | grep -vE 'https?://'` puis vérifier que chaque cible relative existe.
  - Vérifier qu'aucun lien ne pointe encore vers `doc/` (ancien) : `grep -rIn 'doc/' README.md docs/`.
- [ ] **4.3 Historique préservé** — `git log --follow docs/installation/ubuntu-20.04-lts.md` doit remonter l'historique d'origine.
- [ ] **4.4 Aucun impact code** — `grep -rIn "doc/" --include=*.rb --include=*.rake --include=*.yml app config lib` → vide (confirmation finale).
- [ ] **4.5 Rendu** — ouverture rapide de `docs/index.md` (TOC) : tous les liens cliquables résolvent.

---

## 5. Points de contrôle (quality gates)

| Gate | Critère de passage |
|---|---|
| G1 (après P1) | `doc/` ne contient plus que `.gitignore` ; tous les `git mv` réussis ; `git status` cohérent |
| G2 (après P2) | 0 lien relatif cassé dans `docs/` ; README racine ne référence plus `doc/` |
| G3 (après P3) | `doc/` supprimé ; `.gitignore` `/rdoc` préservé ailleurs |
| G4 (après P4) | 27 fichiers retrouvés sous `docs/` ; `git log --follow` OK ; grep code = vide |

---

## 6. Risques & mitigations

| Risque | Impact | Mitigation |
|---|---|---|
| Espace dans `Ubuntu 20.04 LTS.md` | `git mv` échoue si guillemets oubliés | Toujours quoter le chemin source |
| Captures README en URL raw GitHub (branche `master`) | Liens cassés tant que non mergé sur la branche par défaut | Corriger le **chemin** maintenant ; ils résoudront au merge. Documenter dans la PR |
| Spec Stoplight `v1.yaml`/`v2.yaml` vs `openapi-v2.yaml` | Confusion lecteur | README API explicite le statut (legacy vs source de vérité v2) |
| `db/structure.sql` déjà modifié | Pollution du commit doc | Commit séparé, ne pas inclure structure.sql |
| `git mv` casse les liens internes de `docs/analysis/` | Liens audit cassés | Déplacer `analysis/` en bloc — **non touché** dans ce plan |

---

## 7. Plan de rollback
- Tout est en `git mv`/`git rm` sur une branche dédiée → `git reset --hard` ou suppression de la branche annule l'ensemble.
- Aucun fichier supprimé définitivement avant P3 ; P3 ne supprime que `.gitignore` (contenu préservé ailleurs).

---

## 8. Commit / PR suggérés
- **Commit :** `chore(docs): merge doc/ into docs/ with logical tree`
- **PR :** lister la table de correspondance §2, signaler les 3 liens README corrigés, mentionner que les captures résolvent après merge sur la branche par défaut.

---

## 9. Suivi (non bloquant)
- [ ] Consolider à terme les specs API (Stoplight `v1/v2.yaml` → OpenAPI 3.0) — hors périmètre de cette fusion.
- [ ] Traduire/uniformiser EN↔FR des guides déplacés.
- [ ] Ajouter un lint de liens morts CI (`lychee` ou `markdown-link-check`) sur `docs/`.
