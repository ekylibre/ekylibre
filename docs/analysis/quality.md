# Ekylibre 5.0-beta — Code Quality & Test Coverage Audit

**Date:** 2026-05-07

> **Note de suivi (2026-09-10).** Les constats ci-dessous sont ceux du jour de l'audit et sont conservés tels quels. Deux ont été traités depuis, dans le cadre du [plan v6](../planning/v6-improvement-plan.md) : la CI a quitté GitLab pour GitHub Actions (PostgreSQL 13, plus 9.6), et le plancher `SimpleCov` est posé — la mesure sur laquelle reposait le `43` commenté était faussée, `SimpleCov.start` s'exécutant après le chargement de l'application.

## Metrics summary

- **Source**: 418 model files, 404 controller files, 112 exchanger files, 703 migrations.
- **Tests**: 804 `*_test.rb` (260 model, 288 controller, 71 exchanger, 68 service, 17 jobs, 43 helpers, 32 lib, **0 integration**).
- **Largest files**: `lib/procedo/formula/language.rb` (3203), `lib/working_set/query_language.rb` (1954, both rubocop-excluded auto-generated parsers), `app/models/intervention.rb` (1472), `app/helpers/application_helper.rb` (1165), `app/models/product.rb` (1048), `app/models/product_nature_variant.rb` (1011). Largest controller: `backend/interventions_controller.rb` (820).
- **Annotations**: 552 TODO/FIXME/HACK/XXX in app+lib (134 TODO, 46 FIXME, 1 HACK across `.rb`); ~109 `pp`/`puts`/`binding.pry`/`byebug` mentions, including 5 commented-out `byebug` in `lib/ekylibre/tenant.rb`.
- **CI**: GitLab `.gitlab-ci.yml` runs `rubocop --parallel`, `eslint`, and `bin/rails test` against `mdillon/postgis:9.6-alpine` (PG 9.6, EOL since 2021). GitHub Actions only runs CodeQL + stale bot — `codeql.yml` `on.push.branches` does not include `5.0-beta`.
- **Coverage**: `simplecov 0.21.2` + `simplecov-cobertura` wired in `test/test_helper.rb`. `SimpleCov.minimum_coverage 43` is **commented out**. No coverage value visible without running.
- **Migrations**: 703 total; only 24 declare `ActiveRecord::Migration[5.2]` (new format). 315 contain raw `execute`. ~100 named `*fix*`/`*update*` (data corrections).
- **Gemfile.lock**: last regenerated 2026-03-28; Rails pinned to **5.2.8.1** (EOL — last security release June 2022). Ruby 2.6.6 (EOL March 2022). `bundle outdated` shows hundreds of stale gems including `sidekiq 4.2.10` (current 8.x), `paperclip 5.3.0` (gem unmaintained since 2018), `devise 4.9.2`, `database_cleaner 1.99.0`.
- **APM**: `exception_notification` only. No newrelic/sentry/datadog/skylight.
- **Branch delta** (`main..5.0-beta`): 27 files, +1528/-35 lines. New admin panel (`app/controllers/admin/*`, ~298 LOC), `Admin::LoadDemoJob`, dump/restore/demo rake tasks, dnsmasq sidecar. **Zero tests added** for any new code (`git diff main..5.0-beta --name-only | grep test` returns empty).

---

## CRITICAL

### 1. Rails 5.2 / Ruby 2.6 / Sidekiq 4 — all EOL, no security patches
Gemfile.lock pins `rails 5.2.8.1` (EOL 2022-06), Ruby 2.6.6 (EOL 2022-03), `sidekiq 4.2.10` (unsupported), `paperclip 5.3.0` (deprecated upstream, replaced by Active Storage). Any unpatched CVE in this stack is live in production.
**Recommendation:** prioritize Rails 6.1 -> 7 upgrade path; replace Paperclip; bump Ruby to 3.x. The 5.0-beta branch is the right place to stage this.

### 2. CI runs PostGIS 9.6 — production drift risk, EOL DB
`.gitlab-ci.yml:160` uses `mdillon/postgis:9.6-alpine` (a TODO comment acknowledges it). PG 9.6 is EOL since November 2021. Tests do not exercise the PG version any tenant on a recent install would run.
**Recommendation:** switch to `postgis/postgis:13-3.1` or newer; align CI with the OS image used in `docker/dev`.

### 3. Admin panel ships with HTTP Basic + default `admin/admin` and no tests
`app/controllers/admin/base_controller.rb:9-10` uses `ENV.fetch('ADMIN_USERNAME', 'admin')` / `'admin'` defaults. The whole admin namespace (tenant create/destroy/dump/restore — destructive operations) has zero tests (`test/controllers/admin/` does not exist). `Admin::TenantsController#create` (`tenants_controller.rb:23-52`) uses string interpolation in flash with the generated password and rescues the bare class.
**Recommendation:** enforce non-default credentials in production (fail-fast in initializer), add controller tests covering create/destroy/dump permission boundaries; never echo a password in a flash.

### 4. CodeQL workflow ignores active branch
`.github/workflows/codeql.yml:15-19` lists branches up to `1-3-stable` plus `main`. The 5.0-beta branch is excluded from push triggers, and PRs only run against main — so static security scanning is inactive for this work.
**Recommendation:** add `5.0-beta` (and a wildcard for stable branches) to `on.push.branches`.

---

## HIGH

### 5. Exchanger coverage is a 50/50 lottery, despite being highest defect surface
71 exchanger tests vs 112 exchanger sources. Specifically untested: `acom`, `listo`, `planete_vegetal`, `square` (3 files). `telepac` has 13 sources / 2 tests; `agroedi` 12 sources / 1 test. These are externally-supplied data formats — silent regressions cause data corruption.
**Recommendation:** at minimum a smoke "import a fixture, expect N records, no exception" per exchanger; promote `agroedi` and `telepac` to first-class with golden-file fixtures.

### 6. Zero integration tests, zero system/feature tests
`test/integration` does not exist; no Capybara/`ActionDispatch::IntegrationTest` files. Backend layout (`backend.html.haml` beehive cells), Devise sign-in flow, multi-tenant subdomain routing — all unverified end-to-end.
**Recommendation:** add a thin smoke-test integration suite (sign in, switch tenant via header, render dashboard, hit one CRUD path).

### 7. God-class candidates concentrated in core domain
`app/models/intervention.rb` (1472 LOC), `product.rb` (1048), `product_nature_variant.rb` (1011), `account.rb` (910), `activity_production.rb` (861). `app/helpers/application_helper.rb` (1165) is a kitchen-sink helper. `backend/interventions_controller.rb` (820) and `backend/base_controller.rb` (645) embed too much business logic.
**Recommendation:** extract by concern (`app/models/concerns/`), pull printers/services out of helpers; cap controllers at ~250 LOC.

### 8. Dead/commented `byebug` statements in production code path
`lib/ekylibre/tenant.rb` has 5 commented `byebug` markers (lines 55, 62, 377, 381, 388) inside tenant create/drop/restore. Indicates incomplete debugging sessions left behind, and the file is 572 LOC with a `puts` for status reporting (line 120) — should be a logger call.
**Recommendation:** remove dead breadcrumbs; route status output to `Rails.logger` (or pass a verbose IO param).

### 9. `.rubocop_todo.yml` is 1146 lines — lint debt is functionally permanent
`.rubocop.yml:3` inherits the todo file; `Layout/LineLength` and `Style/StringLiterals` are globally disabled with comments dating to 2021. Rubocop is pinned to 1.11.0 (current 1.86.x), so new cops never run.
**Recommendation:** chip away at the TODO file in PRs that touch listed files; bump rubocop to a recent 1.6x with auto-correct.

### 10. New admin tasks shell out to `bundle exec rake` via `Process.spawn` — fragile and unaudited
`app/controllers/admin/tenants_controller.rb:76-87` and `restore_controller.rb:25-33` spawn detached processes for dump/restore. Status is tracked via a Redis hash whose key is `ekylibre:admin:dump:<name>` — there is no timeout, no orphan cleanup, no retry policy, and no test. Restore writes upload directly to disk with `File.binwrite` and derives tenant name from the uploaded filename (`File.basename(filename, '.*')`) without sanitization — path-traversal-adjacent.
**Recommendation:** validate/sanitize tenant_name (reuse the `gsub(/[^a-z0-9_]/, '_')` already present at `tenants_controller.rb:25`); add request specs; consider a proper job runner with status, even if not Sidekiq because of the apartment middleware constraint.

---

## MEDIUM

### 11. Migration hygiene: data + schema mixed, raw SQL pervasive
315/703 migrations contain `execute`. ~100 named `*fix*` or `*update*` perform data corrections inside schema migrations. Only 24 are tagged `[5.2]`; the rest are pre-Rails-5 untyped (works, but loses version-specific defaults).
**Recommendation:** future migrations strictly schema-only; data corrections via reversible rake tasks. Tag all new migrations with `[5.2]`.

### 12. CLAUDE.md documents commands that do not exist in dev compose
CLAUDE.md mentions `rake first_run` and `rake tenant:init` — these exist (in `lib/tasks/`), but there is no mention of the new admin panel UI at `/admin`, the `dnsmasq`/`*.ekylibre.lan` wildcard DNS, or that plugins now live on GitHub (commit `4c6532cfde` migrated them). New onboarding will hit unexpected setup.
**Recommendation:** refresh CLAUDE.md with the admin panel URL, the dnsmasq host alias `127.0.0.2`, and the GitHub plugin source.

### 13. No structured logging, no APM, bare-string error logs
113 `Rails.logger` calls; examples like `app/jobs/intervention_export_job.rb` log raw exceptions and backtraces, `app/jobs/tax_declaration_job.rb` logs `$!`. No `lograge` / `semantic_logger` / `sentry-ruby`. Production log readability scales poorly.
**Recommendation:** add `sentry-ruby` (catches exceptions automatically, replaces `exception_notification`); add `lograge` for one-line request logs.

### 14. SimpleCov minimum-coverage gate disabled
`test/test_helper.rb:42` has `# SimpleCov.minimum_coverage 43` commented. Coverage is collected but never enforced. Cannot verify actual coverage % without running.
**Recommendation:** re-enable a floor (start at current measured value); fail CI if it drops.

### 15. Onboarding docs split across `doc/`, `docs/`, `docker/README.md`
`doc/index.md` lists 8 topics but never defines "tenant", "exchanger", "lexicon", or "onoma" as core concepts. New `docs/v6-brainstorm.md` is unrelated. Developers will not find architectural context without reading source.
**Recommendation:** a single `doc/architecture.md` (or expand CLAUDE.md) covering the four nouns.

---

## LOW

### 16. Bare `rescue` clauses
~78 bare `rescue` clauses across app/lib — silent failure risk. Search hot spots before refactor.

### 17. Lint TODO files
`.haml-lint_todo.yml` (41k LOC) and `.rubocop_todo.yml` are signals of bypassed tooling.

### 18. Bundler/Ruby version mismatch
`Gemfile.lock` `BUNDLED WITH 2.4.12` but Ruby is pinned at 2.6.6; bundler-2.5+ requires Ruby 3. Consistent today, but worth noting if upgrading Ruby.

### 19. Unused/empty tracked dirs
`plugins/` is empty (plugins now via Gemfile). `tmp/` shows `archives/` directory used at runtime but no `.keep`.

### 20. Stale-bot workflow
`.github/workflows/stale.yml` appears unconfigured for a multi-branch repo — could close legitimate long-running issues.

---

## What I could not verify

- Actual test pass rate / live coverage % — needs `docker compose ... rake test` execution.
- Whether GitLab CI is currently green on 5.0-beta — would need pipeline access.
- True "outdatedness" of plugins fetched from `github.com/ekylibre/*` — they are sub-bundles.
- Performance of admin dump/restore at realistic tenant size (1+ GB schema).

## Key files referenced

- `.github/workflows/test.yml`, `lint.yml`, `codeql.yml`
- `test/test_helper.rb`
- `.rubocop.yml`, `.rubocop_todo.yml`
- `Gemfile.lock`
- `app/controllers/admin/base_controller.rb`
- `app/controllers/admin/tenants_controller.rb`
- `app/controllers/admin/restore_controller.rb`
- `lib/ekylibre/tenant.rb`
- `app/models/intervention.rb`
- `CLAUDE.md`
- `doc/index.md`
- `db/migrate/` (703 files)
