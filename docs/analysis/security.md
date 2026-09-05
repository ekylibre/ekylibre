# Ekylibre Security Audit — branch 5.0-beta

**Date:** 2026-05-07
**Scope:** branches `main..5.0-beta` plus general codebase review. All file paths absolute.

---

## CRITICAL

### C1. CSRF protection is globally disabled — every authenticated state-changing endpoint is vulnerable
`/home/djoulin/projects/ekylibre/app/controllers/application_controller.rb:19` extends `ActionController::Base` but never calls `protect_from_forgery`. A repo-wide grep finds zero occurrences anywhere in `app/`, `lib/`, or `config/`. `config/application.rb:58-59` even shows the CSRF defaults are commented out as TODO. Rails 5.2 with `load_defaults 5.2` does NOT auto-enable CSRF without an explicit `protect_from_forgery`. CSRF meta tags are emitted (so JS that checks them works) but the server never verifies the token. Any cross-origin POST to `/backend/...`, `/admin/...`, etc. with the user's session cookie will succeed. The admin tenant create/destroy/dump/restore endpoints are reachable via CSRF if an admin's basic-auth cache is alive.
**Fix:** add `protect_from_forgery with: :exception` to `ApplicationController` and `Admin::BaseController`; explicitly opt-out only on stateless API controllers.

### C2. `Admin::BaseController` ships hardcoded default credentials `admin` / `admin`
`/home/djoulin/projects/ekylibre/app/controllers/admin/base_controller.rb:9-10` uses `ENV.fetch('ADMIN_USERNAME', 'admin')` and `ENV.fetch('ADMIN_PASSWORD', 'admin')`. If the env vars are unset (a single misconfiguration in any deployment) the admin panel accepts `admin:admin`. The admin panel can create/drop tenants, restore arbitrary archives, and download every tenant's data — this is full multi-tenant compromise.
**Fix:** refuse to boot or refuse to authenticate when `ADMIN_USERNAME`/`ADMIN_PASSWORD` are missing; require minimum length; do not provide a default.

### C3. Committed `secret_key_base` for development and test
`/home/djoulin/projects/ekylibre/config/secrets.yml:21,24` contains real (not placeholder) hex `secret_key_base` values committed for `development` and `test`. If a public deployment ever runs in dev mode (or a team member copies the dev secret to a staging env) cookies/sessions can be forged. `git ls-files config/secrets.yml` confirms the file is tracked.
**Fix:** replace both with `<%= ENV["SECRET_KEY_BASE"] %>` and add a check that aborts boot if missing in non-dev. Rotate the leaked keys.

### C4. Path traversal in admin restore upload (`Admin::RestoreController`)
`/home/djoulin/projects/ekylibre/app/controllers/admin/restore_controller.rb:18-22`: filename is taken from `file.original_filename` after `File.basename`, then written to `tmp/archives/<filename>` and the tenant name is derived from it. `File.basename` does strip directory components, but the resulting filename can still contain shell metacharacters or be controlled to overwrite an existing archive (e.g. another tenant's `foo.zip`). The derived `tenant_name` is then passed to `Ekylibre::Tenant.restore` which executes `system "unzip -d ... #{archive_file}"` (`/home/djoulin/projects/ekylibre/lib/ekylibre/tenant.rb:134`) and `psql --dbname=#{db_url}` with shell-interpolated tenant names (`tenant.rb:537-541`) — see C5.
**Fix:** sanitize filename to `[A-Za-z0-9_-]+\.zip`, reject anything else; namespace uploaded archives by an admin-supplied UUID.

### C5. Command/SQL injection via tenant name in `Ekylibre::Tenant.restore_tables_v3` and `restore`
`/home/djoulin/projects/ekylibre/lib/ekylibre/tenant.rb:134` — `system "unzip -d #{archive_path} #{archive_file} > /dev/null"` — both args are interpolated into a shell string with no escaping. Reachable from `Admin::RestoreController` (C4).
`/home/djoulin/projects/ekylibre/lib/ekylibre/tenant.rb:537-541` — `tenant_name` is interpolated directly into `echo 'DROP SCHEMA IF EXISTS "#{tenant_name}" CASCADE; ...' | psql` and into a `SET search_path` injected into the SQL stream. A tenant name containing `";` plus crafted SQL achieves DDL/DML on the postgres user (which has DROP rights on every tenant schema). The admin form sanitizes the create-name (`tenants_controller.rb:25`) but `restore` derives the tenant name from the uploaded zip filename and does not re-sanitize it (`restore_controller.rb:22`).
**Fix:** validate `tenant_name` against `/\A[a-z0-9_]+\z/` at every entry point in `Ekylibre::Tenant`; use `Shellwords.escape` for shell args; quote PostgreSQL identifiers via `ActiveRecord::Base.connection.quote_column_name`.

### C6. ZIP slip in every exchanger that calls `entry.extract(dir.join(entry.name))`
Affects `/home/djoulin/projects/ekylibre/app/exchangers/isagri/geofolia/interventions_exchanger.rb:14`, `.../land_parcels_exchanger.rb:16`, `app/exchangers/ekylibre/rides_exchanger.rb:17`, `.../georeadings_exchanger.rb:15`, `.../backup_exchanger.rb:226`, `.../pictures_exchanger.rb:16`, `app/exchangers/charentes_alliance/outgoing_deliveries_exchanger.rb:13`. None validate that the resolved path stays inside `dir`. A zip entry named `../../config/secrets.yml` (or a Rails initializer) will be written outside the temp directory. Exchangers run inside the tenant context with the app process's filesystem rights — file write anywhere the Rails user can write, including code locations on autoload paths. Restore archives are processed via `unzip` (C5) and Ekylibre's `BackupExchanger` (`backup_exchanger.rb:222-228`). The admin UI restore endpoint accepts arbitrary ZIP files.
**Fix:** before each `entry.extract`, compute `target = File.expand_path(dir.join(entry.name))` and raise unless it `start_with?(File.expand_path(dir) + File::SEPARATOR)`; also reject symlinks.

### C7. XXE in legacy backup XML parsing
`/home/djoulin/projects/ekylibre/app/exchangers/ekylibre/backup_exchanger.rb:239-241` calls `Nokogiri::XML(f) { |c| c.strict.nonet.noblanks.noent }`. `noent` ENABLES entity expansion (libxml2 reverse meaning), permitting XXE: external/local file disclosure via DOCTYPE entities. The other XML parsers (`telepac/exchanger_mixin.rb:34-36`, `process_to_wine/...:21-23`, `document_template.rb:325-326`) correctly do not set `noent` and do set `nonet`, but `BackupExchanger` is the one that actually parses user-supplied tenant restore archives.
**Fix:** remove `.noent` (use safe defaults `strict.nonet.noblanks`); explicitly set `Nokogiri::XML::ParseOptions::NOENT` off.

---

## HIGH

### H1. `Admin::TenantsController#dump_download` lets the admin pull any file under `tmp/archives/<id>.zip` with no whitelist
`/home/djoulin/projects/ekylibre/app/controllers/admin/tenants_controller.rb:103-113`: `name = params[:id]` flows directly into `archive_path = Rails.root.join('tmp', 'archives', "#{name}.zip")` then `send_file`. `params[:id]` from a route can include path traversal (`..%2F..%2Fetc%2Fpasswd`). Combined with C2 default credentials this is a remote arbitrary-file-disclosure of any path that ends in `.zip` (and Rails routing constraints will let many strange values through `:id`).
**Fix:** validate `name =~ /\A[a-z0-9_]+\z/`; require it to be in `Ekylibre::Tenant.list`.

### H2. `Admin::TenantsController#destroy` accepts arbitrary `params[:id]` and calls `Ekylibre::Tenant.drop`
`/home/djoulin/projects/ekylibre/app/controllers/admin/tenants_controller.rb:54-62`: no validation, no membership check on `Ekylibre::Tenant.list`. `drop` does check existence (`tenant.rb:76`), but combined with C2 the impact is full destruction of any tenant by URL. Also note: the action is a DELETE without CSRF (C1), so an admin who visits a malicious page while authenticated to `/admin` can have all tenants destroyed.
**Fix:** same allowlist as H1; verify `Ekylibre::Tenant.exist?(name)` and require a re-confirmation flow.

### H3. `find_by_sql`-style SQL composition in API lexicon endpoints
`/home/djoulin/projects/ekylibre/app/controllers/api/v1/lexicon/registered_phytosanitary_products_controller.rb:19-20` and `/home/djoulin/projects/ekylibre/app/controllers/api/v1/lexicon/api_phytosanitary_data_controller.rb:52` (and v2 equivalents) build `(values #{ids}) ... in (SELECT id from #{table_name})` from `elements` (request body) and a private `table_name` method. `ids` is constructed via `quote(e[:id])::integer` so casting blocks string injection in normal cases, but `table_name` is interpolated unquoted. If `table_name` is ever derived from user input via subclass selection by the API client, this becomes SQLi. Verify all callers; otherwise treat as defense-in-depth and refactor to bind params.
**Fix:** switch to `ActiveRecord::Base.send(:sanitize_sql_array, ['... IN (?)', ids])` or use parameterized values.

### H4. SQL injection in `Backend::OutgoingPaymentListsController#create`
`/home/djoulin/projects/ekylibre/app/controllers/backend/outgoing_payment_lists_controller.rb:140,144` interpolates `params[:period_reference]` directly into `where("purchases.#{params[:period_reference]} IS NOT NULL ...")` and `order(...)`. Authenticated backend users can inject SQL by sending a crafted `period_reference`.
**Fix:** whitelist `period_reference` to a known set of column names before interpolation.

### H5. SQL injection in `Account#merge` and `Entity#merge`
`/home/djoulin/projects/ekylibre/app/models/account.rb:747-749` and `/home/djoulin/projects/ekylibre/app/models/entity.rb:510-512` build `UPDATE #{table} SET #{column.name}=#{id} WHERE #{column.name}=#{other.id} AND #{column.references} IN #{models_group}`. `id` and `other.id` come from records (likely safe ints), but `models_group`, `column.references`, `column.name`, and `table` are derived from reflection metadata — generally safe but unparameterized. If any future refactor lets a controller-supplied class name reach this path (Rails' STI types come from DB), it becomes SQLi. Hardening required.
**Fix:** use `connection.quote` and `quote_column_name` consistently.

### H6. SQL/code execution risk in `general_ledgers_controller.rb` and other `eval` sites
`/home/djoulin/projects/ekylibre/app/controllers/backend/general_ledgers_controller.rb:203` calls `eval(conditions_code)` on a string built from `self.class.list_conditions`. While `list_conditions` is class-level config (not direct user input), the file also calls `params.permit!` (line 207) and feeds the result into export jobs (line 208+). Any branching that lets user values reach `list_conditions` is RCE. Same pattern in `app/models/affair.rb:188`, `app/controllers/backend/dashboards_controller.rb:35`, `app/models/intervention/recorder.rb:35` (`class_eval code`). Verify that the `code` arguments are never user-derived; otherwise this is RCE.
**Fix:** replace `class_eval`/`eval` of dynamically-built strings with explicit method calls or `define_method` on whitelisted symbols.

### H7. Mass assignment via `params.permit!` and `to_unsafe_h` in many controllers
Confirmed sites: `app/controllers/backend/general_ledgers_controller.rb:207`, `.../journals_controller.rb:138`, `.../sale_credits_controller.rb:56`, `.../companies_controller.rb:92`, plus 15+ `to_unsafe_h` usages. Combined with C1 (no CSRF), authenticated users can be CSRF'd into mass-assignment attacks (e.g. setting `administrator: true` on themselves through any nested attribute path that reaches the User model).
**Fix:** replace `permit!` with explicit allow-lists; treat `to_unsafe_h` as code smell and audit each.

### H8. `Backend::AttachmentsController#create` `constantize` on user input
`/home/djoulin/projects/ekylibre/app/controllers/backend/attachments_controller.rb:7`: `params[:subject_type].constantize.find(params[:subject_id])`. Any class in the load path can be loaded; though `.attachments.new` would fail for unrelated classes, `constantize` on attacker-controlled strings can autoload classes with side effects (DoS by autoloading large files; older Rails CVEs allow for confused-deputy issues).
**Fix:** whitelist a fixed set: `%w[Sale Purchase Entity ...].include?(params[:subject_type]) or raise`.

### H9. Admin demo loader executes `git clone` of remote repo
`/home/djoulin/projects/ekylibre/lib/tasks/admin/demo.rake:48`: `system('git', 'clone', '--depth', '1', '--quiet', demo_repo, tmp_path.to_s)`. URL is hardcoded to `https://github.com/ekylibre/demo-data.git` (line 8) — good — but the clone runs the repo's `first_run/loaders.yml` which loads exchangers that can execute arbitrary code paths inside the tenant transaction. If GitHub repo or a hijacked DNS resolves to a malicious endpoint, it is full remote code execution as the Rails user. The clone runs in the admin route, behind C2 default credentials.
**Fix:** pin a commit SHA and verify the cloned tree's signature/checksum; consider distributing demo data as an immutable bundled gem.

---

## MEDIUM

### M1. Authentication tokens compared via `Devise.secure_compare`, but user lookup is timing-leaking
`/home/djoulin/projects/ekylibre/app/controllers/api/v1/base_controller.rb:62`, v2 line 97: `User.find_by(email: ...)` returns nil for non-existent users so the secure_compare is skipped — this leaks user existence by response time and is also vulnerable to CSRF token enumeration over time.
**Fix:** always run a constant-time dummy comparison even when the user is not found.

### M2. Long-lived API tokens stored plaintext in `users.authentication_token`
`/home/djoulin/projects/ekylibre/app/models/user.rb:154-155` lazily generates an `authentication_token` and never rotates. A DB read leaks active credentials.
**Fix:** store a HMAC of the token; provide rotation/invalidation endpoint; consider switching to short-lived JWTs.

### M3. `set_locale` in `api/v2` calls `params.to_unsafe_hash`
`/home/djoulin/projects/ekylibre/app/controllers/api/v2/base_controller.rb:85`. Hardened by `valid_locale_or_nil`, but illustrates a pattern.

### M4. CORS allows `https://ekylibre.stoplight.io.*` (note dot)
`/home/djoulin/projects/ekylibre/config/application.rb:75`: `origins /https:\/\/ekylibre.stoplight.io\.*/`. The unescaped `.` matches any character and `\.*` matches zero-or-more dots — so `https://ekylibre-stoplight-io.attacker.com` will match. Combined with the broad methods list this allows credentialed cross-origin requests.
**Fix:** anchor with `\A` and `\z` and escape dots: `/\Ahttps:\/\/ekylibre\.stoplight\.io(\/.*)?\z/`.

### M5. `params.permit!` after `eval` lets any param flow into export jobs
`/home/djoulin/projects/ekylibre/app/controllers/backend/exports_controller.rb:60`: `ExportJob.perform_later(JSON(params.to_unsafe_h), current_user.id)`. Sidekiq jobs run with apartment-sidekiq middleware — fine for tenant isolation, but unbounded params can DoS Redis and may carry sensitive request data into Redis logs.
**Fix:** explicit permit list.

### M6. `restore` derives tenant name from manifest (untrusted)
`/home/djoulin/projects/ekylibre/lib/ekylibre/tenant.rb:140-150`: when `options[:tenant]` is missing, the controller-supplied filename is used; otherwise `manifest[:tenant]` from the uploaded archive is used. Admin UI passes a tenant explicitly (good), but rake-task callers may not. See C5.

### M7. `dnsmasq` HTTP admin shipped with `admin`/`admin`
`/home/djoulin/projects/ekylibre/docker/dev/docker-compose.yml:53-55`. Dev only, but illustrates the credential pattern.

### M8. `Ekylibre::Tenant.create_aggregation_views_schema!` builds SQL by string interpolation
`/home/djoulin/projects/ekylibre/lib/ekylibre/tenant.rb:248-258`: tenant names interpolated into `CREATE VIEW` and `FROM "tenant"` strings. `tenant` originates from `tenants.yml`, not a request, but defense-in-depth says `quote_column_name` is mandatory.

---

## LOW

### L1. `render inline:` with embedded ERB in `autocomplete.rb`
`/home/djoulin/projects/ekylibre/app/controllers/concerns/autocomplete.rb:31`. Static template, not user-controlled, but forces inline ERB for every controller using the concern; brittle and defeats CSP.

### L2. `render inline:` in `helps_controller.rb#index`
`/home/djoulin/projects/ekylibre/app/controllers/backend/helps_controller.rb:47`. Static template with `params[:article]` passed to the `article` helper — verify the helper escapes; if not, reflected XSS.

### L3. Apartment elevator returns `@app.call(env)` without setting any tenant for `/admin`
`/home/djoulin/projects/ekylibre/config/initializers/apartment.rb:55`. Correct intent, but if any `Admin::*Controller` method ends up touching a tenant model (e.g. `Preference.set!`, `Account.load_defaults`, `User.create!` inside `initialize_tenant`) without an explicit `Ekylibre::Tenant.switch`, it would write to the `public` schema. Verified that `tenants_controller.rb:40-43` wraps the calls in `Ekylibre::Tenant.switch(name) { initialize_tenant(name) }` — OK. But a future developer adding any code path in admin without `switch` will silently corrupt `public`.
**Fix:** add a controller-level guard that raises if `Apartment::Tenant.current == 'public'` and a model touched is not in `excluded_models`.

### L4. `Process.spawn` from admin controllers
`tenants_controller.rb:77`, `restore_controller.rb:26`, `demo_controller.rb:14`. Args are passed as separate argv (not a shell string) — safe against injection. However, all three rake tasks rely on `ENV['TENANT']`/`ENV['ARCHIVE']` which are then passed through `Ekylibre::Tenant.restore` (C5). One log file is shared per task across tenants — log contents may leak between operations.

### L5. `secret_token.rb` falls back to `nil` if `SECRET_KEY_BASE` is unset
`/home/djoulin/projects/ekylibre/config/initializers/secret_token.rb:12`: `config.secret_key_base = ENV['SECRET_KEY_BASE']`. Rails will refuse to boot in production if nil — not a vuln, but adding a meaningful failure message or `ENV.fetch('SECRET_KEY_BASE')` is clearer.

### L6. `dump_redis_key` and `restore` redis keys are global (not per-admin)
A second admin creating a dump while one is running will see the other's status.

---

## Items I could not fully verify from code alone

- Whether `Backend::OutgoingPaymentListsController#create` (H4) ever receives a user-controlled `period_reference` in production — there may be a hidden form-side whitelist; reviewing the view is needed.
- Whether `general_ledgers_controller.rb` `eval` (H6) is reachable with user-influenced `list_conditions`; class-level method needs review across all subclasses.
- Whether the `apartment-sidekiq` middleware version pinned (`~> 1.2`) handles the `apartment` 2.x edge case where a job enqueued without a tenant (e.g. from `/admin`) would default to `public` — recommend adding an explicit assertion in `ApplicationJob`.
- I did not verify every single one of the 30+ exchangers; the ZIP slip pattern is consistent across all the ones I sampled, so I treat the finding as repo-wide.

**Recommended remediation priority:** C1, C2, C3 first (single-line fixes, instant impact), then C4-C7 (admin restore is the easiest end-to-end RCE chain), then H1/H2/H4.
