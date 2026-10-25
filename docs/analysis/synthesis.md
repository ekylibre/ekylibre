# Ekylibre 5.0-beta — Full Project Analysis (synthesis)

**Date:** 2026-05-07
Four specialist agents (security, performance, architecture, quality) audited the codebase in parallel. Their full reports are in this directory. This is the integrated view.

---

## Executive summary — the 5 things to fix this week

The audits converged on a small, urgent set of findings around the **new admin panel + restore flow** that combine into a chain attack. Fix these first; the rest can be sequenced.

| # | Finding | Source | Why it matters |
|---|---------|--------|---------------|
| 1 | **CSRF globally disabled** — `ApplicationController` never calls `protect_from_forgery`; commented out in `config/application.rb:58` | sec C1 | Every authenticated POST/DELETE in `/backend` and `/admin` is forgeable. Multiplies the impact of every other finding. |
| 2 | **Admin panel ships default `admin/admin` credentials** — `app/controllers/admin/base_controller.rb:9-10` `ENV.fetch('ADMIN_PASSWORD','admin')` | sec C2, qa #3 | Single misconfig = full multi-tenant compromise. |
| 3 | **Command/SQL injection in tenant restore** — `lib/ekylibre/tenant.rb:134` shells out `unzip … #{archive_file}`; `:537-541` interpolates `tenant_name` into `psql` SQL | sec C5 | Reachable from the admin restore upload (which derives the tenant name from the uploaded filename, no sanitation). With #2, full RCE. |
| 4 | **ZIP slip in 7+ exchangers** — `entry.extract(dir.join(entry.name))` with no path-resolution check | sec C6 | Arbitrary file write into the Rails tree, including autoload paths. Compounds with #3. |
| 5 | **Committed `secret_key_base` for dev/test** — `config/secrets.yml:21,24` | sec C3 | Tracked in git; rotate now. |

**The chain:** an attacker who finds an admin instance still on `admin/admin` (or CSRFs an authenticated admin) uploads a ZIP whose name carries a SQL/shell payload → restore endpoint runs it under the postgres role → game over. Each link individually is a Critical; together they are an exploit kit.

---

## Cross-cutting strategic risks

These came back from multiple agents and should drive the v5/v6 roadmap, not a sprint.

**EOL stack across the board.** Rails 5.2.8.1 (EOL 2022-06), Ruby 2.6.6 (EOL 2022-03), Sidekiq 4.2.10, PostGIS 9.6 in CI (EOL 2021), Paperclip (deprecated). No security backports. Identified by arch + qa.

**Apartment 2.2.1 is the upgrade blocker.** Unmaintained since 2019, version-locks `apartment-sidekiq`, monkey-patched in `config/initializers/apartment.rb:38-92`. Sidekiq cannot upgrade independently; Rails upgrade is gated on the plugin loader, which is gated on Zeitwerk, which is gated on autoload paths managed by `lib/ekylibre/plugin.rb`. Single biggest leverage point for the project's future.

**Test debt concentrated where defects are most likely.** 0 integration tests, 71 exchanger tests for 112 exchangers (some vendors with 13 sources / 2 tests), 0 tests for the entire new admin namespace. Coverage gate (`SimpleCov.minimum_coverage`) is commented out. CI runs against EOL PostGIS.

**No real cache backend in production.** `config/environments/production.rb:64` leaves `cache_store` commented; falls back to per-process `:memory_store`. Combined with un-cached `Preference[…]` and `Onoma::*` lookups firing inside `before_validation` and `after_save` (`app/models/journal_entry.rb:296`, `lib/ekylibre/record/bookkeep.rb:41,53`) this is the largest CPU/DB tax on every request — Redis is already running.

**`Intervention` is a hot mess.** 1472 LOC, `after_save` block (`:381-430`) does per-target queries × N targets, plus `WorkerTimeIndicator.refresh` non-concurrently on every save (`:429`) — that takes an `ACCESS EXCLUSIVE` lock on the materialized view. Bulk imports stall every concurrent reader.

---

## Recommended action ladder

### This week — security fixes (all S effort, single-line or single-file)

1. Add `protect_from_forgery with: :exception` in `ApplicationController` and `Admin::BaseController`; opt-out only on stateless API controllers.
2. Refuse to boot if `ADMIN_USERNAME`/`ADMIN_PASSWORD` are unset or shorter than N chars; remove the `'admin'` default.
3. Validate `tenant_name` against `/\A[a-z0-9_]+\z/` at every entry of `Ekylibre::Tenant`; use `Shellwords.escape` for shell args; quote PostgreSQL identifiers.
4. Add a ZIP-slip guard helper used by every exchanger (`File.expand_path` start_with? check + symlink reject).
5. Move dev/test `secret_key_base` to ENV; rotate the committed values.
6. Whitelist `params[:id]` in `Admin::TenantsController#dump_download` and `#destroy` against `Ekylibre::Tenant.list`.
7. Disable `noent` in `app/exchangers/ekylibre/backup_exchanger.rb:239-241` (XXE).
8. Anchor the CORS regex in `config/application.rb:75` (`\A…\z`, escape dots).

### This month — quality + perf wins

- Configure `:redis_cache_store` in production; memoize `Preference[]` and `fec_compliance_preference` per request via `RequestStore`.
- Add `type` indexes on `product_nature_variants`, `product_nature_categories` (verify `db/structure.sql`).
- Fix the `Intervention#after_save` hot path: gate on `saved_change_to_state?`; preload products; debounce `WorkerTimeIndicator.refresh` to a single post-transaction job.
- Add CodeQL coverage for `5.0-beta` (`.github/workflows/codeql.yml:15-19`); bump CI image to PostGIS 13+.
- Re-enable the SimpleCov floor at the current measured value.
- Add at least one smoke test per exchanger (import fixture, expect N records).
- Add request specs for the entire `Admin::*Controller` set.

### This quarter — strategic decisions (need product/team input, not just engineering)

- Multi-tenancy: stay on `ros-apartment` fork, or commit to a row-level `tenant_id` migration over 2-3 years? Determines everything downstream.
- Plugin contract: freeze the `Plugfile` DSL as v5.0's stable contract, or convert to standard Rails Engines before Rails 6? 16 plugins depend on this.
- Reporting stack: replace beardley/Jasper (rjb is on the Rails 6 critical path).
- Boundary convention: pick one of `concepts/services/interactors/queries/decorators` and stop adding to the others.

---

## Strengths to preserve through any refactor

- `Ekylibre::Tenant` wrapper is widely used — only 5 files outside it touch Apartment directly. Best lever for replacement.
- Persistent `lexicon` schema — genuinely good multi-tenancy design.
- `ActiveExchanger` registry + Telepac mixin pattern — the right shape; other vendors should copy it.
- Admin/tenant boundary in 5.0-beta is cleanly drawn; long-running ops via `Process.spawn` is the correct workaround for the apartment-sidekiq coupling.

---

## Finding counts (per-domain reports linked from README)

| Domain | Critical | High | Medium | Low |
|--------|---------:|-----:|-------:|----:|
| Security | 6 | 9 | 8 | 6 |
| Performance | 3 | 6 | 7 | 3 |
| Quality | 4 | 6 | 5 | 5 |

Architecture: 5 strategic risks + 5 structural debts + 5 strengths + 6 open decisions.
