# Ekylibre Performance Audit — 5.0-beta

**Date:** 2026-05-07
Audit of `/home/djoulin/projects/ekylibre`. Findings cited at `path:line`. Effort key: S = <1d, M = 1–3d, L = >3d.

## CRITICAL

### 1. `WorkerTimeIndicator` materialized view refreshed on every Intervention save
`app/models/intervention.rb:429` calls `WorkerTimeIndicator.refresh` inside `after_save`. `app/models/worker_time_indicator.rb:54-55` runs `Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)`. A non-concurrent refresh holds an `ACCESS EXCLUSIVE` lock for the duration of the rebuild and blocks all readers; firing on every Intervention save (including bulk imports, costing recompute, state changes) means each save can stall every concurrent request that touches the view. A bulk save of N interventions = N full view rebuilds.
**Fix:** move to `concurrently: true`, debounce via a single post-transaction job, or kick to Sidekiq with deduping (sidekiq-unique-jobs is already a dependency).
**Effort:** M.

### 2. No production cache_store configured + no caching of `Preference[]` / `Onoma`
`config/environments/production.rb:64` only has the commented `# config.cache_store = :mem_cache_store`. Rails 5 falls back to `:memory_store` (in-process, per-worker, capped, useless across processes/dynos) and `action_controller.perform_caching = true` produces nothing useful without a real backend. `Preference.[]` (`app/models/preference.rb:119-121`) issues a fresh `find_by(name:)` SQL query each time — yet `Preference[:bookkeep_in_draft]` and `Preference[:bookkeep_automatically]` fire on every save through `lib/ekylibre/record/bookkeep.rb:41,53`, and `Preference[:currency]` fires inside `JournalEntry`'s `before_validation` (`app/models/journal_entry.rb:296`). 266 `Onoma::*` lookups in `app/`. Combined with multi-tenant cross-talk this is the single biggest CPU/DB tax on every request.
**Fix:** configure `:redis_cache_store` (Redis already runs), wrap `Preference#[]`/`fec_compliance_preference` (`app/models/journal_entry.rb:553`) with per-request memoization via `RequestStore` plus tenant-aware `Rails.cache`.
**Effort:** M.

### 3. STI tables without a `type` index (`product_natures`, `product_nature_variants`, `product_nature_categories`)
`db/structure.sql` defines `index_products_on_type` (line 24806) but no equivalent on the three other heavy STI tables — verified by grepping all `CREATE INDEX.*product_nature*` results. Every `ProductNature.where(...)` Rails STI query appends `WHERE type = '…'`. On large tenants these produce sequential scans.
**Fix:** add `CREATE INDEX … ON public.product_nature_variants (type)` etc.; consider `(type, id)` covering indexes for hot scopes.
**Effort:** S.

## HIGH

### 4. N+1 in `InterventionDecorator#land_parcels_datas`
`app/decorators/intervention_decorator.rb:12-34` does `object.targets.find_each` then per target calls `target.product`, `target.product.activity.color`, `ActivityProduction.find_by(support: product)`, `activity_production.cultivable_zone.work_number`. With ~100 targets that is ~400+ queries per page render. `find_each` precludes any `.includes`.
**Fix:** replace `find_each` with `targets.includes(product: [:activity, :default_storage]).each`; preload `ActivityProduction` matches in one `where(support_id: product_ids)` call.
**Effort:** S.

### 5. N+1 + per-row `Preference[]` in draft journals listing
`app/views/backend/draft_journals/_list.html.haml:50` iterates `@draft_entries.each`, then `entry.items.each` → `item.account`, `item.variant`, `entry.journal`, `Preference[:currency]` (line 60, **inside the inner loop**), and `JournalEntry.fec_compliance_preference` (line 63, executes `Preference.global.find_by` per row). `app/controllers/backend/draft_journals_controller.rb:50-52` builds `@draft_entries` with no `.includes`. With paginated 20 entries × ~5 items, that's hundreds of queries per render.
**Fix:** `@draft_entries = …includes(:journal, items: [:account, :variant])`; hoist `Preference[:currency]` and `fec_compliance_preference` out of the loop into local variables.
**Effort:** S.

### 6. `EquipmentLifeProgressCheckJob` loads all Equipment rows into Ruby
`app/jobs/equipment_life_progress_check_job.rb:9-15` does `Equipment.select { … lifespan_progress > … }` (Ruby `Array#select`, not SQL), pulling every Equipment row into memory. Then `Equipment.where.not(id: worn_equipments.map(&:id)).each` (line 24) iterates the rest, calling `equip.components.select` per row — N+1 over all components. Runs on schedule.
**Fix:** push `lifespan_progress` evaluation into SQL or `find_each` + preload `:components`; cap memory.
**Effort:** M.

### 7. `UpdateInterventionCostingsJob`: reload+save+update_costing in series, no batching
`app/jobs/update_intervention_costings_job.rb` does `interventions.tap(&:reload).map(&:save!)` then `each(&:update_costing)`. Each `save!` re-runs the heavy intervention `after_save` block (cf. finding 1 + 14) — including `WorkerTimeIndicator.refresh` per call. Re-loads the entire AR::Relation.
**Fix:** skip `save!` when only costings change; use `find_each` and bypass intervention callbacks (`update_columns`).
**Effort:** M.

### 8. Heavy `after_save` block on `Intervention` performs per-target queries
`app/models/intervention.rb:381-430`: `targets.find_each` then per target calls `Product.find(target.new_container_id)`, `Product.find(target.new_group_id)`, `ProductNatureVariant.find(target.new_variant_id)`, plus three `find_or_create_by` round-trips, `working_periods.maximum(:stopped_at)` recomputed each iteration, `participations.update_all` twice, `update_costing`, `reconcile_receptions`, `WorkerTimeIndicator.refresh`. Every single intervention update pays this cost.
**Fix:** hoist `working_periods.maximum` once; preload Products with `where(id: target.new_container_ids)`; gate the block on `saved_change_to_state?` so trivial updates don't pay the bill.
**Effort:** M.

### 9. Rake `update_costings` invokes `update_costing` per intervention without batching
`lib/tasks/maintenance/interventions/update_costings.rake:12` runs `Intervention.find_each(&:update_costing)` over every intervention in every tenant — comments themselves warn the script "uses STI". Each call goes through Intervention's full save path (finding 8). On a tenant with 50k interventions this is hours.
**Fix:** batched SQL update, or scope to dirty rows.
**Effort:** M.

## MEDIUM

### 10. Exchangers use `find_or_create_by!` per row, not bulk insert
47 `find_or_create_by`/`find_or_create_by!` callsites in `app/exchangers/` (e.g. `telepac/exchanger_mixin.rb:43,82,188,353`, `socleo/sales_exchanger.rb:199-272`, `agroedi/daplos_exchanger.rb:126-128`, `bordeaux_sciences_agro/istea/balance_exchanger.rb:64-101`). Each does SELECT-then-INSERT in its own statement; only one of these files explicitly wraps the work in a transaction (per the grep — broader transaction boundaries may exist in `ActiveExchanger::Base`, I did not verify). Large CSVs become thousands of round trips.
**Fix:** prebuild a hash of existing keys in one query; use `insert_all` (Rails 5.2 has `activerecord-import`).
**Effort:** M per exchanger.

### 11. `Equipment` / `Account` / `Entity` raw SQL UPDATEs interpolated, no prepared statements
`app/models/account.rb:747-749` and `app/models/entity.rb:510-512` do `connection.execute("UPDATE … WHERE … = #{other.id}")`. Bypass query cache, no plan reuse. Also a SQL-injection risk if any caller leaks a tainted id.
**Fix:** use `quote` and bind params or `update_all`.
**Effort:** S.

### 12. `cap_islet.rb` PostGIS calls without spatial index hint
`app/models/cap_islet.rb:65-71` builds `ST_Extent(shape) FROM cap_islets WHERE id IN (…)` then a second `ST_Extent` over the whole table. 27 GiST indexes exist in `db/structure.sql` (verified by `grep -c "USING gist"`); did not verify whether `cap_islets.shape` is one of them — worth confirming.
**Fix:** confirm GiST on `cap_islets(shape)`; cache extent computation.
**Effort:** S.

### 13. `compute_pfi_async` after_commit on Intervention
`app/models/intervention.rb:433` enqueues async PFI computation on every commit. Combined with finding 1 means each save fans out to a Sidekiq job. Sidekiq 4.x is end-of-life and has known memory regressions vs 6/7 with apartment-sidekiq middleware that switches schemas per job (cold connection per job).
**Fix:** upgrade Sidekiq + apartment-sidekiq; coalesce PFI jobs.
**Effort:** L (upgrade), S (coalescing).

### 14. `JournalEntry#before_validation` rebuilds totals via `items.to_a.reduce` ×6
`app/models/journal_entry.rb:263-272` calls `items.to_a` six times in the same callback, plus iterations with `items.reject` (line 281). When items is a not-loaded relation each `to_a` triggers a re-read or at least re-iteration; with deeply-built nested attributes this is wasteful.
**Fix:** assign `items_array = items.to_a` once; reduce in one pass returning [debit, credit, real_debit, real_credit].
**Effort:** S.

### 15. `production.rb` has `enable_dependency_loading = true` and `eager_load = true`
`config/environments/production.rb:11,126`. Eager_load in prod is correct, but `enable_dependency_loading = true` reintroduces the classic autoload tax in production for any path missed by eager loading — undermining the advantage. The TODO comment acknowledges it.
**Fix:** remove `enable_dependency_loading`; fix any resulting `NameError`s by adding paths to `config.eager_load_paths`.
**Effort:** S.

### 16. `Account.connection.execute` loop in `financial_year_close`
`app/services/financial_year_close.rb:500-510` iterates `Affair.affairable_types.each` and runs an `UPDATE` per type. Each `constantize` triggers possible class-load cost; queries are interpolated.
**Fix:** unionize updates.
**Effort:** M.

## LOW

### 17. Cropping plan cells issue per-activity SQL
`app/views/backend/cells/cropping_plan_on_cultivable_zones_cells/show.html.haml:7-17` iterates activities and per activity calls `activity.net_surface_area(@campaigns)` (likely SQL) and `activity.productions.of_campaign(@campaigns).order(:id).each` then `production.net_surface_area`. Cell render — fix when revisiting dashboard. **Effort:** S.

### 18. API phytosanitary endpoint builds unbounded `(VALUES …)` SELECT
`app/controllers/api/v[12]/lexicon/api_phytosanitary_data_controller.rb:62` builds an in-memory `(VALUES …)` SELECT from request input. With long client-supplied lists the query plan degrades. Add a row-count guard. **Effort:** S.

### 19. Gemfile cold-boot cost
Gemfile has 273 lines with many `require: false`-style deps not used at runtime: cold-boot only, but each Sidekiq worker pays it. **Effort:** M to audit.

## Notes / unverified claims

- I did not run the app or profile; all findings are static.
- `Preference[]` could be cached behind a Russian-doll layer I missed; I only inspected `app/models/preference.rb`.
- Whether `cap_islets.shape` has a GiST index needs a direct check of `structure.sql` for `cap_islets`-specific gist (27 such indexes exist overall but I did not enumerate names).
- Exchanger transaction boundaries may be set in `ActiveExchanger::Base` (gem), not visible here.
- `Bookkeep` macro (`lib/ekylibre/record/bookkeep.rb:45`) does `self.class.where(id: id).update_all(column: now)` after the bookkeeping block — that's an extra UPDATE per save on every bookkept model, but correct vs. a save-loop. Not flagged as a finding.

**Files most worth touching first:** `app/models/intervention.rb`, `app/models/preference.rb`, `config/environments/production.rb`, `app/views/backend/draft_journals/_list.html.haml`, `app/decorators/intervention_decorator.rb`, `app/jobs/update_intervention_costings_job.rb`, `db/structure.sql` (add `type` indexes).
