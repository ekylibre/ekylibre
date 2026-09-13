# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ekylibre is a multi-tenant Farm Management Information System (FMIS) built on **Rails 8.1** / PostgreSQL+PostGIS. Each farm is an isolated PostgreSQL schema (tenant) managed by the `apartment` gem.

The **`6.0-alpha`** branch holds **Rails 8.1 with the 8.1 defaults** — the target of lot B. It is the rung branches merged into one: `ekylibre-6.0`, `ekylibre-7.0` and `ekylibre-7.1` were deleted once 8.1 landed, each being an ancestor of this one, so no commit was lost. The three workflows trigger on `main`, `5.0-beta` and `6.0-alpha` — renaming the branch without updating them would silence the CI. It is still **not deployed**: the production image (`docker/prod/Dockerfile`, still Ruby 2.6) lags on purpose, and putting 8.1 in service is its own piece of work. Dev and CI run **Ruby 3.4.10** since the 7.1 rung — `activerecord-postgis-adapter` required Ruby >= 3.0 from the series accepting ActiveRecord 7.1 onwards, so the two moves were one. The adapter is now on the 11 series.

Each rung was crossed the same way, and the criterion never changed: **the suite returns its reference measure** — 3650 tests, 17 failures, 15 errors — first with the framework bumped, then with `load_defaults` raised. A rung is not "done" because the application boots.

`config/application.rb` declares `config.load_defaults 8.1`, so **Zeitwerk is the autoloader**. Its acronyms, ignores and eager-load exclusions live in the same file.

**Seven defaults are deliberately turned back off right below that line**, each with the reason and the work its removal needs. They are not framework concessions: most of them name a real defect of the application.

| Setting | Since | Why it is off |
|---|---|---|
| `has_many_inversing`, `automatic_scope_inversing` | 6.1, 7.0 | correct semantics, but they expose a mutual `after_save` recursion between `PurchaseInvoice` and `PurchaseItem` that used to terminate only by accident of object identity |
| `active_storage.variant_processor` | 7.0 | stays on `:mini_magick`: the base image ships no libvips |
| `default_column_serializer` | 7.1 | `wice_grid` — 7.1.4 included — still declares a bare `serialize :query`, and the class raises as the gem loads, before the application can fix it. Our own fourteen declarations all carry an explicit coder |
| `raise_on_assign_to_attr_readonly` | 7.1 | 325 tests: setters and callbacks reassign `currency`, `nature`, `journal_id`, `state`, `listing_id`, `number`, `root_model` without telling creation from update. Those writes are silently lost today — a real defect, and an accounting-callback job of its own |
| `Regexp.timeout` (1 s) | 8.0 | none of our regexes comes near it (a `TracePoint` over the whole suite, which sees even rescued timeouts, found nothing), but it aggravates a suite instability without being its only condition: the unbalanced purchase test below tips over 5 runs out of 5 with the setting on, 1 out of 5 with it off. Off out of caution, not proof |
| `raise_on_missing_required_finder_order_columns` | 8.1 | fourteen `lexicon` tables have neither primary key nor unique index, so `first` returns whatever the plan gives. Giving them a key means deciding what identifies a row in each imported reference set — lot C's work |

When a new default breaks something, measure before deciding: run the suite, name the cause, and either fix the defect or turn the setting off **with its reason written down**. A rung's exit criterion is suite parity, not adopting every default.

The geometry stack is on **RGeo 3** (`rgeo ~> 3.1`, `rgeo-proj4 ~> 5.0`, `charta` branch `7.1`): the 2.x series builds on PROJ.4's legacy API, removed in PROJ 8, and its extension attaches no method under the libproj 9 the base images ship. Charta resolves SRIDs through `RGeo::CoordSys::Proj4.create(srid)` — PROJ 6 removed the `epsg` text file `SRSDatabase` used to read — and builds its projected factory around an explicit EPSG:6933 projection factory.

**One old gem is pinned and patched rather than upgraded.** `liquid-rails` 0.2.0 pins `kaminari (~> 1.1.1)`, which locks out the 1.2 series — the first to pass its paginator options as keywords; `config/initializers/10-patches.rb` reimplements `HelperMethods#paginate`. liquid-rails is not dead weight: mail bodies come from `EmailTemplate` rows rendered through the `liquid` handler it installs.

`turnout` (maintenance mode) holds `rack` below 3, which in turn caps `sidekiq` at the 7 series — 8 requires `rack >= 3.1`. Rack 3 is its own migration.

`wice_grid` is the other gem that holds a default back (see the table above). Its 7.1 series does not fix the bare `serialize`, and asks for `coffee-rails >= 5.0` on top: leaving this gem, or fixing it upstream, is a piece of work in itself. Four controllers use `initialize_grid`.

**`redirect_to` refuses other hosts** since the 7.0 defaults, and rightly so: `params[:redirect]` and the `Referer` header are client-supplied. `Backend::BaseController#local_redirect_target` filters a candidate down to an absolute path or a same-host URL; every `redirect_to params[:redirect]` in the backend goes through it, so a foreign target falls back instead of raising a 500.

**Nothing can be autoloaded during initialization.** Rails 7 removed classic autoloading and sets the main Zeitwerk loader up in the *finisher*, after every initializer has run. Two shapes are available, and the choice is not cosmetic:

- boot infrastructure — the plugin registry, `Ekylibre::Access`, `Hook`, `View` — is `require`d explicitly at the bottom of `config/application.rb` (after the Application class, which is what gives `Rails.root` a value) and **excluded from the Zeitwerk index** in the same file. It is never reloaded;
- anything touching reloadable application code goes in `Rails.application.config.to_prepare`, which runs right after boot and on every reload. `config/initializers/{charta,procedo,exchangers}.rb` and each plugin engine's integration registration follow this shape.

`add_autoload_paths_to_load_path` is false since the 7.1 defaults, and it changed **nothing** here: Rails puts `lib` on the `$LOAD_PATH` itself, through `paths["lib"].load_path?`, whatever that setting says. Only `app/models/bookkeepers` and `app/models/lexicon` leave the load path, and no `require` targets them. So the hundred-odd `require 'measure'` / `autoload :X, 'ekylibre/…'` in the tree keep resolving — do not rewrite them for this reason, it was measured.

What *is* true, and worth remembering before touching an initializer: `Rails.autoloaders.main.dirs` is **empty** during the initializers. 76 files of `lib/` are nonetheless loaded before the initialization ends, plugins included — one plugin engine's initializer reaches `Ekylibre::Navigation` — and they all get there through explicit loading.

`bin/rails zeitwerk:check` only inspects eager-load paths. `lib`, `app/models/bookkeepers` and `app/models/lexicon` are autoload-only, so the check skips them and says so — to cover them, replay `eager_load` on `Rails.autoloaders.main` collecting errors instead of stopping at the first. Note that Rails 6 calls `Zeitwerk::Loader.eager_load_all`, so a gem shipping its own non-conformant Zeitwerk loader breaks the application's boot too; `config/initializers/05-zeitwerk_gem_loaders.rb` handles the one such case.

## Development Environment

All development runs inside Docker:

```bash
# Start the full stack (Rails on :3000, PostgreSQL on :5431, Redis, Sidekiq)
docker compose -f docker/dev/docker-compose.yml up

# Shell in the app container
docker compose -f docker/dev/docker-compose.yml exec app bash

# Rails console
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rails c

# Logs
docker compose -f docker/dev/docker-compose.yml logs -f app
```

The app container runs `bundle install` automatically on startup. Plugins from `Gemfile.local` are loaded via the main `Gemfile` (no rebuild needed to add plugins).

## Running Tests

```bash
# All tests
bundle exec rake test

# Single file
bundle exec ruby -Itest test/models/activity_test.rb

# Single test method
bundle exec ruby -Itest test/models/activity_test.rb -n test_something

# With coverage
COVERAGE=true bundle exec rake test
```

Tests use **Minitest**. The test tenant is always named `test` and is switched via Apartment middleware in test env.

**The reference measure is 3650 tests, 17 failures, 15 errors, 4 skips.** Compare against it, not against zero. And beware of three known instabilities before blaming your own change:

- **the order decides.** `config.active_support.test_order = :random`, and a handful of tests depend on state a previous one left. A purchase test whose lines cannot balance (99 € excl. tax for 120 € incl. at 20 %) tips over depending on the run — 6 times out of 14 measured runs. Fixing those amounts is the real work; the `errors.messages.unbalanced` key, which used to make the failure read « Translation missing », is now in place;
- **running one controller test file alone can fail on its own.** `bank_reconciliation/letters_controller_test` raises Devise's « Could not find a valid mapping for #<User …> »: `Devise.mappings` holds a stale class reference. The same file passes inside the full suite. Do not read this as a regression — check under the previous rung's defaults before concluding;
- **the suite rewrites `db/structure.sql`** (a `pg_dump` 17 against a server 13 in the container, so the whole file churns). Check `git status` after a run and restore the file — a commit made without looking propagates that state to every newly created tenant.

## Tenant Management

```bash
# IMPORTANT: lexicon must be loaded before any first_run (local setup only)
rake lexicon:load

# Create and fully initialize a tenant
TENANT=myfarmer rake tenant:init EMAIL=admin@example.com PASSWORD=secret

# Load a first_run data folder
TENANT=myfarmer rake first_run FOLDER=demo

# Drop a tenant
TENANT=myfarmer rake tenant:drop

# Admin UI (HTTP Basic auth via ADMIN_USERNAME/ADMIN_PASSWORD env vars)
http://localhost:3000/admin
```

The `config/tenants.yml` file lists active tenants per Rails environment. `Ekylibre::Tenant` wraps the Apartment gem — use it, not Apartment directly.

## Key Architectural Patterns

### Multi-tenancy
Apartment uses PostgreSQL schemas. The middleware stack selects the tenant via subdomain (prod), `HTTP_X_TENANT` header, or `TENANT` env var (dev). Routes under `/admin` bypass the elevator — they run without any tenant context.

### Routing
Three namespaces: `backend` (authenticated ERP), `api/v1` and `api/v2` (token auth), `admin` (HTTP Basic, tenant management). The root redirects to `backend/dashboards#home` when authenticated or to Devise sign-in otherwise.

### Models
- STI is used extensively: `ProductNature`, `ProductNatureVariant`, `ProductNatureCategory` each have type columns mapping to subclasses under `VariantTypes::`, `Variants::`, `VariantCategories::` namespaces.
- `app/models/lexicon/` contains `Master*` and `Registered*` read-only reference models (backed by the shared `lexicon` PostgreSQL schema, never modified at runtime).
- `app/models/bookkeepers/` contains accounting journal entry writers (called from model callbacks via `Ekylibre::Record::Bookkeep`).
- `lib/ekylibre/record/` contains model mixins: `Autosave`, `Bookkeep`, `HasShape`, `Sums`, etc.

**Deprecating an application API** goes through `Ekylibre.deprecator` (`lib/ekylibre/deprecator.rb`), not `ActiveSupport::Deprecation.warn` — the class-level method is gone in 7.2. The deprecator is registered in `app.deprecators` by an initializer placed `before: :load_environment_config`, like the ActiveSupport railtie's own, so the per-environment behaviour applies to it.

**`alias_attribute` only aliases attributes** since 7.2. For an association, a `store_accessor`, or a method, use `alias_method` — and generate plain methods instead when the target may be defined *after* the alias (that is why `acts_as_affairable` writes `deal_third`, `deal_amount` and `deal_taxes` out in full: `DebtTransfer` delegates `third` a hundred lines below its call).

**Qualify columns in a `where` that precedes a join and feeds `update_all`.** Rails 8.1 compiles that into `UPDATE … FROM` instead of a subquery on ids, so an unqualified column name becomes ambiguous for PostgreSQL — it bit `TaxDeclaration#set_entry_items_tax_modes` (`printed_on`) and the bank-reconciliation letters controller (`letter`). Likewise, condition values are bound parameters now: `usages ~ E?` and `delivery_id IS ?` used to be interpolated and no longer work (`E$1`, `IS $2`).

### Exchangers
`app/exchangers/` contains data import/export adapters for 30+ agricultural software formats (Isagri, Telepac, Vinifera, etc.). Each exchanger subclasses `ActiveExchanger::Base` and implements `import` or `export`.

### Onoma
The `onoma` gem provides the agricultural nomenclature (crops, units, variants, countries, currencies). Look up items with `Onoma::ProductNatureVariant.find(:wheat)`. Many model attributes `refers_to` Onoma items.

### Lexicon
The `lexicon` PostgreSQL schema is shared across all tenants (persistent schema). It contains master reference data (variants, production systems, phytosanitary products, etc.) loaded by `rake lexicon:load`.

### FirstRun
`lib/ekylibre/first_run/` handles tenant initialization from data folders in `db/first_runs/<folder>/`. The `loaders.yml` defines which exchangers to run in order. `rake first_run FOLDER=demo TENANT=name` runs them all in a single transaction (unless `HARD=true`).

### Plugins
Plugins are Rails engines loaded via `Gemfile.local` or `Gemfile.plugins`. They follow the same conventions as the main app. The `TENANT` env var and SSH keys are available in the dev container.

## Database

```bash
# Schema format is SQL (not Ruby)
# Never edit db/structure.sql manually — it's generated by migrations

# Run migrations on all tenants
rake db:migrate  # runs on public schema
rake tenant:migrate  # runs on all tenant schemas

# The lexicon schema is separate and loaded via:
rake lexicon:load
```

### Regenerating db/structure.sql

`db/structure.sql` is `pg_dump` of `ekylibre_development`. It captures the `public`, `postgis` and `lexicon` schemas (via `schema_search_path` in `config/database.yml`). Apartment uses it to clone new tenant schemas (`config.use_sql = true`), so any dirty state in it propagates to every newly created tenant.

Canonical regen procedure (no tenants in dev — check first with `Ekylibre::Tenant.list`):

```bash
# 1. Drop only `public` (preserve postgis + lexicon)
docker compose -f docker/dev/docker-compose.yml exec db env PGPASSWORD=ekylibre \
  psql -h localhost -U ekylibre -d ekylibre_development -v ON_ERROR_STOP=1 \
  -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;"

# 2. Recreate public from migrations
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake db:migrate

# 3. Dump
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake db:structure:dump
```

The `CASCADE` drop removes anything that was added to `public` outside migrations — historically `hstore`, `pg_cron`, `gist_geometry_ops`, legacy `st_asbinary(text)`/`st_astext(bytea)` compat functions. Re-add them only if app code needs them (none does today; `postgis` schema provides `st_astext`/`st_asbinary` and is in `schema_search_path`).

### Warning: postgis CASCADE corruption

The `kartoza/postgis:13` image re-runs `docker/db/init.sql` on every restart. Without the `IF EXISTS` guard at lines 7-16 of that file, the script silently executes `DROP EXTENSION postgis CASCADE` — which drops **every geometry/geography column** in every schema (`shape`, `geolocation`, `working_zone`, `support_shape`, etc.) without erroring. Symptom: `PG::UndefinedColumn` on geometry columns at runtime, even though migrations and code still reference them. If you ever see this, regen `structure.sql` via the procedure above (a single `pg_dump` after a corruption event will commit the bad state — see commit `3815900722` which lost 80 geometry columns this way).

## Views

Templates use **HAML**. The backend layout (`app/views/layouts/backend.html.haml`) uses a beehive/cell dashboard system. Dialog/popover layouts exist for modal content. The admin interface uses a plain `app/views/layouts/admin.html.haml` with no tenant dependencies.

## Translations

The app supports `eng` (default, reference) and `fra` — declared in `config/initializers/i18n.rb`. Other directories under `config/locales/` (`ita`, `por`, `cmn`, `jpn`, `arb`, `deu`, `spa`) are dormant archives, not loaded at runtime.

### Update & sort

```bash
# Regenerate all locale files (sort keys, mark missing entries with leading "# ")
docker compose -f docker/dev/docker-compose.yml exec app bundle exec rake clean:locales

# Dry-run: report completion % without writing
DRY_RUN=true rake clean:locales
```

The task fails if any plugin is registered (`Cannot clean locales if plugins are activated`) — disable `Gemfile.local`/`Gemfile.plugins` first.

### Missing entries convention

`Clean::Support.missing_prompt` is `"# "`. Untranslated entries are written as commented lines: `# key: "Humanized default"`. Reviewers can search for `^\s*#\s+\S` to find untranslated keys.

Orphan markers: `#~` (auto-derivable from another scope), `#?` (key not found in source code anymore), `#<` (parent reference inside nomenclatures).

### Completion helpers

```bash
# Decomment auto-humanized missing entries (use after rake clean:locales)
bin/decomment_locales.rb [locale] [file]

# Machine-translate fra missing entries via DeepL (eng→fra)
DEEPL_API_KEY=xxx bin/translate_locales_deepl.rb [file_glob]
DRY_RUN=true bin/translate_locales_deepl.rb     # count without API calls
DEEPL_API_PRO=true bin/translate_locales_deepl.rb # use api.deepl.com
```

The DeepL script protects `%{...}` and `{{...}}` placeholders, escapes XML chars, retries on HTTP 429, and only touches single-line entries (skips `|` block scalars).

### Known limitations

- `Clean::Support.hash_diff` accumulates `#?` markers on orphan multi-line block entries (only impacts `fra/mailers.yml` today — non-breaking).
- Multi-line block entries (`# key: |`) are skipped by `decomment_locales.rb` and `translate_locales_deepl.rb` — handle manually if needed.
- Some YAML keys (with spaces or dots, e.g. enum values `1 week`, `liquid_10_25_d1.4`) fall outside the decomment regex; they remain commented as humanized defaults.

## Background Jobs

**In test, `config.active_job.queue_adapter = :test`** (`config/environments/test.rb`), and that line is load-bearing. Until Rails 7.1, `ActiveJob::TestHelper` swapped the adapter in at the start of every test; since 7.2 it only does so when the application declares none — and `config/application.rb` declares `:sidekiq` for every environment. Without the test-env line, jobs really go to Redis during the suite and `perform_enqueued_jobs` executes nothing. The measurable symptom before it was put back: 2919 queued and 505 dead jobs piled up in the development Redis, and four accounting-export tests failed.

Note also that the `sidekiq` dev container needs rebuilding whenever the base image changes (`docker compose -f docker/dev/docker-compose.yml build sidekiq`): it shares `app`'s Dockerfile, but a stale image keeps running the old Ruby and the container restart-loops on `Your Ruby version is 2.6.10, but your Gemfile specified >= 3.4.0`.

Sidekiq 7.3 with `apartment-sidekiq` middleware, which switches to the correct tenant schema before each job. Jobs that must run **without** a tenant context (e.g. admin tasks) must not go through Sidekiq — use `Process.spawn` with a rake task instead to avoid the middleware conflict.

Sidekiq 7 talks to Redis through `redis-client`, not the `redis` gem: `Sidekiq.redis` yields a `Sidekiq::RedisClientAdapter::CompatClient`, which forwards most commands but warns on the ones Redis deprecated (`hmset` among them — use `hset`, which takes several field/value pairs). The `redis` gem is still declared, for Action Cable alone. Key prefixing through `redis-namespace` is gone with sidekiq 7; `REDIS_NAMESPACE` was set in no environment, so no key moved.

The retry count is a configuration entry (`config[:max_retries] = 0` in `config/initializers/sidekiq.rb`), no longer a middleware to insert. sidekiq-cron 2 reads `config/schedule.yml` by itself when the server boots — do not load it from an initializer, where Redis may not be reachable yet.

## Performance Hotspots (known issues)

Static analysis surfaced the following recurring sources of slowness. **No APM is configured in production** (`elastic-apm` is commented out in `Gemfile`) — activate Scout APM / Skylight and Postgres `log_min_duration_statement = 200ms` before optimizing further. `bullet` / `rack-mini-profiler` / `ruby-prof` are present in `:development` only.

### Heavy callback cascades on writes

- **`Intervention#save`** (`app/models/intervention.rb:381-489`) triggers 30-100+ SQL queries per save: `targets.find_each` with nested `find_or_create_by`, `participations.update_all` × 2, `update_costing`, `add_activity_production_to_output`, `reconcile_receptions`, `WorkerTimeIndicator.refresh` (REFRESH MATERIALIZED VIEW), `compute_pfi_async`, then bookkeep iterating on inputs+outputs. The `change_state` controller loops compounds the cost.
- **`Ekylibre::Record::Sums`** (`lib/ekylibre/record/sums.rb:38-58`, used by `sale_item`, `purchase_item`, `contract_item`, `sale_contract_item`, `gap_item`, `fixed_asset_depreciation`) reloads parent and runs `children.find_each` on every item save → O(N²) on imports.
- **`Ekylibre::Record::Autosave`** (`lib/ekylibre/record/autosave.rb:26-39`) does `assoc.reload.save` cascades that re-trigger the full callback chain (Sums + Bookkeep included).
- **`Ekylibre::Record::Bookkeep`** (`lib/ekylibre/record/bookkeep.rb:40-58`, ~30 models) queries `Preference[:bookkeep_automatically]` on every save and emits a separate `update_all(accounted_at:)` UPDATE.

When working on these models, prefer `Ekylibre::Record.suppress_callbacks` for bulk operations and recompute totals once at the end.

### N+1 in backend controllers/views

Only **1 occurrence** of `includes`/`preload`/`eager_load` across the 7 hottest controllers (`interventions_controller`, `products_controller`, `activities_controller`, `activity_productions_controller`, `sales_controller`, `purchase_invoices_controller`, `journal_entries_controller`). `app/views/backend/interventions/show.html.haml:100-113` generates ~5N queries per `product_parameter` (accessing `.product`, `.variant`, `.conditioning_unit`, `.product.france_maaid`, `RegisteredPhytosanitaryProduct.where(...)`).

`Intervention#total_cost` and `#cost(role)` (`app/models/intervention.rb:783-822`) are recomputed 6-10× per render of the show page — no memoization.

### Lexicon / Onoma lookups not memoized

183 calls to `Onoma::*` in `app/models`, only 2 are memoized. `Master*` models (`worker_contract.rb:177-180`, `catalog_item.rb:207-208`, `product_nature.rb:405,442`) re-issue the same SQL query in tight loops. The `lexicon` schema is read-only at runtime — safe to memoize per-process or via `Rails.cache.fetch`.

### Exchangers without batching

112 files in `app/exchangers/`, **0 occurrences** of `insert_all`/`upsert_all`/`bulk_insert`, only 1 explicit `transaction do`. `entities_exchanger.rb:95-115` does 5 `create!` per entity in a loop. Imports run all callbacks (Bookkeep, Sums, Autosave) per row. Wrap with `ApplicationRecord.transaction` + `Ekylibre::Record.suppress_callbacks` and prefer `insert_all` when callbacks are not critical.

### Unindexable SQL filters

`app/controllers/backend/interventions_controller.rb:100,111,116` filters with `EXTRACT(YEAR FROM started_at) = ?` — full scan. Use `started_at BETWEEN ... AND ...` or add a functional index.

### Sidekiq config

`config/sidekiq.yml` sets `concurrency: 5` and `config/initializers/sidekiq.rb` sets `max_retries: 0` (failures are silent). Some jobs (e.g. `app/jobs/pfi_calculation_job.rb:18`) use `.each` instead of `find_each`.

### HAML partial rendering

`render partial: ..., collection:` is used in only 3 of 26 files that contain `render partial:`. Loose `render partial:` inside `.each` re-parses the template on every iteration (notably `_compare_planned_with_realised_modal.haml`, `_form.html.haml`, `change_page.js.haml`).
