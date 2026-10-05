---

description: "Task list for feature 002 — Contas e Categorias"
---

# Tasks: Contas e Categorias — Cadastros do Núcleo Financeiro

**Input**: Design documents from `/specs/002-contas-categorias/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [contracts/routes.md](./contracts/routes.md)

**Tests**: obrigatórios. O Princípio III da constituição é inegociável — cada mudança de
comportamento entra com sua cobertura RSpec no mesmo change set. As tarefas de spec abaixo não são
opcionais.

**Organization**: agrupadas por história de usuário, para que cada uma seja implementada e testada de
forma independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência pendente)
- **[Story]**: a qual história pertence (US1..US3)
- Todo caminho de arquivo é explícito

## Path Conventions

Monólito Rails: `app/`, `db/`, `spec/` a partir da raiz. Páginas Phlex em `app/views/**/*.rb`,
componentes em `app/components/**/*.rb`, subclasses STI em `app/models/accounts/`, conforme
`plan.md`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: as duas peças de infraestrutura que todas as histórias usam e que não dependem de
esquema.

- [ ] T001 Criar `app/types/money_type.rb` como subclasse de `ActiveRecord::Type::Decimal`, convertendo `"1.234,56"` e `"1234.56"` para `BigDecimal` e preservando sinal negativo e `nil`, com doc YARD em `#cast` ([research.md](./research.md) D4)
- [ ] T002 [P] Cobrir o tipo em `spec/types/money_type_spec.rb`: formato brasileiro com e sem separador de milhar, formato com ponto decimal, valor negativo, string vazia, `nil` e entrada não numérica
- [ ] T003 [P] Criar `app/components/icon.rb` com `CATALOG` — cerca de catorze SVGs inline (casa, refeição, carro, saúde, educação, lazer, compras, recibo, viagem, trabalho, presente, cofre, carteira e um genérico), no mesmo padrão de SVG inline já usado em `app/components/ruby_ui/empty/empty_media.rb` ([research.md](./research.md) D5)
- [ ] T004 [P] Cobrir em `spec/components/icon_spec.rb` que cada token do catálogo renderiza um `<svg>` com `aria-hidden` e que um token desconhecido é recusado em vez de renderizar vazio

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: esquema, modelos e rotas. Nenhuma história pode começar antes disto.

- [ ] T005 Criar a migration `CreateAccounts` em `db/migrate/` com `user_id` (FK, `on_delete: :cascade`), `type`, `name`, `institution`, `balance` (`decimal` 15,2, não nulo, padrão 0) e `archived_at`; índice `(user_id, type, archived_at)` e índice **único parcial** sobre `(user_id, lower(name))` com `where: "archived_at IS NULL"`, conforme [data-model.md](./data-model.md)
- [ ] T006 Criar a migration `CreateCategories` em `db/migrate/` com `user_id` (FK, cascade), `parent_id` (FK para `categories`), `name`, `nature`, `color`, `icon` e `archived_at`; índices `(user_id, nature, archived_at)` e `(parent_id)`, mais índice **único parcial** sobre `(user_id, parent_id, lower(name))` com `where: "archived_at IS NULL"` e `nulls_not_distinct: true` ([research.md](./research.md) D6)
- [ ] T007 Criar `app/models/account.rb` como raiz STI: `belongs_to :user`, `normalizes :name`, `attribute :balance, MoneyType.new`, validações de `name` e `balance`, restrição de `type` às subclasses registradas, unicidade de `name` entre as ativas, scopes `active`/`archived`, `#archive!`/`#unarchive!` e o mapa `KINDS` que traduz token de formulário em subclasse
- [ ] T008 [P] Criar `app/models/accounts/deposit.rb` e as quatro folhas `checking.rb`, `savings.rb`, `wallet.rb` e `cash.rb` em `app/models/accounts/`, com `Accounts::Cash` validando que `institution` fique em branco
- [ ] T009 Criar `app/models/category.rb`: enum `nature`, `belongs_to :parent` opcional e `has_many :subcategories`, validação de profundidade máxima dois, herança da natureza do pai antes da validação, imutabilidade da natureza após a criação, unicidade entre irmãs ativas, `#archive!` em cascata dentro de uma transação, as constantes `COLORS` (classes utilitárias **literais**) e `SUGGESTED`, e `.create_suggested_for(user)` idempotente com doc YARD
- [ ] T010 [P] Acrescentar `has_many :accounts, dependent: :destroy` e `has_many :categories, dependent: :destroy` em `app/models/user.rb`
- [ ] T011 [P] Escrever `spec/factories/accounts.rb` com **FFaker**, uma factory por subclasse de depósito e traits `:archived` e `:negative`
- [ ] T012 [P] Escrever `spec/factories/categories.rb` com **FFaker** e traits `:income`, `:archived` e `:subcategory`
- [ ] T013 [P] Cobrir `app/models/account.rb` em `spec/models/account_spec.rb`: validações, conversão do saldo pelo `MoneyType`, saldo negativo aceito, unicidade apenas entre ativas (incluindo grafia diferente e o invariante no índice sob inserção concorrente), `Accounts::Cash` recusando instituição, scopes, arquivar e reativar preservando o saldo
- [ ] T014 [P] Cobrir `app/models/category.rb` em `spec/models/category_spec.rb`: natureza herdada do pai, profundidade máxima dois, duas raízes homônimas recusadas pelo índice, natureza imutável, arquivamento em cascata, exclusão bloqueada com subcategoria viva, e `create_suggested_for` criando a árvore e sendo idempotente sem reviver arquivadas
- [ ] T015 Escrever as rotas de contas, categorias, arquivamento e sugestões em `config/routes.rb`, conforme [contracts/routes.md](./contracts/routes.md)

---

## Phase 3: User Story 1 - Cadastrar onde o dinheiro está (Priority: P1) 🎯 MVP

**Goal**: cadastrar, editar, arquivar e listar contas com saldo.

**Independent Test**: cadastrar duas contas de tipos diferentes, editar uma, arquivar a outra e
conferir a lista — sem depender de nenhuma outra história.

### Tests for User Story 1

- [ ] T016 [P] [US1] Escrever `spec/requests/accounts_spec.rb`: estado vazio na primeira visita; cadastro com saldo em formato brasileiro; recusa sem nome e com tipo não previsto; recusa de nome repetido entre ativas; `Accounts::Cash` com instituição recusada; edição refletida na lista; exclusão permitida sem vínculo; `404` para id de outra pessoa (FR-032, FR-033); e `account[type]` ignorado quando enviado à força (contracts/routes.md)
- [ ] T017 [P] [US1] Escrever `spec/requests/accounts/archives_spec.rb`: arquivar remove da listagem do dia a dia, reativar devolve com o mesmo saldo

### Implementation for User Story 1

- [ ] T018 [US1] Criar `app/controllers/accounts_controller.rb` com `index`, `new`, `create`, `edit`, `update` e `destroy`, `params.expect(account: [...])` sem `type`, a subclasse resolvida pelo mapa `Account::KINDS`, e toda busca por `Current.user.accounts`
- [ ] T019 [US1] Criar `app/controllers/accounts/archives_controller.rb` com `create` e `destroy`
- [ ] T020 [P] [US1] Criar `app/views/accounts/index.rb` sobre `RubyUI::Table`, com `RubyUI::Empty` no estado vazio, `Components::Money` no saldo e as arquivadas distinguidas por `RubyUI::Badge`
- [ ] T021 [P] [US1] Criar `app/views/accounts/new.rb` com `RubyUI::Form`, `Components::Field` e `RubyUI::Select` para o tipo
- [ ] T022 [P] [US1] Criar `app/views/accounts/edit.rb`, sem o campo de tipo (contracts/routes.md)
- [ ] T023 [US1] Acrescentar o parâmetro `tone:` em `app/components/money.rb`, pintando valor negativo com o token `destructive` (FR-027), sem mudar o comportamento padrão
- [ ] T024 [P] [US1] Estender `spec/components/money_spec.rb` com o `tone: :signed` em valor negativo, positivo e zero

**Checkpoint**: o cadastro de contas funciona de ponta a ponta e a suíte está verde.

---

## Phase 4: User Story 2 - Organizar os gastos em categorias (Priority: P2)

**Goal**: árvore de dois níveis com natureza, cor e ícone, mais a oferta do conjunto sugerido.

**Independent Test**: criar uma categoria de despesa com cor e ícone, desdobrá-la em duas
subcategorias, renomear uma e arquivar outra — sem depender de contas nem de lançamentos.

### Tests for User Story 2

- [ ] T025 [P] [US2] Escrever `spec/requests/categories_spec.rb`: listagem separada por natureza; criação com cor e ícone; subcategoria herdando a natureza do pai; recusa de terceiro nível; recusa de irmãs homônimas; cor ou ícone fora do conjunto recusados; edição sem natureza no formulário; exclusão bloqueada com subcategoria viva; `404` para id de outra pessoa
- [ ] T026 [P] [US2] Escrever `spec/requests/categories/suggestions_spec.rb`: a oferta aparece só quando a pessoa não tem categoria nenhuma; aceitar cria a árvore sugerida; aceitar duas vezes não duplica nem revive arquivadas; a oferta desaparece após a primeira categoria manual
- [ ] T027 [P] [US2] Escrever `spec/requests/categories/archives_spec.rb`: arquivar a raiz arquiva as subcategorias na mesma transação; reativar
- [ ] T028 [P] [US2] Escrever `spec/components/category_badge_spec.rb`: nome, classe de cor literal e ícone do catálogo

### Implementation for User Story 2

- [ ] T029 [US2] Criar `app/controllers/categories_controller.rb` com `index`, `new`, `create`, `edit`, `update` e `destroy`, `params.expect` sem `nature` no `update`, e `parent_id` resolvido dentro de `Current.user.categories`
- [ ] T030 [US2] Criar `app/controllers/categories/archives_controller.rb` com `create` e `destroy`
- [ ] T031 [US2] Criar `app/controllers/categories/suggestions_controller.rb` com `create`, delegando a `Category.create_suggested_for`
- [ ] T032 [P] [US2] Criar `app/components/category_badge.rb` combinando cor, `Components::Icon` e nome, pensado para ser reusado pelas transações da feature 003
- [ ] T033 [P] [US2] Criar `app/views/categories/index.rb` com a árvore agrupada por natureza e `RubyUI::Empty` oferecendo o conjunto sugerido em um passo
- [ ] T034 [P] [US2] Criar `app/views/categories/new.rb` com `RubyUI::Select` para natureza, cor, ícone e categoria-mãe
- [ ] T035 [P] [US2] Criar `app/views/categories/edit.rb` com nome, cor e ícone — sem natureza nem categoria-mãe

**Checkpoint**: a pessoa monta seu próprio vocabulário de classificação, do zero ou a partir da
sugestão.

---

## Phase 5: User Story 3 - Ver o saldo consolidado no dashboard (Priority: P3)

**Goal**: o bloco de saldo deixa de ser zero fixo e a navegação libera Contas e Categorias.

**Independent Test**: com duas contas ativas e uma arquivada, abrir o dashboard e conferir que a soma
considera só as ativas; arquivar todas e conferir que o bloco volta ao estado vazio.

### Tests for User Story 3

- [ ] T036 [P] [US3] Estender `spec/requests/dashboard_spec.rb`: soma apenas contas ativas de depósito; estado vazio sem nenhuma conta ativa, em vez de `R$ 0,00`; consolidado negativo; os outros seis blocos intactos
- [ ] T037 [P] [US3] Estender `spec/components/stat_card_spec.rb`: `amount: nil` renderiza o estado vazio e nenhum valor monetário
- [ ] T038 [P] [US3] Estender `spec/components/main_nav_spec.rb`: Contas e Categorias com link; apenas Transações e Cartões com o badge "Em breve"

### Implementation for User Story 3

- [ ] T039 [US3] Ajustar `app/components/stat_card.rb` para renderizar o estado vazio quando `amount` é `nil` (FR-026)
- [ ] T040 [US3] Ajustar `app/controllers/dashboard_controller.rb` para calcular o saldo consolidado com um `SUM` agregado escopado — `Current.user.accounts.merge(Accounts::Deposit.active).sum(:balance)` — sem carregar registros
- [ ] T041 [US3] Ajustar `app/views/dashboard/show.rb` para receber o saldo consolidado real, ou `nil` quando não há conta ativa, mantendo os outros seis blocos vazios (FR-025, FR-029)
- [ ] T042 [US3] Ajustar `app/components/main_nav.rb` para dar caminho a Contas e Categorias, deixando só Transações e Cartões como indisponíveis (FR-028)

**Checkpoint**: as três histórias da spec estão entregues e o dashboard mostra o primeiro número real
do produto.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T043 Estender `spec/config/data_privacy_spec.rb` com um caso asseverando que o hash de parâmetros de conta é redigido no log, incluindo `name` e `institution` (FR-034)
- [ ] T044 Rodar `bin/rubocop -a` e revisar o que a correção automática mudou
- [ ] T045 Rodar `bin/brakeman` e corrigir cada achado, sem suprimir (Princípio VI)
- [ ] T046 Conferir que nenhum `.erb` novo existe fora de `app/views/layouts/`, que nenhum controller usa `Account.find` ou `Category.find` sem escopo, e que nenhuma classe Tailwind é montada por interpolação ([research.md](./research.md) D5)
- [ ] T047 Executar `bin/ci` inteiro e exigir verde
- [ ] T048 Percorrer os vinte e cinco passos da validação manual em [quickstart.md](./quickstart.md), incluindo a checagem em 360 px e a inspeção do `log/development.log`

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)
   └─> Phase 2 (Foundational)  ← bloqueia todas as histórias
          ├─> Phase 3 (US1, P1)  ← MVP
          ├─> Phase 4 (US2, P2)
          └─> Phase 5 (US3, P3)  ← precisa da US1 para ter o que somar
                 └─> Phase 6 (Polish)
```

### User Story Dependencies

- **US1** depende apenas da Fase 2.
- **US2** depende apenas da Fase 2. É totalmente independente da US1 — não toca em contas, e seus
  specs criam a sessão direto pela factory. Pode ser feita antes da US1.
- **US3** depende da Fase 2 e da **US1**: sem cadastro de contas não há saldo para consolidar. O
  ajuste do `MainNav` (T042) referencia as rotas de contas e de categorias, então pede as duas
  histórias fechadas.

### Within Each User Story

Specs primeiro, depois controllers e páginas. As páginas Phlex de uma mesma história não se tocam e
são paralelizáveis entre si.

### Parallel Opportunities

- Fase 1: T002, T003 e T004 em paralelo depois de T001.
- Fase 2: T005 e T006 em paralelo; depois T008, T010, T011 e T012 em paralelo; depois T013 e T014 em
  paralelo.
- US1: T016 e T017 em paralelo; depois T020, T021 e T022 em paralelo; T024 em paralelo com as páginas.
- US2: T025–T028 em paralelo; depois T032–T035 em paralelo.
- US3: T036, T037 e T038 em paralelo; a implementação T039–T042 é sequencial, porque T041 depende de
  T039 e T040.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

Fases 1, 2 e 3 entregam valor por si: a pessoa cadastra onde seu dinheiro está e vê a lista com os
saldos. É a primeira resposta à pergunta "qual banco eu uso mais" do PRD §7, e é o que o cadastro de
transações da feature 003 exige para existir.

### Incremental Delivery

US2 entrega o vocabulário de classificação, independente e verificável sozinho. US3 fecha a fatia
ligando o primeiro número real ao dashboard e liberando a navegação. Cada fase termina com a suíte
verde e `bin/ci` passando.

### Notes

- 48 tarefas: 4 de setup, 11 de fundação, 9 na US1, 11 na US2, 7 na US3 e 6 de polimento.
- Specs e implementação da mesma história pertencem ao mesmo commit sempre que possível
  (Princípio III).
- Nenhuma tarefa adiciona gem, pacote de importmap ou serviço: a feature inteira cabe no que já está
  instalado (Princípio V).
- `Accounts::CreditCard` **não** aparece em nenhuma tarefa — é da feature 003, conforme FR-031b e
  [research.md](./research.md) D1.
- Mensagens de commit em Conventional Commits; a entrega vai para `main` por pull request.
