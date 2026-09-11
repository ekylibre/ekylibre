# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ekylibre is a multi-tenant Farm Management Information System (FMIS) built on **Rails 6.1** / PostgreSQL+PostGIS. Each farm is an isolated PostgreSQL schema (tenant) managed by the `apartment` gem.

The `ekylibre-6.0` branch is a migration branch heading for Rails 8.1; it is **not deployed**. Deployment is deliberately deferred until that target is reached, so the production image (`docker/prod/Dockerfile`, still Ruby 2.6) lags on purpose. Dev and CI run **Ruby 2.7** — a stepping stone to 3.3, which Rails 6.0 now unblocks.

`config/application.rb` declares `config.load_defaults 6.0`, so **Zeitwerk is the autoloader**. Its acronyms, ignores and eager-load exclusions live in the same file. The framework is 6.1 but its defaults are still 6.0 — raising them is a separate step, taken one version at a time.

`config/initializers/zz-defer_boot_unloading.rb` neutralises Rails 6.1's `:warn_if_autoloaded`, which unloads every constant autoloaded during initialization. Ekylibre autoloads about seventy at boot (`20-start.rb`, plus each plugin engine's integration), and the ones brought in by `require` never come back — the app would not boot in development at all. **That file is a deferral, not a fix**: the loading has to move into `Rails.application.reloader.to_prepare` before Rails 7, where the warning becomes a hard error. Delete the file to get Rails' full diagnostic with the list of constants to treat.

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

Sidekiq 4.x with `apartment-sidekiq` middleware, which switches to the correct tenant schema before each job. Jobs that must run **without** a tenant context (e.g. admin tasks) must not go through Sidekiq — use `Process.spawn` with a rake task instead to avoid the middleware conflict.

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

`config/sidekiq.yml` sets `concurrency: 5` and `config/initializers/sidekiq.rb:18` sets `max_retries: 0` (failures are silent). Some jobs (e.g. `app/jobs/pfi_calculation_job.rb:18`) use `.each` instead of `find_each`.

### HAML partial rendering

`render partial: ..., collection:` is used in only 3 of 26 files that contain `render partial:`. Loose `render partial:` inside `.each` re-parses the template on every iteration (notably `_compare_planned_with_realised_modal.haml`, `_form.html.haml`, `change_page.js.haml`).
