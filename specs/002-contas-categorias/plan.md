# Implementation Plan: Contas e Categorias — Cadastros do Núcleo Financeiro

**Branch**: `002-contas-categorias` | **Date**: 2026-10-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-contas-categorias/spec.md`

## Summary

Primeiras tabelas financeiras do produto. A Fase 1 deixou a casca pronta — autenticação, `AppShell`,
dashboard com sete blocos vazios — e esta feature pendura nela os dois cadastros de que todo
lançamento depende: **contas** (onde o dinheiro está) e **categorias** (como o gasto é classificado).

A decisão estrutural que organiza tudo está em [research.md](./research.md) D1: conta e cartão de
crédito compartilham uma única tabela `accounts`, via Single Table Inheritance, porque a contabilidade
sempre tratou os dois como contas — uma de ativo, outra de passivo — e porque uma raiz comum dá a
`transactions` uma única chave estrangeira, em vez de uma associação polimórfica que contaminaria o
filtro da Fase 2, a reconciliação da Fase 3 e os relatórios da Fase 4. Esta entrega cria a raiz
`Account` e a subárvore `Accounts::Deposit`; `Accounts::CreditCard` é da feature 003.

Categorias são uma árvore de dois níveis na mesma tabela, com natureza (despesa ou receita), cor e
ícone. A lista nasce vazia e a tela oferece criar um conjunto sugerido em um passo.

No fim, o `StatCard` de saldo consolidado deixa de ser `amount: 0` e passa a somar as contas ativas, e
Contas e Categorias perdem o badge "Em breve" na navegação.

## Technical Context

**Language/Version**: Ruby 4.0.6

**Primary Dependencies**: Rails 8.1.3.1, phlex-rails 2.4 + ruby_ui 1.6, tailwindcss-rails 4.6 +
tailwind_merge, importmap-rails com turbo-rails e stimulus-rails. **Nenhuma gem nova** — STI, enums,
índices parciais e tipos de atributo são todos do próprio Rails.

**Storage**: PostgreSQL 18. Duas tabelas novas (`accounts`, `categories`). A extensão `vector` existe
na imagem mas continua sem uso — é da Fase 3.

**Testing**: RSpec 8 + FactoryBot + FFaker. Specs de componente pelo harness de
`spec/support/phlex.rb`; specs de request pelos helpers de `spec/support/authentication.rb`.

**Target Platform**: aplicação web servida por Puma atrás de Thruster, publicada com Kamal.

**Project Type**: monólito Rails com renderização no servidor. Sem build de Node, sem SPA.

**Performance Goals**: sem meta de throughput — o volume é de dezenas de contas e categorias por
pessoa. As duas restrições reais são: o saldo consolidado é **um** `SUM` agregado, não um `map` sobre
registros carregados; e a listagem de categorias carrega a árvore sem N+1 (`includes(:subcategories)`).

**Constraints**: nenhuma gem nova (Princípio V); nenhum `.erb` novo (Princípio II); nenhum nome de
classe Tailwind montado por interpolação (ver research D5); toda leitura a partir de `Current.user`
(Princípio VI); telas utilizáveis a partir de 360 px.

**Scale/Scope**: uso individual. 5 controllers novos, 6 telas, 2 tabelas, 2 modelos (um com
hierarquia STI), 2 componentes novos e 4 arquivos existentes modificados.

## Constitution Check

*GATE: verificado antes da Fase 0 e revisto após a Fase 1.*

| Princípio | Avaliação | Situação |
|---|---|---|
| I. Rails Omakase | STI, enum, `attribute` com tipo próprio, índice parcial e associação auto-referente são todos recursos de primeira classe do Rails — nada importado de outro ecossistema. Nenhum service object: a criação do conjunto sugerido é um método de classe em `Category`, o arquivamento é um método de instância, e o saldo consolidado é um `SUM` escopado. `params.expect` em todo controller, e a subclasse STI vem da rota, nunca de parâmetro do navegador. | **Passa** |
| II. Phlex, nunca ERB | Todas as seis telas são classes Phlex sob `app/views/`. Reaproveitam `RubyUI::Table`, `Form`, `Select`, `Empty`, `Badge`, `Card` e `Sheet`, mais `Components::Field`, `PageHeader`, `Money` e `DashboardPanel` da Fase 1. Ícones em SVG inline, como os próprios componentes RubyUI já fazem. Nenhum `style` inline, nenhuma classe interpolada. | **Passa** |
| III. Specs junto do código | Cada história entra com specs de modelo, request e componente no mesmo change set, mais a extensão de `spec/config/data_privacy_spec.rb`. FFaker, nunca Faker. | **Passa** |
| IV. Código autoexplicativo | Sem comentários de narração. Doc YARD apenas onde a interface pública não é óbvia: `MoneyType#cast`, `Category.create_suggested_for`, `Account#archive!`. | **Passa** |
| V. Uma stack sem graça | Zero gem nova, zero pacote novo no importmap, zero serviço novo. | **Passa** |
| VI. Dado financeiro é privado | Todo acesso parte de `Current.user.accounts` / `Current.user.categories` — nenhum `Account.find(params[:id])` sem escopo. Nome e instituição de conta já caem no filtro de log, porque `:account` redige o hash de parâmetros inteiro; isso passa a ser **asseverado por spec** em vez de presumido. Achados do Brakeman são corrigidos, não silenciados. | **Passa** |

**Revisão pós-Fase 1**: o desenho não introduziu gem, datastore, camada nem processo. A única
estrutura acrescentada é a hierarquia STI, justificada em research D1 e registrada em Complexity
Tracking. Gates seguem verdes.

## Project Structure

### Documentation (this feature)

```text
specs/002-contas-categorias/
├── plan.md              # Este arquivo
├── spec.md              # Especificação aprovada
├── research.md          # Fase 0 — D1 estrutura contas/cartões, D2 saldo, D3 categorias
│                        #          sugeridas, D4 moeda, D5 ícones/cores, D6 arquivamento
├── data-model.md        # Fase 1 — accounts e categories
├── quickstart.md        # Fase 1 — como validar a entrega de ponta a ponta
├── contracts/
│   └── routes.md        # Fase 1 — rotas, parâmetros e respostas
├── checklists/
│   └── requirements.md  # Checklist de qualidade da spec
└── tasks.md             # Fase 2 — gerado por /speckit-tasks
```

### Source Code (repository root)

```text
app/
├── models/
│   ├── account.rb                       # raiz STI: user, name, institution, balance, archived_at
│   ├── accounts/
│   │   ├── deposit.rb                   # guarda dinheiro; TYPES lista as folhas (research D7)
│   │   ├── checking.rb                  # conta corrente
│   │   ├── savings.rb                   # poupança
│   │   ├── wallet.rb                    # carteira digital
│   │   └── cash.rb                      # espécie — sem instituição
│   ├── category.rb                      # árvore de dois níveis, natureza, cor, ícone
│   └── user.rb                          # ganha has_many :accounts e :categories
├── types/
│   └── money_type.rb                    # aceita "1.234,56" e "1234.56" (research D4)
├── controllers/
│   ├── accounts_controller.rb
│   ├── accounts/
│   │   └── archives_controller.rb       # arquivar e reativar uma conta
│   ├── categories_controller.rb
│   ├── categories/
│   │   ├── archives_controller.rb       # arquivar e reativar, em cascata
│   │   └── suggestions_controller.rb    # cria o conjunto sugerido em um passo
│   └── dashboard_controller.rb          # passa a calcular o saldo consolidado
├── components/
│   ├── icon.rb                          # catálogo fixo de SVGs inline
│   ├── category_badge.rb                # cor + ícone + nome, reusável na Fase 2
│   ├── select_field.rb                  # o par de Field para listas fechadas
│   ├── account_form.rb                  # compartilhado por new e edit
│   ├── category_form.rb                 # idem, sem natureza nem mãe na edição
│   ├── money.rb                         # ganha tone: para destacar negativo (FR-027)
│   ├── stat_card.rb                     # ganha estado vazio quando amount é nil (FR-026)
│   └── main_nav.rb                      # Contas e Categorias deixam de ser "Em breve"
├── views/
│   ├── accounts/{index,new,edit}.rb
│   ├── categories/{index,new,edit}.rb
│   └── dashboard/show.rb                # saldo consolidado deixa de ser zero fixo
db/migrate/                              # CreateAccounts, CreateCategories
spec/
├── factories/{accounts,categories}.rb
├── models/{account,category}_spec.rb
├── types/money_type_spec.rb
├── requests/{accounts,categories,dashboard}_spec.rb
├── components/{category_badge,money,stat_card}_spec.rb
└── config/data_privacy_spec.rb          # +1 caso: parâmetros de conta são redigidos
config/routes.rb                         # resources :accounts, :categories + suggestions
```

**Structure Decision**: monólito Rails padrão, sem subprojetos — o mesmo arranjo da Fase 1. As
subclasses STI ficam em `app/models/accounts/`, nomeadas `Accounts::Checking` e companhia, para que o
caminho do arquivo revele a hierarquia. `app/types/` é autoloaded como qualquer diretório sob `app/`,
o que dispensa initializer para o tipo de moeda. Contas e Cartões serão **duas rotas e dois
controllers sobre a mesma tabela**, cada um escopado à sua subclasse — não um controller com seletor
de tipo, que reintroduziria no HTTP o condicional que a herança existe para eliminar.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Hierarquia STI de dois níveis (`Account` → `Accounts::Deposit` → quatro folhas), em vez de uma tabela plana com um enum de tipo | FR-031 exige que cartão de crédito seja um registro do mesmo cadastro, e FR-031a que ele não some no saldo consolidado. Com a raiz comum, o saldo é `Accounts::Deposit.active.sum(:balance)` e nenhuma soma precisa saber que cartão existe. As folhas também divergem de verdade: espécie não tem instituição. | Um enum `kind` numa tabela plana obrigaria `if conta.cartao?` no dashboard, na listagem, no formulário e em todo relatório da Fase 4 — o condicional por tipo espalhado que a herança elimina. Duas tabelas independentes foram descartadas em research D1 por forçarem associação polimórfica em `transactions`. |
| Quatro subclasses-folha quase vazias | Mantêm **um** discriminador. A alternativa (`Accounts::Deposit` com um enum `kind`) teria dois eixos de classificação — `type` para comportamento e `kind` para rótulo — sobre a mesma distinção. | Classe vazia hoje é taxonomia explícita e ponto de extensão; discriminador duplicado é ambiguidade permanente sobre qual dos dois manda. |
| `Components::Money` e `Components::StatCard` ganham parâmetro novo em vez de nascerem componentes à parte | FR-026 pede estado vazio no bloco de saldo e FR-027 destaque para valor negativo. Os dois componentes já são o lugar único onde o produto formata dinheiro e monta um cartão de métrica. | Um `NegativeMoney` ou `EmptyStatCard` separado duplicaria a formatação que o `Money` existe para centralizar, e quem chama passaria a escolher o componente pelo valor do dado. |
