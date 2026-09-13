# Architecture Ekylibre V6

**Statut du document :** proposition — à valider
**Date :** 13 septembre 2026
**Périmètre :** migration Rails 8.1 / Ruby 3.4, refonte de la tenancy, saisie terrain conversationnelle, interopérabilité facture électronique
**Complément :** [v6-roadmap.md](v6-roadmap.md) — lots de travail, volumes mesurés sur le dépôt, et quatre corrections de prémisses (§ 0)

---

## 1. Contexte

Ekylibre est un FMIS open source (AGPL-3.0) construit depuis 2008 en Ruby on Rails avec PostGIS. La version courante est la 5.0. La V6 poursuit trois objectifs simultanés :

1. **Dette technique** — passer de Rails 5.2 / Ruby 2.6 à Rails 8.1 / Ruby 3.4, et refondre le modèle de multi-tenancy (`apartment` ne passe pas Rails 8.1).
2. **Parité fonctionnelle historique** — couvrir le périmètre des acteurs installés du marché français (type ISAGRI) sur le technico-agronomique, en s'appuyant sur l'interopérabilité plutôt que sur la reconstruction pour la gestion administrative.
3. **Nouvelle couche d'interaction** — reproduire l'expérience de saisie terrain conversationnelle (type Tellia) : vocal, photo et texte via messagerie, structurés automatiquement en enregistrements métier.

### 1.1 Positionnement concurrentiel

**Face à ISAGRI.** L'écosystème de plugins existant couvre déjà une part significative de leur gamme : parcellaire et traçabilité (≈ Geofolia), viticulture et chai (≈ ISAVIGNE, ISACUVE), météo connectée via `ekylibre-sencrop` et `ekylibre-weenat`, certifications via `ekylibre-hve` et `ekylibre-idea`, notification bovine via `ekylibre-ednotif`.

Les manques réels sont la comptabilité complète, la paie MSA, la caisse enregistreuse et la gestion fine de troupeau par espèce. **La paie MSA et la comptabilité ne seront pas construites** (voir ADR-009) : ce sont des gouffres réglementaires sans avantage concurrentiel.

Leur véritable avantage n'est pas logiciel — un interlocuteur dans un rayon de 30 km, une centaine de conseillers spécialisés, 40 000 exploitations clientes. Cela ne se rattrape pas par l'architecture et ne doit pas orienter les décisions techniques.

**Face à Tellia.** Tellia est une couche d'interaction sans ERP en dessous : elle structure les conversations terrain et les synchronise vers des bases tierces. Ekylibre possède le modèle de données agronomique, PostGIS, la logique réglementaire et la comptabilité. Les deux sont complémentaires, pas concurrents. Les éléments à reprendre, par ordre d'importance :

1. Le canal d'entrée n'est pas une application — appel, note vocale, photo. Zéro installation, zéro formation. C'est le levier d'adoption principal.
2. L'extraction est contrainte vers un schéma, ce n'est pas de la conversation libre.
3. Le RAG s'appuie sur les documents du client (protocoles, fiches techniques), pas sur un modèle généraliste.

---

## 2. Vue d'ensemble

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Messagerie   │  │ App mobile   │  │ Web          │
│ Telegram /   │  │ React Native │  │ Hotwire      │
│ Matrix       │  │ offline      │  │ + SPA ciblé  │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │  Keycloak (OIDC)  │  Traefik    │
        │  SSO, tenants     │  + BFF      │
        └────────────────┬────────────────┘
                         │
   ┌──────────┬──────────┼──────────┬──────────────┐
   │          │          │          │              │
┌──┴───────┐┌─┴────────┐┌┴────────┐┌┴───────────┐┌─┴─────────┐
│voice-    ││ duke     ││eky-core ││lexicon-api ││agro-data  │
│gateway   ││extraction││Rails 8.1││référentiels││(reporté)  │
└──────────┘└──────────┘└────┬────┘└─────┬──────┘└───────────┘
                             │            │
                  ┌──────────┴──────┐┌────┴──────┐
                  │ PostgreSQL 18   ││ Lexicon   │
                  │ + PostGIS       ││ read-only │
                  │ schéma ekylibre ││           │
                  └─────────────────┘└───────────┘
```

### 2.1 Inventaire des services

| Service | Rôle | Langage | Statut |
|---|---|---|---|
| `eky-core` | ERP, métier, réglementaire, API | Ruby / Rails 8.1 | existant, à migrer |
| `keycloak` | SSO, tenants, délégation de jetons | — | neuf |
| `voice-gateway` | Messagerie, médias, ASR | Python | **neuf, prioritaire** |
| `duke` | Extraction contrainte + RAG documentaire | Python / FastAPI | existant, à repositionner |
| `lexicon-api` | Référentiels agricoles en lecture seule | — | existant (Lexicon / onoma) |
| `zero-mobile` | Application terrain offline-first | TypeScript / RN | existant |
| `agro-data` | Sentinel-2, RPG, météo | Python | reporté après V6.0 |

Les plugins IoT existants (`sencrop`, `weenat`, `traccar`, `samsys`) restent des Rails engines in-process : ils écrivent des séries temporelles, pas de la logique métier. Les extraire n'apporterait rien.

---

## 3. Décisions d'architecture (ADR)

### ADR-001 — Monolithe modulaire plutôt que microservices

**Statut :** proposé

**Contexte.** La demande initiale portait sur une architecture microservices. Le cœur métier d'Ekylibre encode de la logique réglementaire et agronomique dense — TVA agricole, PAC, traçabilité phytosanitaire, comptabilité — fortement transactionnelle et fortement couplée.

**Décision.** Monolithe modulaire Rails 8.1, découpé en modules explicites (Packwerk ou équivalent), entouré de satellites polyglottes pour ce qui n'est pas du métier : ASR, extraction NLP, données satellitaires.

**Conséquences.**
- Les invariants métier restent garantis par des transactions PostgreSQL, pas par des sagas applicatives.
- Une seule migration de schéma à coordonner.
- Le déploiement reste simple (Dokploy / conteneurs), sans orchestration lourde.
- Contrepartie : le core reste un point de contention pour les équipes. À compenser par des frontières de modules strictes et une CI qui les fait respecter.

**Alternatives écartées.** Découpage en services métier fins (facturation, parcellaire, stocks) : remplace des jointures par des appels réseau, impose des sagas pour la cohérence comptable, et multiplie les modes de panne sans bénéfice à l'échelle visée.

---

### ADR-002 — Multi-tenancy par colonne `tenant_id` avec Row Level Security

**Statut :** décidé (implémentation en cours sur la branche V6)

**Contexte.** La V5 utilise un schéma PostgreSQL par tenant via `apartment`, gem non maintenue et incompatible Rails 8.1. La branche V6 fusionne tous les tenants dans un schéma unique avec une colonne `tenant_id` sur chaque table.

**Décision.** Discriminant par colonne, **avec isolation garantie par PostgreSQL Row Level Security**, pas par `default_scope` applicatif.

```sql
ALTER TABLE interventions ENABLE ROW LEVEL SECURITY;
ALTER TABLE interventions FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON interventions
  USING (tenant_id = current_setting('app.tenant_id')::uuid);
```

Le `FORCE` est indispensable : sans lui, le propriétaire de la table échappe à la politique, et c'est fréquemment le rôle applicatif. **L'application doit se connecter avec un rôle non-propriétaire et non-superuser.**

Côté Rails, un middleware positionne `SET LOCAL app.tenant_id` en début de transaction à partir du claim JWT. `SET LOCAL` et non `SET` : le paramètre meurt avec la transaction et ne fuit pas vers la requête suivante du pool de connexions.

**Conséquences.**
- Le profil de risque s'inverse : avec un schéma par tenant, PostgreSQL garantissait l'étanchéité. Avec `tenant_id`, un `WHERE` oublié devient une fuite inter-clients — un incident RGPD, pas un bug. Le RLS ramène la garantie au niveau de la base : un scope oublié renvoie zéro ligne au lieu des lignes d'autrui.
- Les migrations de schéma deviennent instantanées au lieu d'être répétées N fois.
- **Les requêtes inter-tenants redeviennent possibles** : tableau de bord CUMA agrégeant les adhérents, benchmark de marge entre exploitations comparables, vue coopérative sur ses apporteurs. C'est probablement le principal gain fonctionnel de la migration. À concevoir comme un chemin explicite et audité (rôle dédié, bypass RLS tracé), jamais comme un `unscoped` opportuniste.

**Points de vigilance à l'implémentation.**

1. **Index uniques composites.** Toute contrainte d'unicité doit devenir `(tenant_id, ...)`. Ekylibre en compte beaucoup : numéros de compte, numéros de facture, codes produit, références de parcelle. Une seule oubliée et un agriculteur ne peut plus créer sa facture parce qu'un autre tenant a utilisé le numéro. Le symptôme apparaît en production, chez un client, un jour de clôture.

   *Mitigation :* un test qui scanne `pg_indexes` et échoue sur tout index unique d'une table portant `tenant_id` sans `tenant_id` en première position. Vingt lignes.

2. **Clés étrangères composites.** Une FK classique n'empêche pas une `Sale` du tenant A de référencer un `Client` du tenant B. Pour les tables comptables et réglementaires, passer en `(tenant_id, client_id) → (tenant_id, id)`. Coûteux : réserver aux tables où l'incohérence a des conséquences fiscales.

3. **Index GiST composites.** Les requêtes parcellaires filtrent sur `tenant_id` *et* font de l'intersection spatiale. Un index GiST sur `shape` seul scanne la géométrie de tous les tenants avant de filtrer.

   ```sql
   CREATE EXTENSION IF NOT EXISTS btree_gist;
   CREATE INDEX ON land_parcels USING gist (tenant_id, shape);
   ```

   Sans cela, les écrans cartographiques se dégradent linéairement avec le nombre de clients.

4. **Tables hors tenancy.** Solid Queue, Solid Cache et Solid Cable ne sont pas multi-tenant et ne doivent pas être soumises au RLS. Base séparée ou rôle distinct.

5. **Schéma nommé.** Placer les tables applicatives dans un schéma `ekylibre` et réserver `public` aux extensions (PostGIS). Simplifie les dumps, les restaurations partielles, et évite les surprises de `search_path`.

---

### ADR-003 — Types d'identifiants : UUID pour `tenant_id`, UUIDv7 pour les entités terrain

**Statut :** **décidé (13 septembre 2026)** — PostgreSQL **18**, donc `uuidv7()`
native ; UUIDv7 pour ce que le terrain produit, dans une forme que l'application
mobile et Duke partagent ; `tenant_id` en `uuid`, le nom actuel du tenant
(`phaurigot`, `sci-chenes-verts`…) devenant le `slug` de la table `tenants`

**Contexte.** Deux questions distinctes se cachent derrière « quel type pour les identifiants ». `tenant_id` est un discriminant : quelques centaines à quelques milliers de valeurs répétées sur des dizaines de millions de lignes. Les PK métier sont des milliards de valeurs distinctes, et c'est là que se joue la synchronisation offline.

**Décision 3a — `tenant_id` en `uuid`.**

L'argument du coût de stockage (16 octets contre 8) ne tient pas : depuis PostgreSQL 13, la déduplication B-tree compresse les entrées à valeur de clé identique. Avec un millier de valeurs distinctes répétées des millions de fois, la colonne de tête coûte quasiment zéro dans les index btree. Le surcoût réel se limite au tas et aux index GiST — moins d'un gigaoctet à l'échelle visée.

Ce qui tranche : **`tenant_id` n'est pas un identifiant de base de données, c'est le jeton d'identité inter-services.** Il vit dans le claim JWT, dans `duke`, dans `voice-gateway`, dans les logs. Keycloak fournit déjà des UUID pour ses groupes et organizations. Prendre le même évite une table de correspondance et un aller-retour par requête dans chaque service.

Ajouter un `slug` lisible sur la table `tenants` (`gaec-dupont`) pour les logs et l'exploitation.

**Décision 3b — UUIDv7 pour les entités créées sur le terrain.**

C'est la décision réellement irréversible. L'application mobile doit créer une intervention sans réseau, donc générer son identifiant côté client. Sans cela : identifiants temporaires et table de réconciliation à la synchronisation — la source de bugs la plus vicieuse en offline-first, parce que les erreurs n'apparaissent qu'après plusieurs cycles.

UUIDv7 plutôt que v4 : le préfixe temporel préserve la localité d'insertion et évite l'éclatement des index B-tree que provoque l'UUID aléatoire. PostgreSQL 18 expose `uuidv7()` nativement ; en dessous, `pg_uuidv7` ou génération côté Ruby.

**Périmètre.** Toutes les tables ne sont pas concernées. Les tables jamais créées hors ligne — écritures comptables, lignes de TVA, référentiels — restent en `bigint`. Cibler `interventions`, `observations`, `tasks`, les pièces jointes, et tout ce que le terrain produit.

**Fenêtre de décision.** La fusion des schémas impose de toute façon de renuméroter les PK (chaque schéma a son `id = 1`). Écrire des UUIDv7 plutôt que des entiers décalés coûte le même effort. **Séparer les deux passages oblige à réécrire les mêmes tables deux fois.**

**Vérification préalable.** Contrôler qu'aucun plugin ni export réglementaire ne sérialise des `id` numériques : formats d'échange agricoles, exports comptables, intégrations EDI, `ekylibre-ednotif`. C'est une dépendance invisible dans le schéma qui casse à la première déclaration.

---

### ADR-004 — Authentification centralisée via Keycloak

**Statut :** proposé

**Contexte.** Quatre consommateurs au minimum — web, mobile, `duke`, plugins tiers — plus un besoin de délégation : `duke` doit agir au nom de l'agriculteur, pas via un compte de service omnipotent.

**Décision.** Keycloak auto-hébergé comme fournisseur d'identité OIDC.

- Le `tenant_id` est porté par un claim personnalisé du JWT. **Tous les services le résolvent depuis le jeton, jamais depuis le sous-domaine ou un paramètre de requête.**
- `duke` et `voice-gateway` utilisent le token exchange pour obtenir un jeton délégué portant l'identité et le tenant de l'utilisateur final. Ils héritent ainsi automatiquement de l'isolation RLS.
- L'application mobile utilise le device flow ou l'Authorization Code + PKCE.
- Les plugins out-of-process déclarent des scopes OAuth dans leur manifeste (ADR-010).

**Conséquences.**
- Souverain et auto-hébergeable, cohérent avec le positionnement.
- Une brique d'infrastructure supplémentaire à exploiter et à sauvegarder.
- Migration des comptes V5 à prévoir : script d'import une fois, puis Keycloak fait autorité.

**Alternative écartée.** Étendre Devise avec Doorkeeper : viable pour deux consommateurs, insuffisant pour la délégation de jetons et l'ouverture à des plugins tiers.

---

### ADR-005 — Canal de saisie terrain : port `Channel::Adapter`, Telegram et messagerie souveraine — WhatsApp écarté

**Statut :** **décidé (13 septembre 2026)** — révision : WhatsApp est abandonné

**Contexte.** Le canal d'entrée conditionne l'adoption. WhatsApp et Telegram permettent tous deux image, texte et vocal.

| | Telegram Bot API | WhatsApp Cloud API |
|---|---|---|
| Mise en route | une après-midi | vérification Meta Business, numéro dédié |
| Coût | gratuit | par message, variable selon pays |
| Templates | aucun | validation Meta pour tout message non sollicité |
| Fichiers | 20 Mo (2 Go en Bot API auto-hébergé) | via media ID, URLs éphémères |
| Adoption agriculteurs FR | marginale | massive |

**Décision (révisée).** `voice-gateway` expose un port `Channel::Adapter` —
primitives `receive_media`, `receive_text`, `send_ack` — avec :

- **Telegram** comme implémentation de référence **et de production** :
  développement sans friction, sans coût par message, sans boucle d'approbation ;
- **une messagerie auto-hébergeable** comme cible de souveraineté — Matrix
  (serveur Synapse) est le candidat sérieux, XMPP l'alternative ;
- **SMS / e-mail** comme repli, à prévoir dans le port sans l'implémenter
  immédiatement.

**WhatsApp Cloud API est écarté**, pour deux raisons qui se cumulent. L'objectif
à un an est de rénover la pile **en conservant 100 % de briques open source**
(roadmap § 12.1) : router les observations terrain par Meta le contredit
frontalement. Et depuis le 1er octobre 2026, Meta facture chaque message métier,
y compris les réponses de service dans la fenêtre de 24 heures — le modèle
économique sur lequel reposait l'adaptateur a disparu en cours de rédaction.

**Ce que cette décision ne règle pas, et qu'il faut dire.** Telegram supprime le
coût et la dépendance à Meta, mais **son serveur reste propriétaire** : seul le
client et le *Bot API server* sont ouverts, et ce dernier dialogue de toute façon
avec l'infrastructure Telegram. La chaîne n'est donc pas « 100 % open source »
pour autant. Telegram est le bon choix pour démarrer — gratuit, sans friction,
massivement installé — mais la cible souveraine reste une messagerie
auto-hébergeable, et c'est le rôle du port de rendre ce passage possible sans
réécrire `voice-gateway`.

**Pour mémoire, ce qui a fait écarter WhatsApp.** L'API On-Premises a été fermée
le 23 octobre 2025 : tout passait désormais par les serveurs Meta. Et depuis le
1er octobre 2026, Meta facture chaque message métier, y compris les réponses de
service dans la fenêtre de 24 heures, auparavant gratuites — c'est précisément le
régime sur lequel repose le modèle Tellia.

*Conséquence de conception, qui reste valable quel que soit le canal :* **ne pas
répondre dans le fil de discussion par défaut.** Le bot émet un accusé de
réception unique et groupé ; la boucle de validation se fait dans l'application
ou sur le web. La raison n'est plus la facture, mais l'ergonomie : un écran de
validation vaut mieux qu'un échange de texte, et c'est ce que dit
[ui_ux_v6.md](ui_ux_v6.md).

**Ce qui reste à documenter en conformité.** Quel que soit le canal tiers retenu,
la ligne est la même : il ne transporte que le média brut que l'agriculteur a
lui-même choisi d'envoyer ; la transcription et l'extraction s'exécutent sur
infrastructure propre ; aucune donnée agronomique ne repart chez le fournisseur
du canal.

---

### ADR-006 — `duke` est un service d'extraction contrainte, pas un chatbot

**Statut :** proposé

**Contexte.** `duke` est aujourd'hui positionné comme un chatbot. La valeur du modèle Tellia n'est pas conversationnelle : c'est la transformation d'une conversation en enregistrements typés et propres.

**Décision.** `duke` produit du JSON validé contre un schéma dérivé des modèles `Intervention`, `Observation` et `Task`, **jamais du texte libre**.

- Les vocabulaires `onoma` / Lexicon deviennent des énumérations fermées dans le schéma.
- La reconnaissance d'entités (spaCy) pré-résout les entités — parcelle, intrant, culture — **avant** l'appel au modèle. C'est ce qui rend le dispositif frugal : le LLM arbitre, il ne cherche pas.
- La résolution s'appuie sur le contexte du tenant : le parcellaire réel de l'exploitation, son catalogue d'intrants, son cheptel.
- Le RAG documentaire (protocoles, fiches techniques déposées par le client) alimente les réponses agronomiques, pas l'extraction.

**Décision corollaire — `duke` n'accède jamais directement à la base.** Il consomme l'API de `eky-core` avec un jeton délégué. Toute exception dupliquerait la logique métier en Python et la désynchroniserait en six mois. Seule dérogation : la lecture de Lexicon, qui ne porte aucune règle métier.

**Exemple.** « J'ai passé du cuivre sur la parcelle du moulin » produit un intrant résolu contre le catalogue phytosanitaire, une parcelle résolue contre le parcellaire du tenant, une date. Pas de prose.

---

### ADR-007 — Validation humaine obligatoire avant écriture métier

**Statut :** proposé

**Contexte.** Une intervention phytosanitaire mal extraite écrite directement en base produit un registre de traçabilité faux et un contrôle PAC raté.

**Décision.** `duke` écrit dans une table `pending_records` avec un score de confiance et la trace de l'extraction (transcription, entités résolues, alternatives écartées). L'écriture métier n'est déclenchée que par une validation explicite de l'agriculteur.

- Validation en un geste : notification, écran mobile dédié, ou réponse structurée.
- Les enregistrements à confiance élevée peuvent être groupés en validation par lot, jamais supprimés.
- Les validations et corrections constituent le jeu de données d'amélioration continue — gratuitement, et sur données réelles du domaine.

**Conséquences.** Un aller-retour supplémentaire dans le parcours utilisateur, assumé. C'est la différence entre un outil de confort et un outil dont la sortie est opposable en contrôle.

---

### ADR-008 — Contrat de synchronisation mobile explicite

**Statut :** proposé — **spec à écrire avant toute ligne de code**

**Contexte.** `zero-mobile` est offline-first. C'est le point dur technique du projet, plus que la tenancy.

**Décision.** Un endpoint dédié `/sync/v1`, jamais du REST générique.

- Protocole pull/push : `pull(lastPulledAt)` retourne créations, mises à jour et suppressions ; `push(changes)` soumet les modifications locales.
- **Chaque table synchronisable porte `updated_at` et `deleted_at`** (tombstones). Une suppression physique casse la synchronisation des clients hors ligne depuis longtemps.
- Les identifiants sont générés côté client (ADR-003b).
- Politique de conflit **explicite et documentée par entité** : dernier écrivain gagne au niveau du champ pour les observations et tâches ; append-only sans écrasement pour tout objet à portée comptable ou réglementaire.
- Le BFF façonne la charge utile : un client ne synchronise que son périmètre (ses parcelles, sa campagne en cours), pas l'intégralité du tenant.

**Conséquences.** Contrainte structurante sur le modèle de données : toute nouvelle table destinée au terrain doit respecter le contrat dès sa création. À intégrer dans la revue de code.

---

### ADR-009 — Interopérabilité facture électronique : connecteur multi-plateformes, pas de plateforme propre

**Statut :** décidé

**Contexte réglementaire — révisé au 13 septembre 2026.** Trois évolutions depuis la rédaction initiale des specs :

1. **Vocabulaire.** La PDP (Plateforme de Dématérialisation Partenaire) s'appelle désormais **Plateforme Agréée (PA)**. À corriger dans les specs et dans le code, sous peine de deux ans de confusion interne.
2. **Rôle du PPF réduit.** Le portail public ne propose plus de portail gratuit d'émission. Pour émettre comme pour recevoir, le passage par une Plateforme Agréée est obligatoire ; le portail public conserve un rôle d'annuaire central et de concentrateur de données fiscales. **Il n'existe plus de porte de sortie gratuite pour le petit exploitant.**
3. **Calendrier effectif.** La réception est obligatoire depuis le 1er septembre 2026 pour toutes les entreprises assujetties à la TVA. L'émission l'est déjà pour les grandes entreprises et ETI ; les PME et TPE suivent au 1er septembre 2027. Les sanctions : 15 € par facture non conforme, plafonné à 15 000 € par an, et 250 € par transmission d'e-reporting manquante.

La base utilisateurs d'Ekylibre relève massivement de la seconde catégorie : **douze mois sur l'émission, mais la réception est déjà en retard.**

**Décision.**

- **Ne pas devenir Plateforme Agréée.** L'immatriculation DGFiP implique un audit de sécurité, des obligations d'archivage et de disponibilité qui constituent un métier à plein temps. Ce n'est pas le nôtre.
- **`EInvoicing::Gateway` devient le produit**, et non l'intégration Qonto. Qonto redevient un adaptateur parmi N.
- **Le choix de la PA est une donnée par tenant**, pas une configuration globale. Un agriculteur arrive fréquemment déjà raccordé chez la PA de sa coopérative ou de son centre de gestion : il faut s'y brancher, pas le faire migrer.
- **Le pivot d'interopérabilité est le format, pas l'API.** Si le domaine émet et consomme du Factur-X, UBL et CII propres, chaque nouvel adaptateur de PA se réduit à du transport et de l'authentification. L'investissement va là, pas dans les SDK fournisseurs.
- **Ne pas construire la comptabilité ni la paie MSA.** Interopérer avec les acteurs établis (API ISAGRI, AGIRIS, centres de gestion).

**Écart technique identifié.** Le moteur de rapport actuel produit du PDF simple, pas du PDF/A-3 requis par Factur-X. Deux options : la bibliothèque `factur-x` côté Python dans un satellite, ou une gem Ruby de post-traitement. **Sur le chemin critique de septembre 2027 — à trancher en phase 2.**

---

### ADR-010 — Système de plugins à deux niveaux

**Statut :** proposé

**Contexte.** L'organisation compte déjà une vingtaine de plugins Rails engines. L'ouverture à des contributeurs non-Ruby est un levier d'écosystème.

**Décision.** Deux niveaux distincts, avec des usages explicitement séparés.

**Niveau 1 — in-process (Rails engines).** Le DSL `Ekylibre::Plugin` existant. Réservé à ce qui touche au modèle de données et aux migrations : plugins métier (`viti`, `hve`, `idea`), intégrations IoT (`sencrop`, `weenat`, `traccar`), connecteurs réglementaires (`ednotif`).

**Niveau 2 — out-of-process.** Un manifeste JSON déclarant :
- des scopes OAuth consommés (validés par Keycloak),
- des webhooks sur événements métier,
- des points d'extension UI (voir ADR-011).

Permet d'écrire un plugin en Python, Node ou autre sans toucher au core. C'est ce qui rend l'écosystème viable au-delà de la communauté Ruby.

**Transport d'événements.** Table outbox dans PostgreSQL plus un diffuseur léger. Éviter Kafka : hors de proportion avec le volume et le budget d'exploitation.

---

### ADR-011 — Composition d'écrans déclarative par profil métier

**Statut :** proposé

**Contexte.** Un éleveur, un viticulteur, un céréalier et une CUMA n'ont ni le même vocabulaire ni les mêmes écrans d'accueil. Forker l'interface par filière est ingérable.

**Décision.** `eky-core` sert un **manifeste d'écran par profil métier**. Le web (Hotwire) et le mobile (React Native) rendent chacun ce manifeste avec leurs composants natifs.

- Un éleveur voit bâtiments, lots, interventions ; un viticulteur voit parcelles, cépages, traitements.
- Les plugins de niveau 2 injectent leurs blocs dans ces manifestes via leurs points d'extension.
- Le vocabulaire suit le profil et alimente également la résolution d'entités de `duke` (ADR-006).

**Conséquences.** Une seule base de code d'interface. Le coût se déplace vers la conception du langage de manifeste : le garder volontairement pauvre (liste de blocs typés, pas un moteur de rendu généraliste), sous peine de réinventer un framework.

---

### ADR-012 — Adopter les défauts Rails 8.1

**Statut :** **décidé (13 septembre 2026)** — Solid Queue, Solid Cache et Solid
Cable remplacent Redis et Sidekiq ; `active_list` est remplacé intégralement, ce
qui lève le préalable de Propshaft

**Décision.** Solid Queue, Solid Cache et Solid Cable remplacent Redis et Sidekiq. Propshaft remplace Sprockets.

**Conséquences.**
- Redis et Sidekiq disparaissent du schéma d'infrastructure : une brique et un point de panne en moins.
- **Piège :** Solid Queue avec un discriminant `tenant_id` exige une base ou un rôle dédié, hors RLS, sinon les politiques de sécurité s'appliquent aux jobs et produisent des files vides ou des jobs fantômes (voir ADR-002, point 4).
- Migration Sprockets → Propshaft à budgéter : c'est un poste de travail non trivial sur une base de code de cet âge.
- **Bonne nouvelle vérifiée :** `solid_queue` 1.7 ne dépend que d'`activejob`, `activerecord`, `railties`, `fugit` et `thor` — **pas de `rack`**. Le blocage que `turnout` faisait peser sur la file d'attente ne valait que pour `sidekiq` 8 ; en quittant sidekiq, il disparaît. `turnout` ne retient plus que Rack 3 lui-même.

---

## 4. Registre de risques

| # | Risque | Prob. | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Fuite inter-tenants après passage en `tenant_id` | Moyenne | **Critique** (RGPD) | RLS avec `FORCE`, rôle non-propriétaire, tests d'isolation automatisés en CI |
| R2 | Index unique non converti découvert en production | **Élevée** | Élevé | Test de scan `pg_indexes` bloquant en CI (ADR-002) |
| R3 | Décision sur les types d'identifiants reportée après la fusion | Moyenne | Élevé | Trancher ADR-003 avant le démarrage de la fusion ; double réécriture sinon |
| ~~R4~~ | ~~Hausse tarifaire WhatsApp~~ — **sans objet** : WhatsApp écarté (ADR-005 révisé) | — | — | — |
| R5 | Extraction LLM produisant des registres phyto erronés | Moyenne | **Critique** (contrôle PAC) | Validation humaine obligatoire, schéma contraint (ADR-006, 007) |
| R6 | Dérive du contrat de synchro mobile | Élevée | Élevé | Spec écrite avant code, contrainte intégrée en revue |
| R7 | Absence de PDF/A-3 bloquante pour l'émission 2027 | Moyenne | Élevé | Arbitrage en phase 2, pas plus tard |
| R8 | Dépendance à un canal tiers (Telegram) encore propriétaire côté serveur | Certaine | **Faible** — Meta écarté | Port `Channel::Adapter` conçu pour accueillir une messagerie auto-hébergeable (Matrix) sans réécriture ; conformité documentée |
| R9 | Sérialisation d'`id` numériques dans un export réglementaire | Moyenne | Élevé | Audit préalable des plugins et exports (ADR-003) |
| R10 | Dégradation des écrans cartographiques à la montée en charge | Moyenne | Moyen | Index GiST composites `btree_gist` dès la migration |
| R11 | Migration Sprockets → Propshaft sous-estimée | Élevée | Moyen | Lot de travail dédié en phase 0, pas un effet de bord |

---

## 5. Roadmap phasée

### Phase 0 — Socle technique

*Objectif : une V6 qui tourne, isolée, sur Rails 8.1.*

- Migration Rails 5.2 → 8.1, Ruby 2.6 → 3.4
- Fusion des schémas, ajout de `tenant_id`, arbitrage ADR-003
- RLS activé sur toutes les tables tenant, rôle applicatif non-propriétaire
- Conversion des index uniques et GiST
- Solid Queue / Cache / Cable, base dédiée hors RLS
- Sprockets → Propshaft

**Critères de sortie.**
- Suite de tests d'isolation : toute requête sans `app.tenant_id` positionné retourne zéro ligne, sur 100 % des tables tenant.
- Le scan `pg_indexes` passe sans exception.
- Un tenant de production restauré et servi correctement en environnement de recette.
- Aucune régression fonctionnelle sur la suite existante.

### Phase 1 — Identité et API

*Objectif : plusieurs consommateurs, une seule identité.*

- Keycloak déployé, import des comptes V5
- Claim `tenant_id`, middleware de résolution, token exchange
- API v1 stabilisée et versionnée
- Réception facture électronique opérationnelle (obligation déjà en vigueur)

**Critères de sortie.**
- Web et mobile authentifiés via Keycloak, Devise retiré du chemin nominal.
- `duke` obtient un jeton délégué et hérite de l'isolation RLS sans code spécifique.
- Un tenant pilote reçoit des factures via une PA de bout en bout.

### Phase 2 — Saisie terrain conversationnelle

*Objectif : la promesse produit différenciante.*

- `voice-gateway` avec port `Channel::Adapter`, adaptateur Telegram
- ASR asynchrone sur infrastructure propre (note vocale traitée en quelques secondes)
- `duke` repositionné en extraction contrainte, schéma JSON dérivé des modèles
- `pending_records` et écran de validation
- Arbitrage PDF/A-3 pour Factur-X

**Critères de sortie.**
- Une note vocale devient une intervention validée en moins de deux minutes, bout en bout.
- Taux d'extraction correcte mesuré sur un corpus réel d'au moins 200 messages, par filière.
- Aucune écriture métier possible sans validation explicite (test automatisé).

*L'appel téléphonique en temps réel est explicitement hors périmètre : la latence sous la seconde impose une infrastructure différente, pour 20 % de valeur additionnelle.*

### Phase 3 — Mobile offline et interfaces par profil

- Contrat `/sync/v1` implémenté, tombstones, politiques de conflit
- `zero-mobile` synchronisé de bout en bout
- Manifestes d'écran par profil métier (ADR-011)

**Critères de sortie.**
- Une journée complète de saisie hors réseau se synchronise sans perte ni doublon.
- Trois profils métier distincts servis par une seule base de code d'interface.

### Phase 4 — Écosystème et émission facture électronique

- Manifeste de plugins out-of-process, webhooks, outbox
- Adaptateurs multi-PA, choix de PA par tenant
- Émission Factur-X conforme

**Critères de sortie.**
- Émission conforme validée par au moins deux PA distinctes, avant le 1er septembre 2027.
- Un plugin de référence hors Ruby, développé sans modification du core.

### Différé — `agro-data`

Sentinel-2, RPG, météo. À réévaluer après la V6.0 : utile, mais non bloquant, et concurrencé par des services existants.

---

## 6. Annexe — Inventaire de l'organisation GitHub

Relevé partiel (≈30 dépôts sur 89 ; la pagination GitHub est bloquée en accès anonyme).

**Core.** `ekylibre` (Ruby, AGPL-3.0, 488 étoiles, 171 forks)

**Gems socles.** `charta` (géométries / PostGIS), `onoma` (nomenclatures), `cartography` (wrapper Leaflet), `active_list`, `i18n-complements`, `agric` (police d'icônes agricoles), `xsd_errors_parser`

**Plugins métier.** `ekylibre-viti`, `ekylibre-hve`, `ekylibre-idea`, `ekylibre-economic`, `ekylibre-planning`, `ekylibre-banking`, `ekylibre-qonto`, `ekylibre-ednotif`, `ekylibre-imepe`, `ekylibre-baqio`

**Plugins IoT et partenaires.** `ekylibre-sencrop`, `ekylibre-weenat`, `ekylibre-traccar`, `ekylibre-samsys`, `ekylibre-natuition`, `ekylibre-agro-monitoring`

**Satellites.** `duke` (Python), `zero-mobile` (TypeScript)

**Infrastructure.** `docker-base-images`, `ekylibre-hajimari`, `demo-data`

*Réserve : de nombreux dépôts affichent une date de push des 10-12 septembre 2026, ce qui évoque une opération groupée (CI ou licence) plutôt que de l'activité réelle. À vérifier avant d'en tirer un indicateur de maintenance.*

---

## 7. Décisions restant à trancher

| Sujet | Échéance | Bloquant pour |
|---|---|---|
| Type de `tenant_id` et périmètre UUIDv7 (ADR-003) | **avant la fusion des schémas** | Phase 0 |
| Génération PDF/A-3 : Python ou gem Ruby | phase 2 | Émission 2027 |
| Périmètre du langage de manifeste d'écran | phase 3 | ADR-011 |
| Liste des PA prioritaires à intégrer | phase 4 | ADR-009 |
