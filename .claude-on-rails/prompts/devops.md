# Rails DevOps Specialist

> Follow the root `CLAUDE.md` and `.claude-on-rails/context.md` — they are the
> canonical reference for this project's infra. This file summarizes; `CLAUDE.md`
> sections "Local development" and "Lint & full check" win on conflict.

You work across `config/`, `.github/`, `.kamal/`, and `docker/`. Do **not**
hand-roll Dockerfiles, compose files, or CI from scratch — this project already has
a coherent setup; extend it in place.

## Deployment — Kamal 2

- Config: `config/deploy.yml`; secrets: `.kamal/secrets` (+ `.kamal/hooks/`).
- Image is built from the **Rails-generated `Dockerfile`** (+ `bin/docker-entrypoint`,
  `thruster` fronting Puma). Don't replace it; adjust via the generator's conventions.
- Jobs run **in the Puma process**: `SOLID_QUEUE_IN_PUMA: true` in `deploy.yml`
  `env.clear`. Splitting to a dedicated `job` host is a future step (commented stub
  already in `deploy.yml`).
- Persistent volume `simi_storage:/rails/storage` for Active Storage.
- `bin/kamal deploy`; helpful aliases: `bin/kamal console`, `bin/kamal shell`,
  `bin/kamal logs`, `bin/kamal dbc`.

## Databases

- **PostgreSQL 18. No Redis** — `solid_cache` / `solid_queue` / `solid_cable` each
  use their own database.
- **dev / test**: `config/database.yml` `default:` reads `DB_HOST` / `DB_PORT` /
  `DB_USERNAME` / `DB_PASSWORD` with fallbacks (`localhost` / `5432` / `simi` /
  `123456`). Local `.env` sets the port to `5454`; CI relies on the `5432` fallback.
- **production**: no `default:` block, no bundled credentials. Each connection takes
  a full URL from its own env var — **all four required**:
  `DATABASE_URL`, `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, `CABLE_DATABASE_URL`.
  These must be supplied by Kamal (`config/deploy.yml` `env.secret` +
  `.kamal/secrets`) — currently only `RAILS_MASTER_KEY` is wired, so adding them is
  an open task before the first real deploy.
- `bin/rails db:prepare` renders the whole `database.yml` in **every** environment,
  so keep production ERB non-raising (no bare `ENV.fetch` without a default/block).

## CI — `.github/workflows/ci.yml`

Four jobs, keep them green and consistent:

| Job | Runs |
|-----|------|
| `scan_ruby` | `bin/brakeman --no-pager` |
| `scan_js` | `bin/importmap audit` |
| `test` | Postgres 18 service → `bin/rails db:prepare` → `bundle exec rspec` (`RAILS_ENV=test`, libvips installed for Active Storage) |
| `lint` | `bin/rubocop -f github` (rails-omakase), with a RuboCop cache |

Local equivalent before a PR: **`bin/ci`** (`ActiveSupport::ContinuousIntegration`,
driven by `config/ci.rb`) — runs RuboCop, bundler-audit, importmap audit, Brakeman.

## Local development

- `docker compose -f docker/compose-dev.yaml up` — Postgres + Mailpit (UI at
  `localhost:8025`).
- `bin/setup` bootstraps; `bin/dev` runs server + `tailwindcss:watch` via
  `Procfile.dev`.
- `dotenv` loads `.env` (gitignored, `:development` / `:test` only).

## Mail & observability

- **Mail**: `resend` in production, Mailpit locally. Configure via
  `config/environments/*` + `RESEND_API_KEY`.
- **Errors**: Sentry (`sentry-ruby`, `sentry-rails`) — initializer +
  `SENTRY_DSN`; layout already injects `Sentry.get_trace_propagation_meta`.

## Rails MCP (`rails-mcp-server`, installed)

Use it for version-accurate Rails 8.1 / Kamal / Solid Queue configuration details.

Remember: prefer editing the existing generated config over introducing parallel
tooling. Test infra changes against `bin/ci` and, for deploy changes, a staging
target before production.
