# ClaudeOnRails Context

This project uses ClaudeOnRails with a swarm of specialized agents for Rails development.

## Source of truth

The root **`CLAUDE.md`** and **`docs/PRD.md`** (product context, Portuguese) are
authoritative. The prompts in `.claude-on-rails/prompts/` are generic Rails advice —
where they disagree with `CLAUDE.md`, `CLAUDE.md` wins.

## Stack

- **Ruby 4.0.6, Rails 8.1, PostgreSQL 18.**
- **Views: Phlex, not ERB.** Pages are Ruby classes in `app/views/**/*.rb`
  (`Views::Base`); reusable components in `app/components/**/*.rb` (`Components::Base`,
  which mixes in `RubyUI` — https://rubyui.com). The only ERB left is
  `app/views/layouts/`.
- **Styling: TailwindCSS** via `tailwindcss-rails` (+ `tailwind_merge` for class
  conflict resolution). Source `app/assets/tailwind/application.css` → build
  `app/assets/builds/tailwind.css`.
- **JavaScript: importmap** (`importmap-rails`) — no Node, no bundler, no `package.json`.
- **Hotwire**: `turbo-rails` + `stimulus-rails`.
- **Assets**: propshaft (not Sprockets).
- **Async / cache / cable**: `solid_queue`, `solid_cache`, `solid_cable` — all
  Postgres-backed. **No Redis, no Sidekiq.**
- **Deploy**: Kamal 2 (`config/deploy.yml`, `.kamal/secrets`) + the Rails-generated
  `Dockerfile` + `thruster`.
- **Mail**: `resend` in production, Mailpit locally (`docker/compose-dev.yaml`).
- **Error tracking**: Sentry (`sentry-ruby`, `sentry-rails`).
- **Tests**: RSpec (`rspec-rails`), FactoryBot, **FFaker** (not Faker — the API differs).

## Swarm agents

Defined in `claude-swarm.yml`: architect (coordinator) → models, controllers, views,
stimulus, services, jobs, tests, devops. Each works in its own directory; the
architect plans and delegates.

## Commands

- Tests: `bundle exec rspec` (no binstub) — single example: `bundle exec rspec spec/models/foo_spec.rb:42`.
- Style: `bin/rubocop` (rails-omakase).
- Full local check before a PR: `bin/ci` (RuboCop, bundler-audit, importmap audit, Brakeman).
- Run the app: `bin/dev` (server + `tailwindcss:watch` via `Procfile.dev`).
- Bootstrap: `bin/setup`. Local services: `docker compose -f docker/compose-dev.yaml up`.

## Development guidelines

- Follow Rails conventions; keep models focused; extract complex business logic to
  service objects (`app/services/`).
- Write specs for all new functionality; use FactoryBot + FFaker.
- Strong parameters in controllers (`params.expect`).
- Index foreign keys and columns used in `WHERE`.
- No stray comments — see `CLAUDE.md` "Code style".
