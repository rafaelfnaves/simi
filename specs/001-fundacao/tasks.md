---

description: "Task list for feature 001 — Fundação"
---

# Tasks: Fundação — Acesso, Navegação e Dashboard Inicial

**Input**: Design documents from `/specs/001-fundacao/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/routes.md](./contracts/routes.md)

**Tests**: obrigatórios. O Princípio III da constituição é inegociável — cada mudança de
comportamento entra com sua cobertura RSpec no mesmo change set. As tarefas de spec abaixo não são
opcionais.

**Organization**: agrupadas por história de usuário, para que cada uma seja implementada e testada de
forma independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência pendente)
- **[Story]**: a qual história pertence (US1..US4)
- Todo caminho de arquivo é explícito

## Path Conventions

Monólito Rails: `app/`, `db/`, `spec/` a partir da raiz. Páginas Phlex em `app/views/**/*.rb`,
componentes em `app/components/**/*.rb`, conforme `plan.md`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: trazer para o projeto o que o framework e a biblioteca de componentes já entregam.

- [ ] T001 Rodar `bin/rails generate authentication --no-template-engine` e conferir que nenhuma view foi criada em `app/views/sessions/` ou `app/views/passwords/`, que `bcrypt` foi descomentado no `Gemfile`, que `include Authentication` entrou em `app/controllers/application_controller.rb` e que as duas migrations nasceram em `db/migrate/`
- [ ] T002 Remover `app/views/passwords_mailer/reset.html.erb` e `app/views/passwords_mailer/reset.text.erb` — serão reescritos em Phlex na US2 (Princípio II)
- [ ] T003 Instalar os componentes do RubyUI com `bin/rails generate ruby_ui:component Button Input Form Card Avatar DropdownMenu Sheet Sidebar Separator Alert Badge Table Typography Link Select Empty ThemeToggle Tooltip` e conferir em `config/importmap.rb` se algum pin novo foi adicionado
- [ ] T004 [P] Declarar `SIMI_ALLOWED_SIGNUP_EMAILS` em `.env.example` e no `.env` local, com o endereço que será usado na validação manual

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: esquema, modelo, rotas e a moldura mínima das páginas. Nenhuma história pode começar
antes disto.

- [ ] T005 Criar a migration `AddProfileFieldsToUsers` em `db/migrate/` com `name` (não nulo), `confirmed_at`, `theme` (não nulo, padrão `"system"`), `time_zone` (não nulo, padrão `"America/Sao_Paulo"`) e `locale` (não nulo, padrão `"pt-BR"`), conforme [data-model.md](./data-model.md)
- [ ] T006 Estender `app/models/user.rb` com a validação de `name`, o mínimo de 8 caracteres na senha, a restrição de `theme` aos três valores, a validação de `time_zone`, `generates_token_for :email_confirmation, expires_in: 24.hours`, o predicado `confirmed?` e o método de classe que consulta `SIMI_ALLOWED_SIGNUP_EMAILS` via `ENV.fetch` com padrão (Princípio V)
- [ ] T007 [P] Escrever a factory em `spec/factories/users.rb` usando **FFaker**, com trait `:unconfirmed`
- [ ] T008 [P] Cobrir `app/models/user.rb` em `spec/models/user_spec.rb`: normalização e unicidade do e-mail, política de senha, valores aceitos de `theme`, geração e expiração do token de confirmação, e a lista de autorizados — incluindo o caso de lista vazia recusando todo cadastro
- [ ] T009 Escrever a tabela de rotas de `config/routes.rb` conforme [contracts/routes.md](./contracts/routes.md), com `root "dashboard#show"`, mantendo as duas rotas inseridas pelo generator
- [ ] T010 Reduzir `app/views/layouts/application.html.erb` ao esqueleto: `<body>` com apenas `yield`, classe de tema no `<html>` a partir da preferência da conta, e o script curto no `<head>` que resolve `prefers-color-scheme` quando a preferência é `system` (FR-030)
- [ ] T011 [P] Criar `app/components/flash_messages.rb` sobre `RubyUI::Alert`, exibindo `notice` e `alert`
- [ ] T012 Criar `app/components/auth_shell.rb` (moldura centrada, sem navegação) e `app/views/auth_base.rb` com o `around_template` correspondente
- [ ] T013 Criar `app/components/app_shell.rb` com a estrutura mínima autenticada e ajustar `app/views/base.rb` para envolvê-la em `around_template` — a navegação completa chega na US3
- [ ] T014 Criar `app/controllers/dashboard_controller.rb` com `#show` e `app/views/dashboard/show.rb` como página autenticada mínima — os sete blocos chegam na US3
- [ ] T015 [P] Cobrir o acesso protegido em `spec/requests/dashboard_spec.rb`: sem sessão redireciona para a entrada, com sessão responde `200`

---

## Phase 3: User Story 1 - Criar conta e entrar no SIMI (Priority: P1) 🎯 MVP

**Goal**: cadastrar com e-mail autorizado, confirmar pelo link recebido, entrar e sair.

**Independent Test**: cadastrar, abrir o link no Mailpit, sair e entrar de novo — sem depender de
nenhuma outra história.

### Tests for User Story 1

- [ ] T016 [P] [US1] Escrever `spec/requests/registrations_spec.rb`: cadastro aceito cria a conta e enfileira o e-mail; e-mail fora da lista autorizada não cria conta, não envia e-mail e responde igual ao caso de sucesso; e-mail já cadastrado não duplica nem revela a existência (FR-009a)
- [ ] T017 [P] [US1] Escrever `spec/requests/confirmations_spec.rb`: link válido confirma e abre sessão; link expirado é recusado; link já usado não altera a conta; o reenvio responde de forma genérica
- [ ] T018 [P] [US1] Escrever `spec/requests/sessions_spec.rb`: entrada com credenciais corretas; senha errada com mensagem que não revela o e-mail; conta não confirmada não abre sessão (FR-008); saída encerra a sessão; retorno ao endereço originalmente pedido (FR-016)
- [ ] T019 [P] [US1] Escrever `spec/mailers/user_mailer_spec.rb`: destinatário, assunto, presença do link de confirmação, existência das partes HTML e texto, e ausência de senha no corpo (FR-035)

### Implementation for User Story 1

- [ ] T020 [US1] Criar `app/mailers/user_mailer.rb` com `#confirmation`, montando a parte HTML por classe Phlex e a parte texto como string Ruby, sem template (`research.md` R3)
- [ ] T021 [P] [US1] Criar `app/views/mailers/user_mailer/confirmation.rb` com o corpo HTML do e-mail de confirmação
- [ ] T022 [US1] Criar `app/controllers/registrations_controller.rb` com `#new` e `#create`, `allow_unauthenticated_access`, `params.expect`, e a resposta indistinguível para e-mail já cadastrado ou fora da lista
- [ ] T023 [P] [US1] Criar `app/views/registrations/new.rb` sobre `Views::AuthBase`, com `RubyUI::Form` e `RubyUI::Input`
- [ ] T024 [US1] Criar `app/controllers/confirmations_controller.rb` com `#show`, `#new` e `#create`, consumindo `User.find_by_token_for(:email_confirmation, ...)`, marcando `confirmed_at` e abrindo a sessão
- [ ] T025 [P] [US1] Criar `app/views/confirmations/new.rb` com o formulário de reenvio do link
- [ ] T026 [US1] Estender `app/controllers/sessions_controller.rb` para recusar contas não confirmadas, direcionando ao reenvio, e criar `app/views/sessions/new.rb`
- [ ] T027 [US1] Criar `app/components/user_menu.rb` sobre `RubyUI::DropdownMenu` e `RubyUI::Avatar`, com o nome da pessoa, o acesso ao perfil e a saída, e ligá-lo ao `app/components/app_shell.rb`

**Checkpoint**: o fluxo completo de acesso funciona de ponta a ponta e a suíte está verde.

---

## Phase 4: User Story 2 - Recuperar o acesso (Priority: P2)

**Goal**: redefinir a senha por link enviado ao e-mail.

**Independent Test**: pedir a redefinição, abrir o link no Mailpit, definir uma senha nova e entrar
com ela.

### Tests for User Story 2

- [ ] T028 [P] [US2] Escrever `spec/requests/passwords_spec.rb`: pedido com e-mail existente envia o link; e-mail inexistente responde igual e não envia nada (FR-018); link válido redefine a senha; link expirado ou já usado é recusado; o link deixa de valer assim que a senha muda (FR-020)
- [ ] T029 [P] [US2] Escrever `spec/mailers/passwords_mailer_spec.rb`: destinatário, assunto, presença do link e ausência de senha no corpo

### Implementation for User Story 2

- [ ] T030 [US2] Ajustar `app/mailers/passwords_mailer.rb` para renderizar a parte HTML por Phlex e montar a parte texto como string, no mesmo padrão do `UserMailer`
- [ ] T031 [P] [US2] Criar `app/views/mailers/passwords_mailer/reset.rb` com o corpo HTML do e-mail de redefinição
- [ ] T032 [P] [US2] Criar `app/views/passwords/new.rb` com o formulário de solicitação
- [ ] T033 [P] [US2] Criar `app/views/passwords/edit.rb` com o formulário de nova senha

**Checkpoint**: quem perde a senha volta sozinho, e nenhuma resposta revela quais e-mails existem.

---

## Phase 5: User Story 3 - Enxergar a estrutura da vida financeira (Priority: P3)

**Goal**: navegação principal e os sete blocos do dashboard em estado vazio.

**Independent Test**: entrar com uma conta sem lançamentos e conferir os sete blocos, a navegação e o
comportamento em 360 px.

### Tests for User Story 3

- [ ] T034 [P] [US3] Escrever `spec/components/money_spec.rb`: formatação em Real brasileiro, incluindo zero e valores negativos (FR-024)
- [ ] T035 [P] [US3] Escrever `spec/components/main_nav_spec.rb`: as seis áreas aparecem, a atual é destacada e as da Fase 2 são marcadas como indisponíveis e não clicáveis (FR-021)
- [ ] T036 [P] [US3] Escrever `spec/components/stat_card_spec.rb`: rótulo e valor renderizados
- [ ] T037 [US3] Estender `spec/requests/dashboard_spec.rb` para exigir os sete blocos e seus estados vazios, sem valores fictícios (FR-022, FR-023)

### Implementation for User Story 3

- [ ] T038 [P] [US3] Criar `app/components/money.rb` como o único ponto de formatação monetária do produto
- [ ] T039 [P] [US3] Criar `app/components/page_header.rb` com título e espaço para ações
- [ ] T040 [P] [US3] Criar `app/components/stat_card.rb` sobre `RubyUI::Card`
- [ ] T041 [US3] Criar `app/components/main_nav.rb` sobre os componentes `RubyUI::Sidebar`, com as seis áreas e a marcação de indisponível
- [ ] T042 [US3] Ampliar `app/components/app_shell.rb` para a moldura definitiva: barra lateral colapsável, versão em `Sheet` no celular, topbar com gatilho, menu do usuário e alternador de tema
- [ ] T043 [US3] Montar os sete blocos em `app/views/dashboard/show.rb`, usando `Components::StatCard` nas três métricas e `RubyUI::Empty` nos quatro blocos restantes, na ordem definida em [contracts/routes.md](./contracts/routes.md)

**Checkpoint**: a casca do produto está de pé e a Fase 2 só precisará trocar a fonte de dados.

---

## Phase 6: User Story 4 - Ajustar perfil e aparência (Priority: P4)

**Goal**: editar nome e fuso horário, e escolher entre tema claro, escuro e o do sistema.

**Independent Test**: alterar nome e tema, recarregar, e entrar de outro navegador para confirmar que
as preferências acompanharam a conta.

### Tests for User Story 4

- [ ] T044 [P] [US4] Escrever `spec/requests/settings_spec.rb`: o perfil edita apenas `Current.user` e nunca aceita um id vindo do navegador (FR-034); nome e fuso são salvos; `email_address` é rejeitado como parâmetro; a troca de tema persiste na conta e os três valores são aceitos

### Implementation for User Story 4

- [ ] T045 [US4] Criar `app/controllers/settings/profiles_controller.rb` com `#show` e `#update`, operando sobre `Current.user` e com `params.expect` restrito a nome, fuso e tema
- [ ] T046 [P] [US4] Criar `app/views/settings/profiles/show.rb` com o formulário de perfil, o e-mail apenas em leitura e o caminho para a troca de senha
- [ ] T047 [US4] Criar `app/controllers/settings/themes_controller.rb` com `#update`, persistindo a preferência e voltando à página de origem
- [ ] T048 [US4] Criar `app/components/theme_switcher.rb` reaproveitando `RubyUI::ThemeToggle` como gatilho e enviando a mudança ao servidor, e `app/javascript/controllers/theme_controller.js` para virar a classe do `<html>` na hora (`research.md` R7)

**Checkpoint**: as quatro histórias da spec estão entregues.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T049 Rodar `bin/rubocop -a` e revisar o que a correção automática mudou
- [ ] T050 Rodar `bin/brakeman` e corrigir cada achado, sem suprimir (Princípio VI)
- [ ] T051 Conferir que nenhum `.erb` existe fora de `app/views/layouts/` e que nenhum controller usa `User.find(params[:id])`
- [ ] T052 Executar `bin/ci` inteiro e exigir verde
- [ ] T053 Percorrer os onze passos da validação manual em [quickstart.md](./quickstart.md), incluindo a checagem em 360 px e a inspeção do `log/development.log`
- [ ] T054 Documentar em `.env.example` e no `README.md` a variável `SIMI_ALLOWED_SIGNUP_EMAILS` e o que acontece quando ela está vazia

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)
   └─> Phase 2 (Foundational)  ← bloqueia todas as histórias
          ├─> Phase 3 (US1, P1)  ← MVP
          ├─> Phase 4 (US2, P2)
          ├─> Phase 5 (US3, P3)
          └─> Phase 6 (US4, P4)
                 └─> Phase 7 (Polish)
```

### User Story Dependencies

- **US1** depende apenas da Fase 2.
- **US2** depende da Fase 2 e reaproveita o `UserMailer` da US1 como referência de padrão; pode ser
  feita antes da US1, ao custo de definir o padrão de mailer ali.
- **US3** depende da Fase 2. É independente da US1 e da US2 — os specs de dashboard criam a sessão
  diretamente pela factory.
- **US4** depende da Fase 2 e do `app_shell` da US3 para o alternador no topo, mas a página de perfil
  em si é independente.

### Within Each User Story

Specs primeiro, depois mailer, controller e páginas. As páginas Phlex de uma mesma história não se
tocam e são paralelizáveis entre si.

### Parallel Opportunities

- Fase 2: T007, T008, T011 e T015 em paralelo.
- US1: os quatro specs T016–T019 em paralelo; depois T021, T023 e T025 em paralelo.
- US2: T028 e T029 em paralelo; depois T031, T032 e T033 em paralelo.
- US3: T034–T036 em paralelo; depois T038, T039 e T040 em paralelo, antes de T041.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

Fases 1, 2 e 3 entregam um produto utilizável: uma conta autorizada se cadastra, confirma, entra e
sai, e encontra uma área privada. É o menor recorte que tem valor por si.

### Incremental Delivery

Cada fase seguinte fecha uma história inteira, com a suíte verde e `bin/ci` passando. US2 remove a
dependência de suporte para senha esquecida; US3 entrega a casca que a Fase 2 do roadmap vai
preencher; US4 encerra o item "Configurações" do PRD §9.

### Notes

- 54 tarefas: 4 de setup, 11 de fundação, 12 na US1, 6 na US2, 10 na US3, 5 na US4 e 6 de polimento.
- Specs e implementação da mesma história pertencem ao mesmo commit sempre que possível
  (Princípio III).
- Mensagens de commit em Conventional Commits; a entrega vai para `main` por pull request.
