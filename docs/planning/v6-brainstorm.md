# Ekylibre v6 — Requirements Specification

> Brainstorm output — `/sc:brainstorm` session, 2026-05-07.
> Scope: next generation of Ekylibre, any farm, integration as the constraint anchor.
> This document specifies **requirements only**. No architecture, schema, or implementation plan.
> Handoff: feed Open Questions into `/sc:design`.

## 1. Vision

A **federated, integration-native FMIS** that participates in a multi-vendor ag-data ecosystem (not a closed system of record). Primary value: **cross-farm data aggregation for cooperatives and advisors**, powered by a **third-party plugin marketplace** of pragmatic per-vendor adapters with bidirectional sync.

### Anchor decisions (input to this brainstorm)

- **Scope**: v6 of Ekylibre (next-generation rebuild, not greenfield, not a single feature gap).
- **Audience**: any farm — broad, not segmented to a sharper persona.
- **Constraint anchor**: integration capability is the lens shaping all requirements.
- **Loudest pain solved**: cooperatives and advisors cannot aggregate data across member farms.
- **Posture**: **node**, not hub — source of truth may live elsewhere; bidirectional sync.
- **Standards bet**: pragmatic per-vendor adapters over committing to ISOXML / ADAPT / EFDI.
- **Plugin model**: third parties can ship integrations on a public marketplace.

## 2. Personas

- **P1 — Farmer member**: operates one farm. Today's primary user.
- **P2 — Coop / Advisor** *(new first-class persona)*: needs aggregated views across N member farms, with member consent.
- **P3 — Third-party developer**: builds and ships an integration adapter on the marketplace.
- **P4 — Integration partner (vendor)**: system Ekylibre bidirectionally syncs with (John Deere, Sencrop, Smag, accounting tools, etc.).

## 3. Functional Requirements

### FR-1 — Cross-farm aggregation *(the primary unmet need)*
- **FR-1.1** A coop user requests access to N member farms; each member grants/revokes consent at granular scope (parcels, interventions, yields, phyto records, financials — separately).
- **FR-1.2** Coop runs aggregated queries (totals, averages, benchmarks, time-series) without leaking individual farm identity below a configurable anonymization threshold (min N farms per cohort).
- **FR-1.3** Member farms audit who accessed their data; revocation propagates within a defined SLA.
- **FR-1.4** Aggregations respect lexicon harmonization across heterogeneous source systems.

### FR-2 — Bidirectional sync as first-class capability
- **FR-2.1** Each integration declares **direction** per entity (read / write / bidirectional).
- **FR-2.2** Bidirectional integrations declare a **conflict resolution policy** (last-write-wins, source-wins, manual review, custom resolver).
- **FR-2.3** Every synced record carries **lineage**: source system, source ID, last sync, conflict history.
- **FR-2.4** UI shows "from {system}, last synced {when}" per record, with manual re-sync / override.
- **FR-2.5** Failed syncs surface in a per-tenant **sync inbox** with retry / abandon controls — not hidden in logs.

### FR-3 — Plugin marketplace
- **FR-3.1** Self-service developer portal for register / publish / version / deprecate.
- **FR-3.2** Each plugin declares: OAuth scopes required, entities touched, sync direction, pricing model.
- **FR-3.3** Automated security review (SAST, dependency scan, scope justification); optional manual "verified" tier.
- **FR-3.4** Tenant admins install / uninstall and grant OAuth scopes at install time.
- **FR-3.5** Plugin runtime is **isolated** — a misbehaving plugin cannot crash the host, exhaust DB, or read out-of-scope data.
- **FR-3.6** Pricing supported; Ekylibre handles billing / payouts; revenue split configurable.
- **FR-3.7** Plugin updates roll forward without host redeploy; rollback supported.

### FR-4 — Adapter SDK *(core of the pragmatic-per-vendor bet)*
- **FR-4.1** SDK exposes: lexicon mapping helpers, sync framework, conflict hooks, OAuth scaffolding, error / retry helpers, sandbox tenant for testing.
- **FR-4.2** Existing 30+ exchangers migratable with reasonable effort; backward compat during transition.
- **FR-4.3** SDK supports **batch** (file / import) and **streaming / event** (webhook, MQTT) integrations.

### FR-5 — Identity, consent, authorization
- **FR-5.1** Permissions modeled as **scopes** (`interventions:read`, `parcels:write`, …) with consent flows for both human users and cross-farm coop access.
- **FR-5.2** Federated identity via OAuth / OIDC — no password sharing across coop A ↔ Ekylibre v6.

### FR-6 — Source-of-truth posture *(node, not hub)*
- **FR-6.1** Per entity type, tenant configures which system is authoritative (e.g. JD owns parcel geometry, Ekylibre owns agronomic plan).
- **FR-6.2** UI clearly shows read-only state when authority lives elsewhere.

## 4. Non-Functional Requirements

- **NFR-1 Reliability** — One integration's failure cannot impact others or the host.
- **NFR-2 Security** — Plugin sandbox enforces scopes **at runtime**, not just at install. PII flows auditable.
- **NFR-3 Performance** — Coop aggregations across 100 farms over 1-year time-series return within 5s.
- **NFR-4 Compatibility** — Current exchangers keep working during a transition window (≥18 months, placeholder).
- **NFR-5 Auditability** — Every cross-tenant access and sync operation is logged for member-farm audit (FR-1.3) and regulator.
- **NFR-6 Multi-tenancy** — Apartment's schema-per-tenant either kept (with cross-tenant aggregation solved another way) or replaced. **This is the central architectural decision — see Open Questions.**
- **NFR-7 i18n / regional** — Marketplace supports country / region filtering (Telepac/FR, Cropwise/DE, …).

## 5. User Stories

**US-1 — Coop benchmarking.** *Coop agronomist compares wheat yields across 47 member farms.*
- (a) Benchmark visible only if ≥5 farms granted yield-read consent.
- (b) Each member sees audit entry of the query.
- (c) Revoking consent excludes the farm within ≤1h.

**US-2 — Tractor telemetry round-trip.** *JD pass completion auto-creates intervention in Ekylibre; edits flow back to Ops Center.*
- (a) Pass completion → Ekylibre intervention within ≤5 min.
- (b) Edits in Ekylibre → Ops Center within ≤5 min.
- (c) Concurrent edits trigger configured conflict policy (default: manual review in sync inbox).

**US-3 — Third-party publishing.** *Sencrop-weather plugin at €5 / farm / month.*
- (a) Submit via portal; automated checks within 10 min.
- (b) Visible in marketplace with declared pricing.
- (c) Monthly payouts net of revenue share.
- (d) Broken update is rollback-able without tenant impact.

**US-4 — Conflict surface.** *Farmer notices an external overwrite.*
- (a) Sync inbox shows both versions, source, timestamps.
- (b) One-click winner pick or field-level merge.

**US-5 — Exchanger migration.** *Move Isagri exchanger to v6 SDK without breaking customers.*
- (a) Old + new paths coexist during transition.
- (b) Per-tenant feature flag selects path.
- (c) Functional equivalence on documented import operations after cutover.

## 6. Open Questions *(input list for `/sc:design`)*

1. **Cross-tenant data model — the fault line.** Apartment is excellent for isolation but punishing for FR-1. Three candidates:
   - (a) Keep apartment + separate **aggregation warehouse** (replica → ETL → analytics schema) for coop queries only.
   - (b) Move to **single-schema multi-tenant** with `tenant_id` everywhere.
   - (c) Hybrid: apartment for transactional, columnar replica for analytics.
2. **Sync engine location.** In-process Sidekiq, separate sync service, or per-plugin runtime? Drives FR-3.5 isolation and scaling.
3. **Plugin runtime technology.** Rails engines in host process (no real isolation) vs. out-of-process workers / WASM / containers. 5-year bet.
4. **Marketplace billing.** In-house vs. Stripe Connect; EU VAT, partner KYC implications.
5. **Lexicon governance.** With third-party plugins, lexicon becomes a contract. Extension proposal flow? Versioning?
6. **Coop tenant model.** New "meta-tenant" type, role layered on existing tenants, or separate identity domain?
7. **OAuth / OIDC IdP.** Self-hosted vs. federated vs. both.
8. **Backward-compat horizon.** 18 months is a placeholder — depends on actual customer distribution.

## 7. Central tension to resolve first

**FR-1 (coop aggregation) and the apartment per-schema model are in real tension.** Every anchor decision above is internally consistent, but together they make the multi-tenancy decision (Open Question #1) the load-bearing one for v6. The rest of the architecture cascades from it.

## 8. Out of scope for this brainstorm

No architecture, schema, API design, or implementation plan — per `/sc:brainstorm` skill boundaries.
