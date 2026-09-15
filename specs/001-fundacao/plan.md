# Implementation Plan: Fundação — Acesso, Navegação e Dashboard Inicial

**Branch**: `001-fundacao` | **Date**: 2026-09-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-fundacao/spec.md`

## Summary

Sair de um scaffold sem domínio para uma aplicação autenticada e navegável. O generator nativo de
autenticação do Rails 8.1 fornece o núcleo — `User`, `Session`, `Current`, o concern `Authentication`,
o fluxo de senha e o token de redefinição — e esta feature o estende com três coisas que ele não
cobre: cadastro restrito por lista de endereços autorizados, confirmação de e-mail por link, e
preferências de conta (nome, fuso, tema).

Toda a interface é escrita em Phlex sobre os componentes do RubyUI, que já entrega `Sidebar`, `Empty`
e `ThemeToggle`. O dashboard nasce com os sete blocos do PRD §9 em estado vazio, de modo que a Fase 2
troque a fonte de dados sem redesenhar a página.

## Technical Context

**Language/Version**: Ruby 4.0.6

**Primary Dependencies**: Rails 8.1.3.1, phlex-rails 2.4 + ruby_ui 1.6, tailwindcss-rails 4.6 +
tailwind_merge, importmap-rails com turbo-rails e stimulus-rails, solid_queue/solid_cache/solid_cable,
resend, sentry-rails. **bcrypt** é a única gem nova, descomentada pelo próprio generator.

**Storage**: PostgreSQL 18 (imagem `pgvector/pgvector:pg18`). A extensão `vector` existe na imagem mas
não é habilitada nesta feature — pertence à Fase 2.

**Testing**: RSpec 8 + FactoryBot + FFaker. Specs de componente renderizam por um view context Rails
real, via o harness em `spec/support/phlex.rb`.

**Target Platform**: aplicação web servida por Puma atrás de Thruster, publicada com Kamal. Navegadores
modernos, conforme o `allow_browser versions: :modern` já presente em `ApplicationController`.

**Project Type**: monólito Rails com renderização no servidor. Sem build de Node, sem SPA.

**Performance Goals**: sem meta numérica própria — o volume desta fase é de um punhado de contas e
nenhum dado financeiro. A restrição real é a ausência de flash de tema (FR-030), que exige a decisão
de tema no servidor, e não uma meta de throughput.

**Constraints**: sem Node, sem Redis (Princípio V); nenhum `.erb` novo fora de `app/views/layouts/`
(Princípio II); interface utilizável a partir de 360 px; e-mails e tokens fora de logs e do Sentry
(Princípio VI).

**Scale/Scope**: uso individual; cerca de 10 telas e 8 controllers nesta entrega.

## Constitution Check

*GATE: verificado antes da Fase 0 e revisto após a Fase 1.*

| Princípio | Avaliação | Situação |
|---|---|---|
| I. Rails Omakase | Toda a lógica cabe em models, controllers e mailers. Nenhum service object é necessário: a autorização de cadastro é um método de classe em `User`, e o dashboard é montado por um objeto de apresentação simples. `params.expect` em todo controller. | **Passa** |
| II. Phlex, nunca ERB | Generator rodado com `--no-template-engine` para não criar as três views ERB. As duas views ERB do `PasswordsMailer` são removidas e reescritas em Phlex, com a parte texto montada no mailer. Único ERB remanescente: `app/views/layouts/`. Componentes do RubyUI usados antes de qualquer markup próprio. | **Passa com desvio registrado** (ver Complexity Tracking) |
| III. Specs junto do código | Cada uma das quatro histórias entra com specs de modelo, request, mailer e componente no mesmo change set. FFaker, nunca Faker. | **Passa** |
| IV. Código autoexplicativo | Sem comentários de narração. O código gerado pelo Rails entra como está; onde for editado, o comentário só permanece se explicar um *porquê*. | **Passa** |
| V. Uma stack sem graça | `bcrypt` é a única gem nova, exigida por `has_secure_password` e descomentada pelo próprio generator — não muda a superfície de runtime. Nenhum Redis, nenhum Node, nenhum pacote novo no importmap além do que os componentes do RubyUI exigirem. | **Passa** |
| VI. Dado financeiro é privado | Nenhum dado financeiro existe ainda, mas a regra estrutural é estabelecida agora: toda leitura parte de `Current.user`, nunca de um id vindo do navegador. Filtros de log e o endurecimento do Sentry já foram aplicados antes desta feature. Achados do Brakeman são corrigidos, não silenciados. | **Passa** |

**Revisão pós-Fase 1**: o desenho não introduziu camadas, gems ou datastores além do previsto. Os
gates seguem verdes.

## Project Structure

### Documentation (this feature)

```text
specs/001-fundacao/
├── plan.md              # Este arquivo
├── spec.md              # Especificação aprovada
├── research.md          # Fase 0 — decisões verificadas contra as gems instaladas
├── data-model.md        # Fase 1 — users e sessions
├── quickstart.md        # Fase 1 — como validar a entrega de ponta a ponta
├── contracts/
│   └── routes.md        # Fase 1 — rotas, parâmetros e e-mails
├── checklists/
│   └── requirements.md  # Checklist de qualidade da spec
└── tasks.md             # Fase 2 — gerado por /speckit-tasks
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── application_controller.rb        # recebe include Authentication
│   ├── concerns/authentication.rb       # gerado
│   ├── sessions_controller.rb           # gerado, estendido: exige conta confirmada
│   ├── passwords_controller.rb          # gerado
│   ├── registrations_controller.rb
│   ├── confirmations_controller.rb
│   ├── dashboard_controller.rb
│   └── settings/
│       ├── profiles_controller.rb
│       └── themes_controller.rb
├── models/
│   ├── user.rb                          # gerado, estendido
│   ├── session.rb                       # gerado
│   └── current.rb                       # gerado
├── mailers/
│   ├── user_mailer.rb
│   └── passwords_mailer.rb              # gerado
├── components/
│   ├── app_shell.rb                     # moldura autenticada sobre RubyUI::Sidebar
│   ├── auth_shell.rb                    # moldura centrada das telas de acesso
│   ├── main_nav.rb
│   ├── user_menu.rb
│   ├── theme_switcher.rb
│   ├── page_header.rb
│   ├── stat_card.rb
│   ├── money.rb
│   ├── flash_messages.rb
│   └── ruby_ui/                          # componentes instalados pelo generator
├── views/
│   ├── base.rb                          # ganha around_template com o AppShell
│   ├── auth_base.rb
│   ├── dashboard/show.rb
│   ├── sessions/new.rb
│   ├── registrations/new.rb
│   ├── confirmations/new.rb
│   ├── passwords/{new,edit}.rb
│   ├── settings/profiles/show.rb
│   ├── mailers/user_mailer/confirmation.rb
│   ├── mailers/passwords_mailer/reset.rb
│   └── layouts/application.html.erb      # único ERB, reduzido a esqueleto
└── javascript/controllers/
    └── theme_controller.js

db/migrate/                               # CreateUsers, CreateSessions, AddProfileFieldsToUsers
spec/
├── factories/users.rb
├── models/user_spec.rb
├── requests/{sessions,registrations,confirmations,passwords,dashboard,settings}_spec.rb
├── mailers/{user_mailer,passwords_mailer}_spec.rb
└── components/{app_shell,main_nav,stat_card,money}_spec.rb
```

**Structure Decision**: monólito Rails padrão, sem subprojetos. As páginas ficam em `app/views/**/*.rb`
como classes Phlex e os componentes reutilizáveis em `app/components/**/*.rb`, exatamente como o
Princípio II exige e como os inicializadores `config/initializers/{phlex,ruby_ui}.rb` já configuram o
autoload. Os controllers de configuração ficam sob o namespace `Settings`, deixando espaço para os
demais itens de Configurações do PRD §9.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `Components::ThemeSwitcher` e `theme_controller.js` próprios, em vez de usar apenas `RubyUI::ThemeToggle` | A spec pede três estados de tema (claro, escuro, sistema — FR-028) e persistência vinculada à conta, válida em qualquer dispositivo (FR-029). O componente do RubyUI alterna dois estados e grava em `localStorage`. | Usar o componente como está deixaria a preferência presa ao navegador, quebrando FR-029 justamente no caso de uso real do produto — a mesma pessoa no celular e no computador. O componente do RubyUI continua sendo reaproveitado como o botão do topo; o que se acrescenta é a persistência no servidor e o terceiro estado. |
| Corpo de e-mail em texto montado como string Ruby no mailer | O Princípio II proíbe `.erb` novo, e Phlex não gera `text/plain`. | Um e-mail só HTML seria mais simples, mas provedores penalizam mensagens sem alternativa em texto, e a spec depende de os links de confirmação e redefinição efetivamente chegarem. |
