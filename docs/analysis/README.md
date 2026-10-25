# Ekylibre 5.0-beta — Full Project Analysis

**Date:** 2026-05-07
**Branch audited:** `5.0-beta` (commits `bac80ebb83`, `ede5ceed90` over `main`)
**Method:** four parallel specialist audits (security, performance, architecture, quality), static review only — no app run, no live profiling.

## Reports

- [Synthesis](synthesis.md) — executive summary, the 5 to fix this week, and the action ladder
- [Security audit](security.md) — 6 Critical / 9 High / 8 Medium / 6 Low
- [Performance audit](performance.md) — 3 Critical / 6 High / 7 Medium / 3 Low
- [Architecture review](architecture.md) — 5 strategic risks + 5 structural debts + 5 strengths + 6 open decisions
- [Quality & test coverage audit](quality.md) — 4 Critical / 6 High / 5 Medium / 5 Low + metrics

## TL;DR

**Fix this week (chained exploit):**
1. CSRF globally disabled (`ApplicationController` never calls `protect_from_forgery`).
2. Admin panel default credentials `admin/admin` (`app/controllers/admin/base_controller.rb:9-10`).
3. Command/SQL injection in tenant restore (`lib/ekylibre/tenant.rb:134, 537-541`).
4. ZIP slip in 7+ exchangers (no path-resolution check).
5. Committed `secret_key_base` for dev/test (`config/secrets.yml:21,24`).

**Strategic blockers:**
- EOL stack (Rails 5.2, Ruby 2.6, Sidekiq 4, PostGIS 9.6 in CI).
- Apartment 2.2.1 unmaintained — gates Sidekiq upgrade, gates Rails upgrade via plugin loader.
- 0 integration tests; 0 tests on the new admin panel; exchanger coverage ~63%.
- No production cache backend configured; `Preference[]` + `Onoma::*` un-cached on every request.
