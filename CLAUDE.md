# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

SIMI is a personal finance management platform. Product context: `@docs/PRD.md` (Portuguese).

Stack: Ruby 4.0.6, Rails 8.1, PostgreSQL 18, importmap (no Node build for JS).

## Views & components — Phlex, not ERB

Views and components are Ruby classes, not `.erb` templates.

- Pages: `app/views/**/*.rb`, subclass `Views::Base`.
- Reusable components: `app/components/**/*.rb`, subclass `Components::Base`.
- `Components::Base` mixes in `RubyUI` (https://rubyui.com) — use those components before hand-rolling markup.
- The only ERB left is `app/views/layouts/`.

Styling is TailwindCSS via `tailwindcss-rails`. `bin/dev` runs `tailwindcss:watch` (see `Procfile.dev`); build once with `bin/rails tailwindcss:build`. Source: `app/assets/tailwind/application.css` → output: `app/assets/builds/tailwind.css`.

## Code style

Rails code here should read as clean, simple, and self-explanatory. Lean on clear names and small methods instead of prose.

- **Do not litter the codebase with comments.** No comments that restate the code (`# find the user`), no section-divider banners, no commented-out code. They rot and add noise.
- Add a comment only when it explains *why* something non-obvious exists — a workaround, a business rule, an edge case — never *what* a line does.
- For documenting public classes/modules/methods, use proper **RDoc or YARD** doc comments (`# @param`, `# @return`, ...), not scattered inline remarks.
- Formatting follows rails-omakase (`bin/rubocop`) — don't hand-format against it.

## Testing

- Run: `bundle exec rspec` — single example: `bundle exec rspec spec/models/foo_spec.rb:42` (no `bin/rspec` binstub).
- FactoryBot for fixtures, **FFaker** for fake data (not `Faker` — the API differs).
- The `test` job in `.github/workflows/ci.yml` runs the suite against a Postgres service.

## Lint & full check

- `bin/rubocop` — style (rails-omakase via `rubocop-rails-omakase`).
- `bin/ci` — full local pipeline: RuboCop, bundler-audit, importmap audit, Brakeman. Run before opening a PR.

## Local development

- `docker compose -f docker/compose-dev.yaml up` — Postgres and Mailpit (web UI `localhost:8025`).
- `bin/setup` to bootstrap, `bin/dev` to run the server + CSS watcher (via `Procfile.dev`).
- `dotenv` loads `.env` (gitignored, `:development`/`:test` only) for local env vars.
- DB connection is ENV-driven: `config/database.yml` reads `DB_HOST` / `DB_PORT` / `DB_USERNAME` / `DB_PASSWORD` (local `.env` defaults the port to 5454; `default:` fallbacks target CI's 5432 service). `production` requires `DB_PASSWORD` with no fallback.

## Git

- Feature branch off `main`, then PR.
- Conventional Commit messages (`feat:`, `fix:`, `chore:` …).
