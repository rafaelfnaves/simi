<!--
SYNC IMPACT REPORT
==================
Version change: [unversioned template] → 1.0.0
Bump rationale: Initial ratification. The document moved from an unfilled scaffold to a
concrete governance charter, defining six principles and two supporting sections.

Modified principles (placeholder → concrete):
- [PRINCIPLE_1_NAME] → I. Rails Omakase, Convention Over Configuration
- [PRINCIPLE_2_NAME] → II. Phlex Views, Never ERB
- [PRINCIPLE_3_NAME] → III. Specs Ship With The Code (NON-NEGOTIABLE)
- [PRINCIPLE_4_NAME] → IV. Self-Explanatory Code, Not Commented Code
- [PRINCIPLE_5_NAME] → V. One Boring Stack (Postgres-Backed, No Node, No Redis)
- (added) → VI. Financial Data Is Private By Default

Added sections:
- Technology Constraints (was [SECTION_2_NAME])
- Development Workflow & Quality Gates (was [SECTION_3_NAME])
- Governance (rules filled in)

Removed sections: none.

Follow-up TODOs: none. All placeholders resolved.
-->

# SIMI Constitution

SIMI is a personal finance management platform. Product context lives in `docs/PRD.md`
(Portuguese); day-to-day engineering guidance lives in `CLAUDE.md`. This constitution
governs both.

## Core Principles

### I. Rails Omakase, Convention Over Configuration

The framework's defaults are the design. Code MUST follow Rails naming, layout, and
lifecycle conventions before reaching for an abstraction. Business logic MUST live where
Rails expects it: models for domain rules and validations, controllers for HTTP concerns
with strong parameters (`params.expect`), jobs for background work, and service objects in
`app/services/` only when logic outgrows a focused model method. Controllers MUST stay thin;
models MUST stay focused. Patterns imported from other ecosystems (repositories, generic
managers, ceremony layers) MUST NOT be introduced without a documented reason that Rails
cannot already serve.

**Rationale:** A single-developer product survives on predictability. Convention means any
file's purpose is inferable from its path, and future contributors — human or agent — do not
have to learn a bespoke architecture before making a change.

### II. Phlex Views, Never ERB

Views and components are Ruby classes, not templates. Pages MUST live in `app/views/**/*.rb`
and subclass `Views::Base`; reusable components MUST live in `app/components/**/*.rb` and
subclass `Components::Base`. New `.erb` files MUST NOT be added — the only permitted ERB is
`app/views/layouts/`. Before hand-rolling markup, the RubyUI components mixed into
`Components::Base` MUST be checked first and used when one fits. Styling MUST be TailwindCSS
utility classes compiled by `tailwindcss-rails`; ad-hoc CSS files and inline `style`
attributes MUST NOT be introduced. Class-conflict resolution goes through `tailwind_merge`.

**Rationale:** Views as plain Ruby are testable, refactorable, and type-checkable by the same
tools as the rest of the app, and a shared component library keeps a minimalist interface
consistent without a design system living in a separate language.

### III. Specs Ship With The Code (NON-NEGOTIABLE)

Every behavioral change MUST arrive with RSpec coverage in the same change set. Tests MUST use
RSpec (`bundle exec rspec` — there is no `bin/rspec` binstub), FactoryBot for fixtures, and
**FFaker** for fake data. `Faker` MUST NOT be used; its API differs and mixing the two breaks
factories. Bug fixes MUST add a spec that fails before the fix. A change MUST NOT be merged
with a red suite, and specs MUST NOT be skipped, pending, or deleted to make CI green.

**Rationale:** This system computes money. A wrong balance, a duplicated import, or a
mis-categorized transaction is a silent failure the user only discovers by losing trust in the
numbers — the suite is the only thing that catches that before they do.

### IV. Self-Explanatory Code, Not Commented Code

Code MUST read as clean, simple, and self-explanatory through clear names and small methods.
Comments that restate the code, section-divider banners, and commented-out code MUST NOT be
committed. A comment is permitted only when it explains *why* something non-obvious exists —
a workaround, a business rule, an edge case. Public classes, modules, and methods that need
documentation MUST use proper RDoc or YARD doc comments (`# @param`, `# @return`), not
scattered inline remarks. Formatting MUST follow rails-omakase via `bin/rubocop`; code MUST
NOT be hand-formatted against it.

**Rationale:** Comments rot while code moves. Prose that duplicates the implementation becomes
a second, silently wrong source of truth; a good method name never does.

### V. One Boring Stack (Postgres-Backed, No Node, No Redis)

The runtime surface stays deliberately small. Background jobs, cache, and cable MUST use
`solid_queue`, `solid_cache`, and `solid_cable` on PostgreSQL — Redis and Sidekiq MUST NOT be
added. JavaScript MUST be delivered through importmap with Hotwire (`turbo-rails`,
`stimulus-rails`); a Node build step, bundler, or `package.json` MUST NOT be introduced. Assets
go through propshaft. Configuration MUST be environment-driven: development and test read the
`DB_*` variables with fallbacks, while production takes a full URL per connection
(`DATABASE_URL`, `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, `CABLE_DATABASE_URL`) supplied by
Kamal. Because `bin/rails db:prepare` renders `config/database.yml` in every environment, the
production ERB MUST stay non-raising (no bare `ENV.fetch` without a default or block).
Credentials and secrets MUST NOT be committed.

**Rationale:** Every additional service is another thing to run locally, secure, monitor, and
pay for. One database and one process model is what makes a solo-operated product deployable
with Kamal to a single machine.

### VI. Financial Data Is Private By Default

Every record that belongs to a user MUST be scoped to that user at query time; a controller or
query MUST NOT reach financial data through an unscoped lookup on a client-supplied id.
Transaction amounts, descriptions, statement contents, and account identifiers MUST NOT be
written to logs, Sentry events, or error messages. Imported statements and any derived
artifacts MUST NOT be sent to third-party services unless the PRD explicitly scopes that
integration. Brakeman findings MUST be fixed rather than suppressed, unless the suppression
carries a written justification.

**Rationale:** Privacy is a stated product principle in `docs/PRD.md`, and a bank statement is
among the most sensitive documents a person owns. Leakage here is not a bug to be patched
later — it is unrecoverable.

## Technology Constraints

The pinned stack is Ruby 4.0.6, Rails 8.1, and PostgreSQL 18. Views use Phlex and RubyUI;
styling uses TailwindCSS. Mail goes through Mailpit locally and Resend in production. Error
tracking is Sentry. Deployment is Kamal 2 with the Rails-generated `Dockerfile` and `thruster`.
Local services (PostgreSQL, Mailpit) run via `docker compose -f docker/compose-dev.yaml up`;
`dotenv` loads a gitignored `.env` in development and test only.

Adding a gem or an external service is an amendment-level decision when it changes the runtime
surface (a new datastore, a new background processor, a new build toolchain). Library additions
that stay inside the existing surface MUST still be justified in the pull request: what it
does, why the framework cannot, and what it costs to remove later.

Database changes MUST index foreign keys and any column used in a `WHERE` clause. Migrations
MUST be reversible or state explicitly why they are not.

## Development Workflow & Quality Gates

Work starts on a feature branch off `main` and lands through a pull request. Commit messages
MUST follow Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`).

Before opening a pull request, `bin/ci` MUST pass locally — it runs setup, RuboCop,
bundler-audit, importmap audit, and Brakeman. `bundle exec rspec` MUST pass. GitHub Actions
re-runs the security scans, the RSpec suite against a PostgreSQL service, and the linter; all
jobs MUST be green before merge.

A pull request MUST NOT be merged while it disables a lint rule, a security check, or a spec in
order to pass. If a gate is wrong, the gate is changed deliberately in its own commit with the
reason recorded.

## Governance

This constitution supersedes other practices, conventions, and habits in this repository. Where
`CLAUDE.md`, `.claude-on-rails/prompts/`, generated scaffolding, or an agent's default behavior
disagrees with it, this document wins.

Amendments MUST be made by editing this file in a dedicated commit that states the rationale and
bumps the version. Versioning follows semantic versioning:

- **MAJOR** — a principle is removed or redefined in a way that invalidates existing code or
  process.
- **MINOR** — a principle or section is added, or existing guidance is materially expanded.
- **PATCH** — clarification, wording, or typo fixes that do not change what is required.

Compliance is verified at review time: every pull request MUST be checked against these
principles, and any deviation MUST be justified in the pull request description or corrected
before merge. Complexity that violates a principle is permitted only with a written
justification of why the simpler, compliant approach fails.

`CLAUDE.md` remains the operational guide for runtime development commands and day-to-day
conventions; it MUST be kept consistent with this constitution when either changes.

**Version**: 1.0.0 | **Ratified**: 2026-09-09 | **Last Amended**: 2026-09-09
