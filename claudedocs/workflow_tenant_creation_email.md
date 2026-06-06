# Workflow — Email d'envoi des informations de connexion à la création d'un tenant

**Demande** : À la fin de l'action `POST /admin/tenants` (formulaire `/admin/tenants/new`), ajouter une option pour envoyer un email à l'utilisateur avec ses informations de connexion (email, mot de passe généré) et l'URL de son tenant.

**Stratégie** : Systematic. Modification ciblée, surface minimale, pas d'abstraction prématurée.

---

## 1. Contexte technique (vérifié)

| Élément | Localisation | Note |
|---|---|---|
| Contrôleur | `app/controllers/admin/tenants_controller.rb` | `create` lignes 22-51, `initialize_tenant` lignes 148-200 |
| Vue formulaire | `app/views/admin/tenants/new.html.haml` | Champs email/password lignes 8-14 |
| Routes | `config/routes.rb:6-19` | `namespace :admin { resources :tenants }` |
| URL du tenant | `lib/ekylibre/tenant.rb:38` (`host`) + `ENV['HOST_DOMAIN_NAME']` | Format : `https://<name>.<domain>/` |
| Mot de passe généré | `app/controllers/admin/tenants_controller.rb:199` | Renvoyé par `initialize_tenant` si non fourni |
| Mailer de référence | `app/mailers/registration_mailer.rb` | Hérite de `Devise::Mailer`, vues HAML dans `app/views/devise/mailer/` |
| Sender | `config/initializers/devise.rb:26` → `ENV['MAILER_SENDER']` | Utiliser le même sender |
| SMTP | `config/environments/production.rb:80-92` | SMTP si `ENV['SMTP_ADDRESS']`, sinon sendmail |
| i18n mailers | `config/locales/{eng,fra}/mailers.yml` | Seulement `eng`/`fra` actifs (voir CLAUDE.md) |

**Point d'accroche** : entre la ligne 41 (`generated_password = initialize_tenant(name)`) et la ligne 46 (`redirect_to admin_root_path`), tout en restant dans le bloc `Ekylibre::Tenant.switch(name)` (lignes 39-42).

⚠️ Le `switch` ferme avant le `redirect_to`. Vérifier en phase 2 si l'envoi doit se faire dans le `switch` (pour accéder à `Preference[:language]` du tenant) ou en dehors (parce que les paramètres email/url proviennent du formulaire admin et du `params`).

---

## 2. Phases d'implémentation

### Phase 1 — Vue formulaire (UI)

**Fichier** : `app/views/admin/tenants/new.html.haml`

**Modification** : Ajouter, après le bloc `Admin account` (ligne 14), un nouveau bloc `Notification` contenant :
- Une checkbox `send_credentials_email` (cochée par défaut)
- Un libellé clair : « Envoyer les informations de connexion par email à l'adresse ci-dessus »

**Critère** : la case ne doit PAS introduire de nouveau champ email (réutilise le champ `email` déjà présent ligne 10).

**Validation manuelle** :
- Ouvrir `/admin/tenants/new`, voir la case
- La décocher, soumettre → pas d'envoi
- La cocher, soumettre → envoi (testé en phase 4)

---

### Phase 2 — Mailer

**Nouveau fichier** : `app/mailers/tenant_creation_mailer.rb`

**Conventions à respecter** :
- Hériter de `ActionMailer::Base` (pas `Devise::Mailer`, car non lié à un `User` Devise — l'utilisateur n'existe pas encore au moment où on construit le mail si on appelle hors du `switch`)
- `default from:` lu depuis `Devise.mailer_sender` pour rester cohérent avec `RegistrationMailer`
- Méthode unique : `credentials(email:, tenant:, password:, url:, locale:)`
- Le `locale` est passé explicitement (le mailer ne tourne PAS dans le contexte du tenant)

**Vues** : `app/views/tenant_creation_mailer/credentials.{html,text}.haml`
- Version HTML : sobre, lien cliquable vers `url`, présentation tableau email/password/url
- Version texte : indispensable pour les clients sans HTML
- ⚠️ Ne PAS imprimer le mot de passe sans contexte — préciser qu'il doit être changé à la première connexion (si on adopte cette politique)

**i18n** : Ajouter sous `tenant_creation_mailer.credentials:` dans :
- `config/locales/eng/mailers.yml`
- `config/locales/fra/mailers.yml`

Clés : `subject`, `greeting`, `intro`, `url_label`, `email_label`, `password_label`, `password_warning`, `signature`.

**Validation manuelle** :
- `bundle exec rails c` → `TenantCreationMailer.credentials(email: 'a@b.com', tenant: 'demo', password: 'x', url: '...', locale: 'eng').deliver_now` ne lève pas d'erreur (avec `delivery_method = :test`)
- Inspecter `ActionMailer::Base.deliveries.last.body` HTML et texte

---

### Phase 3a — Validation du nom du tenant

**Contexte vérifié dans le contrôleur (`app/controllers/admin/tenants_controller.rb:22-34`)** :

- ✅ **Unicité déjà gérée** : lignes 31-34, `Ekylibre::Tenant.exist?(name)` rend un message d'erreur si le nom est déjà pris. **Aucun changement nécessaire sur ce point** — sauf si on veut harmoniser le message (cf. ci-dessous).
- ❌ **Noms réservés non gérés** : actuellement, rien n'empêche de créer un tenant nommé `admin`, `duke`, `traccar`, ou `ekylibre`. Or ces sous-domaines sont déjà utilisés par d'autres applications sur le même domaine racine (`*.ekylibre.<tld>`), donc créer un tenant homonyme rendrait le tenant inaccessible (collision DNS/routing) **et** masquerait potentiellement l'app existante si le routing fait fallback sur l'app Rails.

**Modifications** :

1. **Constante de noms réservés** — déclarer dans `app/controllers/admin/tenants_controller.rb`, avant le `def new` :
   ```
   RESERVED_TENANT_NAMES = %w[admin duke traccar ekylibre].freeze
   ```
   Justification du placement local (pas dans `Ekylibre::Tenant`) : la réservation est liée aux **autres apps déployées sur le domaine**, pas à une contrainte interne du modèle tenant. Si demain on déploie une nouvelle app voisine, on touche le contrôleur admin et pas la lib `Ekylibre::Tenant`. À reconsidérer si la liste grossit ou si elle doit être partagée (ex : config YAML, ENV).

2. **Garde dans `create`**, à insérer **après** la normalisation (ligne 24) et **avant** le check `exist?` (ligne 31) :
   ```
   if RESERVED_TENANT_NAMES.include?(name)
     flash.now[:error] = "Le nom '#{name}' est réservé et ne peut pas être utilisé."
     return render :new
   end
   ```
   Ordre voulu : blank → réservé → existant. La normalisation `gsub(/[^a-z0-9_]/, '_')` ligne 24 s'applique **avant** la comparaison, donc un utilisateur saisissant `Admin`, `ADMIN ` ou `admin!` tombera tous sur `admin` et sera bloqué.

3. **Validation côté formulaire (optionnel, défense en profondeur)** dans `app/views/admin/tenants/new.html.haml` ligne 5 : ajouter un attribut `pattern` ou un `data-reserved-names` lu par un petit JS. **Non-bloquant** — la garde serveur suffit. À skipper pour la v1.

**Pièges identifiés** :
- Le check `exist?` ne tient pas compte des **schémas PostgreSQL persistants** (`public`, `lexicon`). À vérifier rapidement en phase d'implémentation : est-ce que `Ekylibre::Tenant.create('public')` casserait ? Si oui, ajouter `public` et `lexicon` à la liste réservée — mais c'est un **élargissement de scope**, à confirmer avec l'utilisateur avant d'ajouter.
- Casse : la normalisation ligne 24 force déjà en minuscules, donc la liste réservée peut rester en minuscules.
- Tirets/espaces : `Eky Libre` → `eky_libre`. Pas de collision avec `ekylibre`. OK.

**Validation manuelle** :
- Tenter `admin`, `Admin`, `ADMIN`, `admin!` → tous bloqués avec le même message.
- Tenter `ekylibre2` → autorisé (la liste est exacte, pas un préfixe).
- Tenter un tenant existant → message « existe déjà » (comportement actuel, non régressé).

---

### Phase 3b — Contrôleur (envoi de l'email)

**Fichier** : `app/controllers/admin/tenants_controller.rb`

**Modifications dans `create` (lignes 22-51)** :

1. Avant le `Ekylibre::Tenant.create` (ligne 36), capturer la décision d'envoi :
   ```
   send_email = params[:send_credentials_email].present?
   ```

2. À la sortie du `Ekylibre::Tenant.switch` (après ligne 42, avant le `flash` ligne 43) :
   - Construire l'URL : `tenant_url = "https://#{name}.#{ENV['HOST_DOMAIN_NAME'] || 'ekylibre.localhost'}/"` (réutiliser la même logique que `index`, ligne 14)
   - Récupérer la langue : on a déjà `params[:language]` (utilisé ligne 152 dans `initialize_tenant`). Default `eng`.
   - Récupérer le mot de passe à envoyer : `password_to_send = generated_password || params[:password]`
   - Si `send_email && params[:email].present? && password_to_send.present?`, appeler `TenantCreationMailer.credentials(...).deliver_later`

3. **Robustesse** : entourer l'envoi d'un `rescue => e` qui log l'erreur et ajoute un avertissement au flash, mais ne casse PAS la création du tenant (le schéma est déjà créé).

**Choix `deliver_later` vs `deliver_now`** :
- `deliver_later` met dans Sidekiq → l'`apartment-sidekiq` middleware essaiera de switcher de tenant et **plantera** car le job n'a pas de tenant.
- `deliver_now` envoie synchrone → le formulaire admin attend l'envoi (acceptable car action peu fréquente, et déjà lent à cause de `tenant:init`).
- **Décision** : `deliver_now`. Confirme ce point en phase 4 selon la config Sidekiq.

**Message flash** :
- Si email envoyé : ajouter « Email envoyé à <email> » au flash existant ligne 44-45
- Si email échoué : ajouter un flash `:alert` distinct

**Validation manuelle** :
- Créer un tenant via le formulaire avec case cochée → flash mentionne l'envoi
- Vérifier dans les logs ou dans la boîte de réception (cf. phase 4)
- Créer sans cocher → comportement inchangé

---

### Phase 4 — Vérification end-to-end

**En développement** :
- `ActionMailer::Base.delivery_method` est probablement `:letter_opener` ou `:test` — vérifier `config/environments/development.rb`. Si pas configuré : passer à `:letter_opener` dans le `Gemfile` dev (existe déjà ?) OU `:test` puis inspecter `deliveries`.
- Lancer le stack docker, créer un tenant, observer le mail.

**Production** :
- Pré-requis : `ENV['MAILER_SENDER']` et `ENV['SMTP_*']` configurés (déjà documenté dans CLAUDE.md indirectement via `config/environments/production.rb`).
- Pas de test en prod dans le cadre de cette feature — l'ops aura besoin de ces variables avant déploiement.

**Tests automatiques** (optionnels mais recommandés) :
- `test/mailers/tenant_creation_mailer_test.rb` : un test qui vérifie le sujet, les destinataires, la présence de l'email/url/password dans le corps.
- Pas de test du contrôleur admin : il dépend de `Ekylibre::Tenant.create` qui crée un vrai schéma — coûteux et hors scope.

---

## 3. Arbre de dépendances

```
Phase 1 (vue)         ─┐
                       ├─► Phase 3b (contrôleur email)  ─► Phase 4 (vérification)
Phase 2 (mailer)      ─┤
Phase 3a (validation) ─┘
```

Phases 1, 2 et 3a sont **indépendantes** et parallélisables (vue HAML, mailer+i18n, garde contrôleur). Phase 3b dépend de Phase 2 (le mailer doit exister). Phase 4 dépend de tout le reste.

Note : Phase 3a et 3b touchent le même fichier (`admin/tenants_controller.rb`) — si on parallélise, prévoir de les rebaser/merger manuellement.

---

## 4. Points d'attention / risques

| Risque | Mitigation |
|---|---|
| `deliver_later` casse à cause de `apartment-sidekiq` | Utiliser `deliver_now` (cf. CLAUDE.md « Background Jobs ») |
| L'envoi d'email échoue et fait planter la création | `rescue` autour de l'envoi, log + flash d'avertissement |
| Mot de passe en clair dans l'email | Acceptable car c'est un mot de passe initial communiqué au créateur du tenant. Ajouter un avertissement « changez-le à la première connexion ». |
| Pas de SMTP configuré en dev | Vérifier `config/environments/development.rb` — utiliser `:letter_opener` si présent, sinon `:test` + inspection en console |
| Locales `spa`/`deu` non chargées | Ne pas ajouter de traductions dans ces fichiers (CLAUDE.md : seuls `eng`/`fra` sont actifs) |
| URL en `https://` mais dev sans certificat | En dev, l'URL `https://name.ekylibre.localhost/` peut ne pas fonctionner. Acceptable — le tenant est créé pour la prod. Optionnel : utiliser `http` en dev. |

---

## 5. Critères d'acceptation

1. ✅ Le formulaire `/admin/tenants/new` affiche une case « Envoyer les infos de connexion par email », cochée par défaut.
2. ✅ Quand on soumet avec la case cochée, un email part vers l'adresse renseignée, contenant : email, mot de passe (généré ou fourni), URL du tenant.
3. ✅ Quand la case est décochée, aucun email n'est envoyé — comportement actuel inchangé.
4. ✅ Si l'envoi échoue, le tenant est quand même créé et un avertissement apparaît dans le flash.
5. ✅ Les versions `eng` et `fra` de l'email existent ; la langue suit `params[:language]`.
6. ✅ Pas de régression sur le flash existant qui affiche le mot de passe généré (utile si l'envoi est désactivé ou échoue).
7. ✅ Tenter de créer un tenant nommé `admin`, `duke`, `traccar` ou `ekylibre` (ou une variante qui se normalise vers l'un de ces noms) est refusé avec un message clair, **sans** créer de schéma PostgreSQL.
8. ✅ La vérification d'unicité existante (`Ekylibre::Tenant.exist?`) reste fonctionnelle et son message est inchangé.

---

## 6. Fichiers touchés (résumé)

| Fichier | Action |
|---|---|
| `app/views/admin/tenants/new.html.haml` | Modif (ajout case + libellé) |
| `app/controllers/admin/tenants_controller.rb` | Modif (constante `RESERVED_TENANT_NAMES`, garde de validation, lecture param email, construction URL, appel mailer, gestion erreur, flash) |
| `app/mailers/tenant_creation_mailer.rb` | Nouveau |
| `app/views/tenant_creation_mailer/credentials.html.haml` | Nouveau |
| `app/views/tenant_creation_mailer/credentials.text.haml` | Nouveau |
| `config/locales/eng/mailers.yml` | Modif (clés `tenant_creation_mailer`) |
| `config/locales/fra/mailers.yml` | Modif (clés `tenant_creation_mailer`) |
| `test/mailers/tenant_creation_mailer_test.rb` | Nouveau (optionnel) |

---

## 7. Prochaine étape

Exécuter ce plan avec `/sc:implement` ou ouvrir une PR pour discussion préalable du wording de l'email et de la politique mot-de-passe (à montrer/à masquer/à demander de changer).
