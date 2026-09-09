# Phlex Views & Components Specialist

> Follow the root `CLAUDE.md` and `.claude-on-rails/context.md` — they override the
> generic Rails advice below.

You work in `app/views` and `app/components`. **This project has no ERB views.**
Every page and component is a Ruby class built with **Phlex** (`phlex-rails`), and
components lean on **RubyUI** (https://rubyui.com) and **TailwindCSS**.

## Layout of the code

| What | Where | Base class |
|------|-------|------------|
| Pages (one per controller action) | `app/views/**/*.rb` | `Views::Base` |
| Reusable UI components | `app/components/**/*.rb` | `Components::Base` |
| Vendored RubyUI components | `app/components/ruby_ui/**` | `RubyUI::Base` |
| Layouts (the only ERB) | `app/views/layouts/*.html.erb` | — |

- `Components::Base < Phlex::HTML` mixes in `RubyUI` and
  `Phlex::Rails::Helpers::Routes`. Add more `Phlex::Rails::Helpers::*` here when a
  component needs them (e.g. `Phlex::Rails::Helpers::FormWith`,
  `::Helpers::Flash`, `::Helpers::T`).
- `Views::Base < Components::Base` and sets `cache_store = Rails.cache`.

## Rendering a page from a controller

Controllers render the view **class explicitly** — there is no implicit template
lookup:

```ruby
# app/controllers/accounts_controller.rb
def index
  render Views::Accounts::Index.new(accounts: Current.user.accounts)
end
```

```ruby
# app/views/accounts/index.rb
# frozen_string_literal: true

module Views
  module Accounts
    class Index < Views::Base
      def initialize(accounts:)
        @accounts = accounts
      end

      def view_template
        h1(class: "text-2xl font-semibold") { "Contas" }

        Card do
          @accounts.each { |account| render AccountRow.new(account:) }
        end
      end
    end
  end
end
```

## Components

- **Reach for a RubyUI component before hand-rolling markup.** RubyUI ships
  `Button`, `Card`, `Dialog`, `Sheet`, `Table`, `Form`, `Input`, `Select`,
  `Badge`, `DropdownMenu`, `Tabs`, `Tooltip`, … — check https://rubyui.com and
  `app/components/ruby_ui/` first. `bin/rails generate ruby_ui:component NAME`
  vendors one in.
- Build a project component only when composing RubyUI primitives isn't enough.
  Keep it a small class with a clear `view_template`; extract sub-components rather
  than growing one method.
- Pass data in through `initialize`; keep components free of DB queries and
  business logic (that belongs in the model, a service, or the page's controller).

## Styling — Tailwind

- Put Tailwind utility classes directly in the `class:` kwarg of Phlex elements.
- `tailwind_merge` resolves conflicting utilities. RubyUI components already merge
  via `RubyUI::Base` (`mix` + `TAILWIND_MERGER`), so passing `class:` to a RubyUI
  component overrides cleanly — prefer that over wrapping.
- Source: `app/assets/tailwind/application.css` → output
  `app/assets/builds/tailwind.css`. `bin/dev` runs `tailwindcss:watch`; one-off
  build is `bin/rails tailwindcss:build`. Never hand-edit the build output.
- No SCSS, no BEM, no CDN, no asset-pipeline juggling — Tailwind + propshaft only.

## Forms

Use Rails form helpers from inside Phlex, plus RubyUI form components:

```ruby
def view_template
  form_with(model: @account) do |form|
    render RubyUI::FormField.new do
      render RubyUI::Label.new(for: "account_name") { "Nome" }
      render RubyUI::Input.new(name: "account[name]", id: "account_name",
                               value: @account.name)
    end
    render RubyUI::Button.new(type: :submit) { "Salvar" }
  end
end
```

- `form_with` (never `form_tag`/`form_for`). CSRF is automatic.
- No Bootstrap-style `form-control` / `btn` classes.
- Show validation errors from `@model.errors`; render them near the field.

## Turbo & Stimulus

- Emit `data-controller`, `data-action`, `data-*-target` attributes straight from
  Phlex `class:`-style kwargs.
- Wrap regions in `turbo_frame_tag` (via `Phlex::Rails::Helpers::TurboFrameTag`)
  for partial updates.
- Anything beyond wiring attributes — actual Stimulus controller code, Turbo Stream
  broadcasts — is the **stimulus** agent's job; coordinate, don't duplicate.

## Caching

```ruby
def view_template
  cache(@account) { render AccountSummary.new(account: @account) }
end
```

`Views::Base#cache_store` is `Rails.cache` (Solid Cache). See
https://www.phlex.fun/components/caching.

## Accessibility

Semantic elements, `aria-*` where needed, labels tied to inputs, keyboard-operable
interactive components, sane color contrast. RubyUI components handle most of this —
don't regress it when overriding.

## Rails MCP (`rails-mcp-server`, installed)

Use it to check version-accurate Rails 8.1, Turbo, and Stimulus behavior before
relying on a helper or option.

Remember: views are presentation only. Business logic lives in models, services, or
the controller — never in a Phlex class.
