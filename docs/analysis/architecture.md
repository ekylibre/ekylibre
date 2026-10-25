# Ekylibre 5.0-beta — Architecture Review

**Date:** 2026-05-07
**Scope verified by reading:** `Gemfile`, `Gemfile.local`, `Gemfile.lock`, `config/application.rb`, `config/routes.rb` (1614 lines), `config/initializers/apartment.rb`, `lib/ekylibre/plugin.rb`, `lib/ekylibre/tenant.rb`, `lib/active_exchanger/base.rb`, sample exchangers under `app/exchangers/telepac/`, `app/exchangers/isagri/`, `app/models/product_nature_variant.rb`, all directories under `app/{services,concepts,interactors,queries,decorators,integrations}`, and the `main..5.0-beta` diff.

## Strategic risks

### Rails 5.2.8.1 / Ruby 2.6.6 — both EOL ~4 years, gem ecosystem rotting around them
`Gemfile:15,19` pins `ruby '>= 2.6.6, < 3.0.0'` and `rails '5.2.8.1'`. Several Gemfile dependencies are themselves frozen at versions that block any near-term upgrade: `state_machine '~> 1.2'` (unmaintained, blocks Ruby 3 — `state_machine` was famously incompatible past 2.x), `paperclip '~> 5.3'` (deprecated since 2018, replaced by ActiveStorage), `paranoia`, `sprockets < 4.0`, `webpacker '~> 4.x'` (also EOL). `Gemfile:67 therubyracer`, `Gemfile:152-158 beardley` (Java/JRB-based Jasper) and `Gemfile:34 rjb '1.6.2'` add JRuby/JNI fragility. The path to Rails 6.1 → 7.x is not single-step: each of these gems is a separate replacement project.
**Recommendation:** write down a Rails-6.1 prerequisite list; the long poles are paperclip→ActiveStorage, state_machine→aasm/state_machines, sprockets/webpacker→jsbundling+propshaft, and the Jasper/beardley reporting stack.

### Apartment 2.2.1 — the gem is unmaintained and the schema-per-tenant pattern caps you
`Gemfile:45` pins `apartment '~> 2.2.1'` (last release Sept 2019). The codebase already wraps Apartment behind `Ekylibre::Tenant` (`lib/ekylibre/tenant.rb`) and only 5 files outside that wrapper touch Apartment directly (`lib/fixturing.rb`, jobs, the new admin controller). That wrapper is the lever, but it's incomplete — `config/initializers/apartment.rb:38-92` monkey-patches Apartment internals (`Elevators::Header`, `SecuredSubdomain`, `PostgresqlSchemaAdapter`, blacklisting `\restrict`/`\unrestrict` from `pg_dump 17` output), so the abstraction is leaky in exactly the place a replacement would need to slot in. Schema-per-tenant in PostgreSQL hits known pain at low-thousands of tenants: `pg_catalog` bloat, `pg_dump`/`pg_restore` time, planner overhead. There is **no documented migration story** in `CLAUDE.md` or `docs/`.
**Recommendation:** decide explicitly between (a) forking apartment, (b) `ros-apartment` (community fork, still 2.x-style), or (c) a row-level `tenant_id` migration over 2-3 years. Option (c) is the only one that actually removes the scaling ceiling.

### Sidekiq 4.x with `apartment-sidekiq` middleware — bottlenecked on Apartment
`Gemfile:102` `sidekiq '~> 4.0'`, locked at `4.2.10`. Sidekiq 7 is current; 4.x missed every reliability/perf improvement of 5/6/7 and security advisories accumulate. Worse, `apartment-sidekiq '~> 1.2'` is itself version-locked to apartment 2.x; you cannot upgrade Sidekiq independently of solving the multi-tenancy story above. The CLAUDE.md note that admin jobs must use `Process.spawn` rather than Sidekiq (visible in `app/controllers/admin/demo_controller.rb`, `restore_controller.rb`) is a workaround for this coupling — it splits the background job model in two.

### Plugin loading model is a private DSL on top of monkey-patched autoload
`lib/ekylibre/plugin.rb` (388 lines) is a homegrown plugin loader: each plugin has a `Plugfile` that's `instance_eval`'d (`plugin.rb:170`), with DSL methods `add_routes`, `extend_navigation`, `subscribe`, `add_toolbar_addon`, `register_manure_management_method`, `redirect_after_login`. It does its own `ActiveSupport::Dependencies.autoload_paths +=` (`plugin.rb:218-231`), `prepend_view_path`, asset path mirroring, and SCSS theme generation (`plugin.rb:222-258`). Rails 6 dropped classic autoload for Zeitwerk; this loader will need a full rewrite for any Rails upgrade. The 16 plugins in `Gemfile.local` (banking, qonto, baqio, ednotif, samsys, traccar, ekyviti, weenat, economic, natuition, idea, planning, duke, hajimari) all depend on this contract.
**Recommendation:** before Rails 6, freeze the plugin contract in a real spec doc and convert to Rails Engines with `config.eager_load_paths`.

## Structural debt

### Boundary directories under `app/` are organic accretion, no documented rule of placement
Six "domain" directories coexist: `app/concepts/` (5 files, e.g. `FinancialYearExchangeImport`, `SequenceManager`), `app/services/` (~106 files, biggest bucket, mixes flat services and namespaced `Accountancy::`, `Interventions::`, `Printers::`), `app/interactors/` (~11, e.g. `Interventions::BuildInterventionInteractor`), `app/queries/` (5 files, `Products::SearchVariantByExpressionQuery`), `app/decorators/` (Draper, ~25 files), `app/integrations/` (only 2: weather APIs). Reading samples, the convention is invisible: `FinancialYearExchangeImport` (concept) and `BuildInterventionInteractor` (interactor) and `AccountancyClassifierService` (service) all do the same thing — wrap a transaction, return a result object, expose a single `run`/`call`. The split is historical — Trailblazer/Interactor/Draper/etc. were each adopted in different eras.
**Recommendation:** pick one (interactors for write-side commands, queries for read, services for stateless helpers, decorators for view-only) and move the rest in a tracked deprecation. Don't refactor everything — just stop adding to `concepts/` and `interactors/` and document where new code goes.

### STI on `ProductNature*` is a moderate, not a runaway, problem
Counted: 7 files in `app/models/variant_categories/`, 7 in `app/models/variant_types/`, 15 in `app/models/variants/` (8 top-level + 4 articles + 3 equipments). `app/models/product_nature_variant.rb:84-86` enumerates allowed types in code with `enumerize :type, in: %w[Animal Article ...].map { |t| "Variants::#{t}Variant" } + ...`. STI on three coupled tables is fine at this depth — the deeper sub-namespace (`Variants::Articles::FertilizerArticle`) is where it gets fragile because `enumerize` becomes a hand-curated list that drifts from filesystem. The bigger structural smell is that `ProductNature`, `ProductNatureVariant`, `ProductNatureCategory` all share the `type` column and must be kept in sync.
**Recommendation:** keep STI at depth 1, push depth-2 distinctions (FarmProduct vs Fertilizer vs PlantMedicine) onto a polymorphic `behavior` association or an ENUM-typed column; the variants' subdirs are already mixing both shapes.

### Onoma + Lexicon split is real but legitimate; the unclear part is which is canonical
`Gemfile:107 onoma '~> 0.9.8'` ships static YAML nomenclature (varieties, units, families) inside the Ruby gem and is queried like `Onoma::Unit['liter']`. The `lexicon` PostgreSQL schema (`config/initializers/apartment.rb:28 persistent_schemas = %w[postgis lexicon]`) holds the heavier reference data — `MasterVariant`, `MasterProduction`, `RegisteredPhytosanitaryProduct` (45+ models in `app/models/lexicon/`). They overlap: `app/models/lexicon/registered_phytosanitary_product.rb:147` does `Onoma::Unit['liter']`, and `app/models/lexicon/technical_sequence.rb:42-46` resolves activity families through Onoma. The dependency direction (lexicon → onoma) is fine, but the rule for "what goes in onoma vs what goes in the lexicon schema" is not written down.
**Recommendation:** document one rule — e.g. "small enumerable/closed sets in Onoma; relational/large/regulator-sourced data in lexicon" — and audit which gem-side enums are actually open-set (variety lists certainly are).

### Exchanger versioning by directory copy — Telepac is duplicating one-line classes
`app/exchangers/telepac/` has v2015 through v2025 (11 versions). Each `cap_statements_exchanger.rb` is **11 lines** and the 2024→2025 diff is a single `campaign 2024 → campaign 2025` change; all real logic lives in `telepac/exchanger_mixin.rb` (400 lines). This is fine — it's the version-pinned-but-trivial approach. The smell is in the 112-file count overall: `lib/active_exchanger/base.rb:8 VENDORS = %i[acom agro_systemes agrigest agroedi ... ]` is a hardcoded enumeration, and several have only 1-2 files. The `category`/`vendor` taxonomy is a class-level DSL the registry walks; that part is well-built.
**Recommendation:** declare the 2-tier (vendor, year) versioning explicit and stop adding flat exchangers under one-vendor directories.

### Routes: 1614 lines, 230 `resources` declarations, all 4 namespaces in one file
`config/routes.rb` is large but not unmanageable — well structured into shared `concern`s (`:list`, `:unroll`, `:picture`, `:products`, `:affairs`) at the top, then sequential `namespace :admin / api/v1 / api/v2 / iot / backend` blocks. The `backend` namespace alone runs from line 160 to ~1593. The new `admin` namespace (lines 6-19) is small and clean.
**Recommendation:** extract `backend.rb`, `api_v1.rb`, `api_v2.rb` via `Rails.application.routes.draw_from_path` — single-file routing slows test boot and review.

## Strengths

- **`Ekylibre::Tenant` wrapper exists and is widely used** — `lib/ekylibre/tenant.rb` correctly hides Apartment behind a domain-level API. Only 5 files outside it touch Apartment directly. This is the single biggest enabler for the eventual apartment replacement.

- **Persistent `lexicon` schema is genuinely good multi-tenancy** — `config/initializers/apartment.rb:28` makes lexicon shared across all tenants. This both saves disk and makes regulatory-data updates atomic. Few schema-per-tenant systems get this right.

- **Admin/tenant boundary is cleanly drawn in 5.0-beta** — diff `main..5.0-beta` shows `app/controllers/admin/base_controller.rb` (HTTP Basic, no Devise), `Admin::*Controller` all extend it, and `config/initializers/apartment.rb:55-56` plus routes-level `request.path.start_with?('/admin')` shortcut prevents tenant elevation. Long-running ops use `Process.spawn` to a rake task (`admin/demo_controller.rb:14-22`, `restore_controller.rb:24-32`) — correct given Sidekiq+Apartment middleware constraints. The boundary is well-drawn for what it is.

- **Telepac exchanger architecture (mixin + thin year-versioned class)** is the right shape — `app/exchangers/telepac/exchanger_mixin.rb` holds logic, `vYYYY/cap_statements_exchanger.rb` only declares the campaign year. Other vendors should copy this.

- **ActiveExchanger registry, category/vendor DSL, deprecation marker** — `lib/active_exchanger/base.rb` is a small, well-defined plugin point. `Result` objects, `Supervisor`, transaction-wrapped run with rollback are all good. This is the kind of internal framework that survives Rails upgrades.

- **Decorators (Draper) used consistently** — 25 decorators in `app/decorators/`, all parallel to model names. This is one bucket where the convention is uniform.

## Decisions to make

1. **Multi-tenancy: replace Apartment, or stay on a fork?** — `ros-apartment` is a drop-in fork keeping the schema model; row-level (`acts_as_tenant` or hand-rolled `tenant_id`) is a years-long migration but removes the scaling ceiling forever. Decide before any Sidekiq or Rails upgrade — both are blocked by this. Open question: how many tenants today, projected in 3 years?

2. **Reporting stack** — `Gemfile:152-158 beardley` (Jasper via JRB) is documented as deprecated in `Gemfile:147`. Keep, replace with `prawn` (already in Gemfile), or move to a service? This is on the Rails-6 critical path because rjb compatibility with Ruby 3 is not guaranteed.

3. **Plugin contract: freeze or rewrite?** — 16 ekylibre/* plugins on GitHub now (`Gemfile.local`). Either codify the current `Plugfile` DSL as the stable contract for v5.0 (and handle Zeitwerk migration inside `lib/ekylibre/plugin.rb`), or convert to standard Rails Engines. The first is faster, the second is what the ecosystem expects.

4. **Boundary convention** — pick interactors+queries+services or concepts+services. Document. The four-bucket status quo is a teaching tax on every new contributor.

5. **Sidekiq upgrade trigger** — Sidekiq 4 → 7 is gated on apartment-sidekiq. Either invest in a `Sidekiq::Middleware` replacement that calls `Ekylibre::Tenant.switch` directly (small, likely <100 lines), then upgrade Sidekiq independently — or wait until apartment is replaced. The first is the better hedge.

6. **`type` column / STI ceiling on ProductNatureVariant** — depth-2 (`Variants::Articles::*`, `Variants::Equipments::*`) is fragile because the allowed types are duplicated between `enumerize` and the filesystem. Convert depth-2 to a separate column or behavior table before adding more variants.

---

## Files referenced

- `Gemfile`, `Gemfile.local`, `Gemfile.lock`
- `config/application.rb`, `config/routes.rb`, `config/initializers/apartment.rb`, `config/initializers/sidekiq.rb`
- `lib/ekylibre/plugin.rb`, `lib/ekylibre/tenant.rb`, `lib/active_exchanger/base.rb`, `lib/fixturing.rb`
- `app/models/product_nature_variant.rb`, `app/models/variants/`, `app/models/lexicon/`
- `app/exchangers/telepac/exchanger_mixin.rb`, `app/exchangers/telepac/v2024/cap_statements_exchanger.rb`, `app/exchangers/isagri/`
- `app/{concepts,services,interactors,queries,decorators,integrations}/`
- `app/controllers/admin/`, `app/views/admin/`

**Could not verify from code alone:** actual tenant count today, real `pg_dump` times, whether the plugins compile against current `Plugfile` DSL after recent loader patches. Those need empirical data from production.
