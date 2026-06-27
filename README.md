# Ekylibre

Ekylibre is a multi-tenant **Farm Management Information System** (FMIS) for crop, livestock, viticulture and accounting management.

Built with [Ruby on Rails](https://rubyonrails.org/), [PostgreSQL](https://www.postgresql.org/) + [PostGIS](https://postgis.net/), and packaged for Docker production with Caddy (multi-tenant TLS) and Dokploy.

- 🌐 Website: <https://ekylibre.org>
- 🚀 Live demo: <https://demo.ekylibre-dev.com>
- 📚 User documentation (FR): <https://ekylibre.github.io/doc/fr/demarrage/>
- 💬 Community forum: <https://discord.com/invite/BSpD6hq7qR>

## Screenshot

[Screen](https://github.com/ekylibre/demo-data/blob/main/demo/alamano/background.jpg)

## What's new in 5.0

Ekylibre **5.0** (June 2026) is a major release. Highlights:

- 🌱 **HVE audit module** — Haute Valeur Environnementale (V4.4) scoring across biodiversity, phytosanitary, fertilisation and irrigation themes.
- 📋 **Phytosanitary register 2027** — automated legal treatment register (XML / JSON / CSV) per *Arrêté du 24 décembre 2025*, with 5-year archival.
- 🤖 **Duke AI assistant** — embedded conversational widget with voice input (STT), structured intervention drafting, and a model selector (Claude / Mistral / local Ollama).
- 🛠 **Admin & landing platform** — `/admin` namespace for tenant CRUD, demo loading, restore, lexicon management, plugins inspector.
- 🌐 **API v2 expanded** — new endpoints (`cultivable_zones` with GeoJSON, `procedures`, `farm_profiles`, `farm_accountancy`, `users`, `tokens`, `variants`, `products`), idempotent intervention CRUD, OpenAPI 3.0 spec.
- 📊 **ECharts** replaces Highcharts for all dashboards and analyses.
- 🧩 **Plugins recentered on GitHub** — 16 public plugins shipped via `docker/prod/Gemfile.prod` (banking, ednotif, hve, idea, traccar, sencrop, weenat, agro-monitoring, etc.).
- 📱 **Zero Mobile** — pilot React Native app for offline spraying intervention capture (iOS TestFlight + Android Play Internal Testing).

**Full release notes (FR):** [`docs/releases/5.0.fr.md`](docs/releases/5.0.fr.md)
**Technical changelog:** [`CHANGELOG.md`](CHANGELOG.md)

### Breaking changes

- App server **Unicorn → Puma 5.6** in production.
- **Node 20** minimum (was 14).
- Production reverse proxy **Nginx → Caddy** (on-demand multi-tenant TLS).
- `docker/db/init.sql` requires the new `IF EXISTS` guard around `DROP EXTENSION postgis` — see [CLAUDE.md](CLAUDE.md) for context.
- **AgroMonitoring** moved out of core into the [`ekylibre-agro-monitoring`](https://github.com/ekylibre/ekylibre-agro-monitoring) plugin.

## Installation

* [Install Ekylibre](https://ekylibre.org/techdoc/)
* [Docker](./docker/README.md)
* [Docker production (Dokploy)](./docker/prod/README.md) — Caddy multi-tenant TLS, GHCR images

## Documentation

- [User documentation (FR)](https://ekylibre.org/fr/user-doc/demarrage/)
- [Tech documentation (FR)](https://ekylibre.org/techdoc/)
- [API v2 — French integration guide](https://ekylibre.org/api/)
- [API v2 — OpenAPI 3.0 spec](./docs/api/openapi-v2.yaml)
- [5.0 release notes (FR)](./docs/releases/5.0.fr.md)
- [Architecture analysis](./docs/analysis/)
- [Developer guide for Claude Code](./CLAUDE.md) — tenant management, performance hotspots, lexicon ops

## Contributing

We encourage contributions.

* Read the dev conventions ([Français](https://github.com/ekylibre/ekylibre/wiki/Conventions-de-d%C3%A9veloppement))
* Check the issue tracker before starting work
* Fork → feature/bugfix branch → commit → PR
* Add tests for any new behaviour
* Keep refactors isolated from feature commits

## See also

* [Live demo](https://demo.ekylibre-dev.com)
* [Demo dataset - FR](https://github.com/ekylibre/demo-data)

## License

Ekylibre is released under the [GNU/AGPLv3](http://opensource.org/licenses/AGPL-3.0) license.
