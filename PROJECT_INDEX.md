# Project Index: Ekylibre

Generated: 2026-05-31 (branch `5.0-beta`)

Multi-tenant Farm Management Information System (FMIS). Rails 5.2 / Ruby 2.6 / PostgreSQL+PostGIS. Each farm is an isolated PostgreSQL schema (tenant) managed by the `apartment` gem.

> See `CLAUDE.md` for development workflow, tenant management, perf hotspots, and translation tooling. This index is the structural map.

## Project Structure

```
ekylibre/
├── app/
│   ├── assets/           Sprockets pipeline (CSS/JS legacy)
│   ├── channels/         ActionCable
│   ├── concepts/         Trailblazer-style concepts
│   ├── controllers/      407 files; namespaces: admin, api/{v1,v2}, backend, authentication, iot, public
│   ├── decorators/       Draper decorators
│   ├── exchangers/       112 import/export adapters (Isagri, Telepac, Vinifera, …)
│   ├── helpers/
│   ├── inputs/           SimpleForm custom inputs
│   ├── integrations/     ActionIntegration adapters (3rd-party services)
│   ├── interactors/
│   ├── javascript/       Webpacker packs (components, duke, lib, packs, pages, services)
│   ├── jobs/             Sidekiq jobs (accountancy, exports, daily/hourly triggers, PFI, …)
│   ├── mailers/
│   ├── models/           287 root models (+ STI subclasses in variants/, variant_types/,
│   │                     variant_categories/, intervention/, lexicon/, accountancy/, bookkeepers/)
│   ├── queries/
│   ├── serializers/
│   ├── services/         Domain services (accountancy, interventions, fixed_asset, financial_year, …)
│   ├── themes/           UI themes
│   ├── validators/
│   └── views/            888 HAML templates (layouts: backend, admin, dialog, popover)
├── bin/                  decomment_locales.rb, translate_locales_deepl.rb, …
├── config/
│   ├── application.rb · routes.rb · database.yml · tenants.yml
│   ├── accountancy/      French PCG accounting docs
│   ├── environments/     development.rb · production.rb · test.rb
│   ├── initializers/     apartment, devise, onoma, procedo, beardley, beehive, sidekiq, …
│   └── locales/          eng (ref), fra (active); ita/por/cmn/jpn/arb/deu/spa dormant
├── db/
│   ├── migrate/          703 migrations
│   ├── first_runs/       Tenant seed data folders (demo, …) — loaded via loaders.yml
│   ├── lexicon/          Shared read-only PostgreSQL schema seed
│   ├── nomenclatures/    Onoma definitions
│   ├── views/            Scenic SQL views (incl. materialized)
│   ├── structure.sql     30K lines — generated, never hand-edit
│   ├── models.yml · tables.yml
├── docker/dev/           docker-compose.yml — Rails:3000, PG:5431, Redis, Sidekiq
├── docs/                 analysis, api, development/algo, guides, installation, planning
├── lib/
│   ├── ekylibre/         Core lib: record/ (Autosave, Bookkeep, Sums, HasShape), first_run/,
│   │                     plugin/, navigation/, schema/, support/, testing/, view/, access/,
│   │                     corporate_identity/, document_management/, export/open_document/, job/
│   ├── procedo/          Intervention DSL (formula language; see CLAUDE.md memories)
│   ├── active_exchanger/ Exchanger base framework
│   ├── clean/            rake clean:locales support (Clean::Support)
│   ├── calculus/ · abaci/ · aggeratio/   Numeric/agronomic helpers
│   ├── action_integration/  · active_guide/ · active_sensor/
│   ├── map/ · pesticide/ · open_weather_map/ · svf/ · tele/
│   ├── omniauth/ · userstamp/ · working_set/ · state_machine/
│   ├── enumerize/ · generators/ · routing/ · templates/ · tasks/ · test/
├── plugins/              Plugin directory (see Gemfile.local / Gemfile.plugins)
├── test/                 806 *_test.rb (Minitest): models, controllers, services, exchangers,
│                         jobs, mailers, decorators, interactors, validators, concepts,
│                         factories (FactoryBot), fixtures, cassettes (VCR), ci, helpers
└── public/ · packaging/ · private/ · log/ · node_modules/
```

## Entry Points

- **HTTP**: `config.ru` → Rails app; root redirects to `backend/dashboards#home` (authed) or Devise sign-in
- **Routing namespaces** (`config/routes.rb`):
  - `admin/*` — HTTP Basic, bypasses Apartment elevator (no tenant)
  - `backend/*` — Devise-authenticated ERP (main UI)
  - `api/v1/*`, `api/v2/*` — token auth
  - `authentication/*`, `iot/*`, `public/*`
- **Background**: Sidekiq via `apartment-sidekiq` middleware (auto-switches tenant per job); `config/sidekiq.yml` concurrency 5, max_retries 0
- **CLI**: rake tasks under `lib/tasks/` (`lexicon:load`, `tenant:init`, `tenant:migrate`, `first_run`, `clean:locales`)

## Key Architectural Patterns

- **Multi-tenancy** — `apartment` gem, PostgreSQL schemas. Tenant resolved by subdomain (prod), `HTTP_X_TENANT` header, or `TENANT` env (dev). Use `Ekylibre::Tenant`, not Apartment directly. `lexicon` schema is shared (read-only at runtime).
- **STI** — `ProductNature` / `ProductNatureVariant` / `ProductNatureCategory` subclass into `VariantTypes::*`, `Variants::*`, `VariantCategories::*`.
- **Bookkeeping** — `app/models/bookkeepers/` writes journal entries via `Ekylibre::Record::Bookkeep` mixin from model callbacks (~30 models).
- **Mixins** (`lib/ekylibre/record/`) — `Autosave`, `Bookkeep`, `HasShape`, `Sums`, `acts/`. Use `Ekylibre::Record.suppress_callbacks` for bulk ops (see CLAUDE.md perf section).
- **Exchangers** — Each subclasses `ActiveExchanger::Base`; called by `lib/ekylibre/first_run/` loaders for tenant seeding.
- **Onoma** — Agricultural nomenclature gem; many model attrs `refers_to` Onoma items.
- **Procedo** — Intervention parameter/formula DSL (`lib/procedo/`). Memory: formula nodes use `Procedo::Formula::Nodes::*`, not `Language::*`.
- **Views** — HAML + beehive/cell dashboard layout (`app/views/layouts/backend.html.haml`).

## Configuration

- `Gemfile` — 121 gems (Rails 5.2.8.1, PostGIS adapter, apartment, sidekiq 4.x, devise, haml 5.2, charta, onoma, procedo, jasper/rjb for reports, scenic)
- `Gemfile.local` / `Gemfile.plugins` — plugin loading (no rebuild needed)
- `package.json` — Webpacker 4.x; Vue 2 + Leaflet 1.2 + Highcharts + chart.js
- `.lexicon-version` = `6.0.1-test`
- `config/tenants.yml` — per-env tenant list
- `config/initializers/` — `apartment.rb`, `procedo.rb`, `onoma.rb`, `beardley.rb` (Jasper), `beehive.rb` (dashboards), `devise.rb`

## Tests

- **Framework**: Minitest. Tenant name is always `test`, switched via Apartment middleware.
- **Coverage**: 806 `*_test.rb` files across models, controllers, services, exchangers, jobs, mailers, decorators, interactors, validators, concepts, helpers, lib, javascripts.
- **Run**: `bundle exec rake test` (full) · `bundle exec ruby -Itest <file> -n <test>` (single) · `COVERAGE=true rake test`
- **Fixtures**: `test/fixtures/` + FactoryBot in `test/factories/`. VCR cassettes in `test/cassettes/`.

## Translations

- Active locales: `eng` (reference), `fra`. Others dormant.
- `rake clean:locales` regenerates/sorts; missing keys written commented (`# key: "Humanized"`).
- Tooling: `bin/decomment_locales.rb`, `bin/translate_locales_deepl.rb` (DeepL eng→fra).

## Performance Hotspots (from CLAUDE.md)

- **Write cascades**: `Intervention#save` (30–100+ queries), `Sums` (O(N²) on imports), `Autosave` reload+save, `Bookkeep` per-save preference lookup.
- **N+1 in backend**: only 1 `includes` across 7 hottest controllers; `interventions/show.html.haml:100-113` ≈5N queries/parameter; `Intervention#total_cost` not memoized (6–10×/render).
- **Onoma/lexicon lookups**: 183 call sites, only 2 memoized.
- **Exchangers**: 0 `insert_all`/`upsert_all` across 112 files; only 1 explicit transaction.
- **No APM** in production (`elastic-apm` commented out).

## Quick Start

```bash
# Boot stack
docker compose -f docker/dev/docker-compose.yml up

# One-time lexicon load
rake lexicon:load

# Create a tenant
TENANT=myfarmer rake tenant:init EMAIL=admin@example.com PASSWORD=secret

# Tests
bundle exec rake test
```

App on http://localhost:3000 · Admin UI at `/admin` (HTTP Basic via `ADMIN_USERNAME`/`ADMIN_PASSWORD`).
