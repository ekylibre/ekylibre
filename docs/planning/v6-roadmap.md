# Ekylibre V6 — Feuille de route opérationnelle

**Statut :** proposition — à valider
**Date :** 13 septembre 2026
**Complément de :** le document d'architecture V6 (ADR-001 à ADR-012), dont il reprend
le découpage en phases. Là où l'architecture dit *pourquoi* et *quoi*, ce document
dit *ce qu'il faut écrire ou modifier*, dans quel ordre, et ce qui est déjà fait.

**À lire avec :** [v6-etat-des-lieux.md](v6-etat-des-lieux.md) (état mesuré au
13 septembre), [v6-improvement-plan.md](v6-improvement-plan.md) (lots A à H et
efforts), [v6-dependency-audit.md](v6-dependency-audit.md).

---

## 0. Quatre corrections au document d'architecture

Ces points sont vérifiés sur la branche `6.0-alpha` et changent des prémisses.

**0.1 — `apartment` passe Rails 8.1.** L'ADR-002 justifie le mono-schéma par
« `apartment` ne passe pas Rails 8.1 ». Le dépôt n'utilise pas `apartment` mais
son fork maintenu **`ros-apartment`, en 3.4.4, qui déclare `activerecord < 8.2`
et fonctionne** : six tenants listés sous Rails 8.1.3.1, suite à parité. Rien ne
presse techniquement.

La décision reste bonne, mais pour ses vraies raisons — migrations jouées une
fois au lieu de N, requêtes inter-tenants redevenues possibles, préparation de la
restauration d'archives v5 — et non par contrainte de compatibilité. La
conséquence pratique : **le calendrier du mono-schéma est un choix, pas une
échéance subie.**

**0.2 — La phase 0 est déjà à moitié faite.** « Migration Rails 5.2 → 8.1,
Ruby 2.6 → 3.4 » est **achevée** (quinze commits, parité de suite à chaque
palier). Restent, dans cette phase : la fusion des schémas, le RLS, les index, et
Propshaft.

**0.3 — PostgreSQL n'est plus plafonné par le client.** L'image de base
`ruby3.4.10` embarque désormais `psql`/`pg_dump` **17.11** ; le serveur de
développement et la CI sont en **13.4**. Le blocage documenté jusqu'ici (« le
client 13 refuse un serveur plus récent ») est levé : monter le serveur en 15, 16
ou 17 ne demande plus que de changer l'image du service. C'est ce qui ouvre la
porte à l'ADR-003b, `uuidv7()` native n'existant qu'en PostgreSQL 18.

Effet de bord à connaître : `db/structure.sql` versionné a été produit par
`pg_dump` 13.23. **Toute régénération avec le client 17 produit un diff de
~1400 lignes** (ordre et forme des contraintes). Il faut l'assumer une fois,
dans un commit dédié, et fixer la version de `pg_dump` employée.

**0.4 — Solid Queue et Propshaft ne sont pas là.** L'ADR-012 les présente comme
adoptés. État réel : `sidekiq` 7.3.10 (la série 8 exige `rack >= 3.1`, que
`turnout` interdit), `sprockets` 3.7.5 et `webpacker` 4.3.0, `redis` 5.4.1,
aucun `propshaft` ni `solid_queue`. Ce sont des lots à écrire, chacun avec son
préalable.

---

## 1. Ce qui est fait

| Lot | État |
|---|---|
| Rails 5.2 → **8.1.3.1**, Ruby 2.6 → **3.4.10** | fait, valeurs par défaut 8.1 incluses |
| Paperclip → Active Storage | fait (lot A.3) |
| `state_machine` → `Transitionable` | fait |
| RGeo 2 → **3**, PROJ 9 | fait |
| `sidekiq` 4 → **7.3**, Action Cable fonctionnel | fait |
| CI GitHub Actions, CodeQL, plancher de couverture 55 % | fait (lot A.8) |
| RCE du restore de tenant | corrigée (lot P0) |
| RuboCop 1.11 → **1.91**, ESLint au vert | fait |

---

## 2. Lot 0 — Assainir avant d'ouvrir le schéma

*Rien de ce qui suit n'est nouveau fonctionnellement. Tout est un préalable pour
que le chantier de schéma soit lisible : sans suite verte, une régression de RLS
se perdra dans le bruit.*

### 2.0 — La suite verte, d'abord (**bloquant**)

| # | À faire | Mesure actuelle |
|---|---|---|
| 0.1 | Traiter les **17 échecs et 15 erreurs** de la suite, hérités des paliers antérieurs | 3650 tests, 32 cas rouges |
| 0.2 | Corriger le test d'achat aux montants inconciliables (99 € HT / 120 € TTC à 20 %), puis rétablir `Regexp.timeout` | 1 cas instable |
| 0.3 | Stabiliser `Devise.mappings` en exécution isolée (référence de classe périmée) | 7 erreurs en fichier seul |
| 0.4 | Empêcher la suite de réécrire `db/structure.sql` (`maintain_test_schema`, ou tâche dédiée) | diff à restaurer après chaque exécution |

**Critère de sortie :** `bin/rails test` sort au vert, donc le job `Tests` de la
CI passe. C'est aujourd'hui la seule raison de son échec.

### 2.1 — Les sept valeurs par défaut désactivées

Chacune est documentée dans `config/application.rb`. Deux forment un lot cohérent
avec le point 0.1, parce qu'elles touchent les mêmes rappels comptables :

| # | À faire |
|---|---|
| 0.5 | `raise_on_assign_to_attr_readonly` : revoir les rappels et setters qui réaffectent `currency`, `nature`, `journal_id`, `state`, `listing_id`, `number`, `root_model` sans distinguer création et mise à jour. **325 tests concernés** ; ces écritures sont perdues en silence aujourd'hui |
| 0.6 | `has_many_inversing` + `automatic_scope_inversing` : casser la récursion mutuelle `PurchaseInvoice` ↔ `PurchaseItem` |
| 0.7 | `default_column_serializer` : sortir de `wice_grid` (4 contrôleurs) ou corriger son `serialize :query` nu en amont |
| 0.8 | `raise_on_missing_required_finder_order_columns` : donner une clé aux **14 tables du `lexicon`** qui n'en ont pas — *à faire dans le lot 1, C.2* |
| 0.9 | `active_storage.variant_processor` : libvips dans l'image de base |

### 2.2 — Dette d'outillage

| # | À faire |
|---|---|
| 0.10 | Résorber les **809 offenses** de `.rubocop_todo.yml` (542 auto-corrigeables) par lots thématiques |
| 0.11 | Les **39 avertissements TypeScript** (types `any`, retours manquants) |
| 0.12 | Décider du sort de `Ekylibre::Plugin` (≈300 lignes) : le mécanisme `plugins/` est mort, les 19 greffons sont des engines. Le retirer ou le documenter |
| 0.13 | Supprimer les constantes autochargées pendant l'initialisation (avertissement Rails ; 76 fichiers de `lib/` chargés avant la fin de l'initialisation) |

### 2.3 — Mise en service du palier

| # | À faire |
|---|---|
| 0.14 | `docker/prod/Dockerfile` en Ruby 3.4 ; relever le plancher du `Gemfile` (`ruby '>= 3.4'`) |
| 0.15 | Décider si la V6 se déploie **avant** le mono-schéma (recommandé : livrer Rails 8.1 en production réduit l'écart et valide la pile sous charge réelle) |
| 0.16 | Déclencher `build-prod-image` sur `6.0-alpha` le jour de cette décision, pas avant |
| 0.17 | Monter le serveur PostgreSQL (13 → 16 ou 17), le client le permet déjà ; régénérer `structure.sql` dans un commit dédié |

---

## 3. Lot 1 — Mono-schéma et isolation (ADR-002, ADR-003)

*Reprend les lots C et D du plan v6. La décision ADR-003 est bloquante et doit
être prise avant la première migration.*

### 3.1 Préalables de décision

| # | À trancher | Pourquoi maintenant |
|---|---|---|
| 1.1 | **Type de `tenant_id`** (`uuid` recommandé) et **périmètre UUIDv7** | la fusion renumérote les PK de toute façon : écrire des UUIDv7 coûte le même passage. Séparer les deux oblige à réécrire les mêmes tables deux fois |
| 1.2 | **Audit préalable** : aucun greffon ni export réglementaire ne doit sérialiser des `id` numériques (EDI, `ednotif`, exports comptables, Isacompta, Telepac) | une dépendance invisible dans le schéma casse à la première déclaration |
| 1.3 | **Version de PostgreSQL cible** : `uuidv7()` native exige la 18 ; sinon `pg_uuidv7` ou génération Ruby | conditionne 1.1, et la montée serveur (0.17) |

### 3.2 Schéma

| # | À faire | Volume mesuré |
|---|---|---|
| 1.4 | Prototype sur 3 tables — `interventions`, `intervention_parameters`, `products` : `tenant_id`, PK et FK composites, index tenant-aware, RLS `FORCE`. **Porte de sortie du lot** | 3 tables |
| 1.5 | Classifier les tables en trois plans : contrôle (global, hors RLS) / données (tenant, RLS) / référentiel (`lexicon`, partagé) | **313 tables** |
| 1.6 | Générateur de migrations piloté par 1.5 | `id` → `bigint` : 219 tables ; PK composites : 240 ; FK composites : 169 ; index uniques tenant-aware : 35 |
| 1.7 | **Linter de schéma en CI** : toute table du plan de données doit porter `tenant_id NOT NULL`, une PK composite, RLS `ENABLE` + `FORCE`, une politique `USING` + `WITH CHECK` | bloquant au build |
| 1.8 | Scan `pg_indexes` : échec sur tout index unique d'une table à `tenant_id` sans `tenant_id` en tête (ADR-002, R2) | ~20 lignes de test |
| 1.9 | Index **GiST composites** `btree_gist (tenant_id, shape)` | **64 colonnes géométriques** |
| 1.10 | Cas particuliers : vues matérialisées, HABTM, `WorkerTimeIndicator` | — |
| 1.11 | Séquences globales + `setval` au-dessus du `MAX(id)` tous tenants confondus, rejouable | — |
| 1.12 | Schéma nommé `ekylibre`, `public` réservé aux extensions | — |
| 1.13 | Rôle applicatif **non-propriétaire, sans `BYPASSRLS`, non-superuser** ; rôle de maintenance distinct | aujourd'hui : un seul rôle propriétaire |

### 3.3 Runtime

| # | À faire | Volume mesuré |
|---|---|---|
| 1.14 | Plan de contrôle : `users`, `tenants`, `user_tenants` | 3 tables neuves |
| 1.15 | `TenantRecord` / `ApplicationRecord` / `LexiconRecord` ; reclasser les modèles | **244 modèles racines + 111 STI** |
| 1.16 | Annoter les associations en `query_constraints` — mécanisé par script, revu par domaine | **1 413 associations** |
| 1.17 | Contexte runtime : `SET LOCAL app.tenant_id` en transaction, `Current.tenant`, **fail-closed** | — |
| 1.18 | Propager le contexte aux chemins asynchrones : file d'attente, Action Cable, tâches rake, exchangers | 112 exchangers |
| 1.19 | Auditer le SQL brut : chacun peut contourner la RLS ou casser sur la PK composite | **206 sites** (81 `execute`, 80 `update_all`, 19 `delete_all`, 18 `select_*`, 7 `joins("…")`, 1 `find_by_sql`) |
| 1.20 | Tests d'isolation **générés** : sans contexte → 0 ligne ; sous tenant A → jamais une ligne de B | une paire par modèle du plan de données |
| 1.21 | Retirer Apartment (9 fichiers) et le schéma d'agrégation | — |
| 1.22 | Chemin inter-tenants **explicite et audité** (rôle dédié, bypass tracé) : tableau de bord CUMA, benchmark, vue coopérative | le gain fonctionnel du lot |

---

## 4. Lot 2 — Identité et API (ADR-004)

| # | À faire |
|---|---|
| 2.1 | Déployer Keycloak ; importer les comptes V5 une fois, puis Keycloak fait autorité |
| 2.2 | Claim `tenant_id` dans le JWT ; **tous les services le résolvent depuis le jeton**, jamais depuis le sous-domaine |
| 2.3 | Middleware de résolution côté Rails, raccordé au contexte 1.17 |
| 2.4 | Token exchange pour `duke` et `voice-gateway` (jeton délégué, isolation RLS héritée) |
| 2.5 | Retirer Devise du chemin nominal ; conserver le compte de secours `admin` hors tenant |
| 2.6 | Stabiliser et versionner l'API v1 ; décider du sort de l'API v2 existante |
| 2.7 | Device flow / Authorization Code + PKCE pour le mobile |

**Dépend de :** lot 1 (le claim n'a de sens qu'avec le contexte tenant).

---

## 5. Lot 3 — Saisie terrain conversationnelle (ADR-005, 006, 007)

| # | À faire |
|---|---|
| 3.1 | `voice-gateway` : port `Channel::Adapter` (`receive_media`, `receive_text`, `send_ack`), adaptateur **Telegram** d'abord |
| 3.2 | ASR asynchrone sur infrastructure propre |
| 3.3 | Repositionner `duke` en **extraction contrainte** : schéma JSON dérivé de `Intervention`, `Observation`, `Task` ; vocabulaires `onoma`/Lexicon en énumérations fermées |
| 3.4 | Pré-résolution d'entités (parcelle, intrant, culture) **avant** l'appel au modèle, sur le contexte du tenant |
| 3.5 | RAG documentaire sur les documents déposés par le client |
| 3.6 | `pending_records` : score de confiance, trace d'extraction, alternatives écartées |
| 3.7 | Écran de validation (mobile et web) ; validation par lot pour la confiance élevée |
| 3.8 | Test automatisé : **aucune écriture métier sans validation explicite** |
| 3.9 | Adaptateur WhatsApp, vérification Meta Business |
| 3.10 | Accusé de réception **unique et groupé** — ne pas répondre dans le fil (facturation Meta au 1er octobre 2026) |
| 3.11 | Documenter la position de souveraineté : le canal ne transporte que le média choisi par l'agriculteur ; transcription et extraction sur infrastructure propre |
| 3.12 | Adaptateur de repli SMS/e-mail : **prévu dans le port, pas implémenté** |

**Dépend de :** lot 2 (jeton délégué). Mesure de sortie : corpus réel de 200 messages par filière.

---

## 6. Lot 4 — Mobile offline et interfaces par profil (ADR-008, 011)

| # | À faire |
|---|---|
| 4.1 | **Écrire la spec `/sync/v1` avant toute ligne de code** |
| 4.2 | `updated_at` + `deleted_at` (tombstones) sur chaque table synchronisable |
| 4.3 | Politique de conflit **par entité** : dernier écrivain gagne au champ pour observations et tâches ; append-only pour tout objet comptable ou réglementaire |
| 4.4 | BFF : façonner la charge utile au périmètre du client (ses parcelles, sa campagne) |
| 4.5 | `zero-mobile` synchronisé de bout en bout |
| 4.6 | Contrainte de revue de code : toute table destinée au terrain respecte le contrat dès sa création |
| 4.7 | Manifestes d'écran par profil métier ; langage **volontairement pauvre** (liste de blocs typés) |
| 4.8 | Les greffons de niveau 2 injectent leurs blocs dans ces manifestes |

**Dépend de :** ADR-003b (identifiants générés côté client) — donc du lot 1.

---

## 7. Lot 5 — Facture électronique (ADR-009)

*La réception est obligatoire depuis le 1er septembre 2026 : **cette partie est
déjà en retard**. L'émission pour les PME et TPE tombe au 1er septembre 2027.*

| # | À faire | Échéance |
|---|---|---|
| 5.1 | `EInvoicing::Gateway` comme produit : Qonto redevient un adaptateur parmi N | — |
| 5.2 | **Réception** de bout en bout via une Plateforme Agréée, sur un tenant pilote | en retard |
| 5.3 | Choix de la PA **par tenant** (l'agriculteur arrive souvent déjà raccordé chez sa coopérative ou son centre de gestion) | — |
| 5.4 | Domaine émettant et consommant **Factur-X, UBL, CII** propres ; l'investissement va au format, pas aux SDK | — |
| 5.5 | **PDF/A-3** : le moteur de rapport produit du PDF simple. Trancher entre bibliothèque `factur-x` Python et post-traitement Ruby | avant l'émission 2027 |
| 5.6 | Émission conforme validée par **au moins deux PA distinctes** | 1ᵉʳ sept. 2027 |
| 5.7 | e-reporting (250 € par transmission manquante) | — |
| 5.8 | Renommer PDP → **Plateforme Agréée (PA)** dans les specs et le code | avant d'écrire du code |

**Ne pas construire :** comptabilité complète, paie MSA, caisse enregistreuse.
Interopérer (API ISAGRI, AGIRIS, centres de gestion).

---

## 8. Lot 6 — Infrastructure et écosystème (ADR-010, 012)

| # | À faire | Préalable |
|---|---|---|
| 6.1 | **Solid Queue** en remplacement de Sidekiq | `sidekiq` 8 exige `rack >= 3.1`, que `turnout` interdit : sortir de `turnout` ou changer de mode maintenance **d'abord** |
| 6.2 | Base ou rôle **dédié hors RLS** pour Solid Queue / Cache / Cable | lot 1 (sinon files vides ou jobs fantômes) |
| 6.3 | Solid Cache, Solid Cable ; retirer Redis | 6.1 |
| 6.4 | **Sprockets 3.7 + Webpacker 4 → Propshaft** : lot de travail dédié, non un effet de bord | dépend du sort d'`active_list` et du front (lot 7) |
| 6.5 | Sortir de `liquid-rails` (épingle `kaminari` 1.1, paginateur repris à la main) ou le remplacer pour les gabarits d'e-mails | — |
| 6.6 | Manifeste de greffons **out-of-process** : scopes OAuth, webhooks, points d'extension UI | lot 2 |
| 6.7 | Table **outbox** + diffuseur léger — pas de Kafka | — |
| 6.8 | Un greffon de référence hors Ruby, écrit sans modifier le cœur | 6.6 |
| 6.9 | Frontières de modules explicites (Packwerk ou équivalent) **vérifiées en CI** | — |
| 6.10 | APM en production (Scout ou Skylight) et `log_min_duration_statement = 200ms` — aucun APM aujourd'hui | 0.15 |

---

## 9. Lot 7 — Front et API-only (lot G du plan)

| # | À faire |
|---|---|
| 7.1 | Décider du sort d'`active_list` (condamné par ADR-6.2) : ce qui le remplace commande 6.4 |
| 7.2 | Découpler le front ; API-only **après** parité fonctionnelle, pas avant |
| 7.3 | Reprendre les points chauds de performance déjà inventoriés : cascades de rappels sur `Intervention#save` (30-100 requêtes par sauvegarde), `Ekylibre::Record::Sums` en O(N²) à l'import, N+1 des 7 contrôleurs les plus chauds, mémoïsation des 183 appels `Onoma::*`, `insert_all` dans les 112 exchangers, `EXTRACT(YEAR FROM …)` non indexable |

---

## 10. Ordre recommandé

```
Lot 0.0–0.4  suite verte            ─┐
Lot 0.14–0.17 mise en service        ├─ en parallèle, sans dépendance mutuelle
Lot 0.5–0.9  défauts Rails          ─┘
                     │
             1.1–1.3 décisions ADR-003  ← bloquant
                     │
             Lot 1   mono-schéma + isolation
                     │
             Lot 2   Keycloak et API
                   ┌─┴─┐
           Lot 3 saisie   Lot 4 mobile
                   └─┬─┘
             Lot 5   facture électronique  ← contrainte de calendrier propre
             Lot 6   infrastructure
             Lot 7   front
```

Deux remarques sur cet ordre. Le **lot 5 ne dépend d'aucun autre** : sa contrainte
est réglementaire, et la réception est déjà en retard — il peut démarrer tout de
suite, par l'adaptateur d'une seule PA. Et le **lot 0 avant tout le reste** n'est
pas une précaution de principe : un chantier qui ajoute `tenant_id` à 240 tables
et des politiques RLS partout produira des régressions, et il faut qu'elles soient
visibles.

---

## 11. Décisions à trancher, par échéance

| Sujet | Échéance | Bloquant pour |
|---|---|---|
| Type de `tenant_id`, périmètre UUIDv7, version PostgreSQL cible | **avant la première migration** | lot 1 entier |
| Déployer Rails 8.1 en production avant ou après le mono-schéma | avant le lot 1 | 0.14–0.16 |
| Ordre de la dette du lot 0 | maintenant | lisibilité du lot 1 |
| Sortie de `turnout` (mode maintenance) | avant 6.1 | Solid Queue |
| Remplacement d'`active_list` | avant 6.4 | Propshaft |
| PDF/A-3 : Python ou Ruby | avant l'émission | 5.5 |
| Périmètre du langage de manifeste d'écran | lot 4 | 4.7 |
| Liste des PA prioritaires | lot 5 | 5.3 |
| Sort d'`Ekylibre::Plugin` | opportuniste | 0.12 |
