# Contrato de Interface: rotas HTML

**Feature**: `002-contas-categorias` | **Date**: 2026-10-05

O SIMI continua sem API. A superfície externa são as rotas HTML consumidas pelo navegador. Esta
feature não envia nenhum e-mail.

---

## Rotas

Todas exigem autenticação: nenhuma recebe `allow_unauthenticated_access`.

| Verbo | Caminho | Ação | Sucesso | Falha |
|---|---|---|---|---|
| `GET` | `/accounts` | `accounts#index` | lista das contas com saldo; estado vazio na primeira visita | — |
| `GET` | `/accounts/new` | `accounts#new` | formulário de cadastro | — |
| `POST` | `/accounts` | `accounts#create` | `/accounts` com aviso | reexibe o formulário, `422` |
| `GET` | `/accounts/:id/edit` | `accounts#edit` | formulário de edição | `404` se não for da pessoa |
| `PATCH` | `/accounts/:id` | `accounts#update` | `/accounts` com aviso | reexibe o formulário, `422` |
| `DELETE` | `/accounts/:id` | `accounts#destroy` | `/accounts` com aviso | `/accounts` com alerta sugerindo arquivar |
| `POST` | `/accounts/:id/archive` | `accounts/archives#create` | `/accounts` com aviso | — |
| `DELETE` | `/accounts/:id/archive` | `accounts/archives#destroy` | `/accounts` com aviso | — |
| `GET` | `/categories` | `categories#index` | árvore separada por natureza; estado vazio com a oferta do conjunto sugerido | — |
| `GET` | `/categories/new` | `categories#new` | formulário de cadastro | — |
| `POST` | `/categories` | `categories#create` | `/categories` com aviso | reexibe o formulário, `422` |
| `GET` | `/categories/:id/edit` | `categories#edit` | formulário de edição | `404` se não for da pessoa |
| `PATCH` | `/categories/:id` | `categories#update` | `/categories` com aviso | reexibe o formulário, `422` |
| `DELETE` | `/categories/:id` | `categories#destroy` | `/categories` com aviso | `/categories` com alerta sugerindo arquivar |
| `POST` | `/categories/:id/archive` | `categories/archives#create` | `/categories` com aviso; subcategorias arquivadas junto | — |
| `DELETE` | `/categories/:id/archive` | `categories/archives#destroy` | `/categories` com aviso | — |
| `POST` | `/categories/suggestions` | `categories/suggestions#create` | `/categories` com as sugeridas criadas | `/categories` sem duplicar nada |

Arquivamento é uma **subrota própria**, não um `PATCH` com um campo escondido no formulário: arquivar
não é editar o cadastro, e separar as duas coisas mantém o formulário sem um campo que ninguém
preenche à mão.

```ruby
resources :accounts, except: :show do
  resource :archive, only: %i[ create destroy ], module: :accounts
end

resources :categories, except: :show do
  resource :archive, only: %i[ create destroy ], module: :categories
end

namespace :categories do
  resource :suggestions, only: :create
end
```

Nenhuma das duas tem `show`: a listagem já mostra tudo o que há para ver sobre uma conta ou uma
categoria nesta fase, e uma página de detalhe sem lançamentos não teria conteúdo.

---

## Parâmetros aceitos

Strong parameters com `params.expect`, conforme o Princípio I.

| Ação | Parâmetros |
|---|---|
| `accounts#create` | `account[kind]`, `account[name]`, `account[institution]`, `account[balance]` |
| `accounts#update` | `account[name]`, `account[institution]`, `account[balance]` |
| `categories#create` | `category[name]`, `category[nature]`, `category[color]`, `category[icon]`, `category[parent_id]` |
| `categories#update` | `category[name]`, `category[color]`, `category[icon]` |
| `categories/suggestions#create` | nenhum |

Três ausências deliberadas:

- **`account[type]` nunca é aceito.** O formulário envia `kind`, um token curto (`checking`,
  `savings`, `wallet`, `cash`), que o controller traduz por um mapa fixo para a subclasse. Aceitar o
  nome da classe vindo do navegador permitiria instanciar qualquer coisa — inclusive o cartão de
  crédito da feature 003 — por um formulário de conta.
- **`account[kind]` não é aceito em `update`.** Trocar a subclasse de um registro STI em edição é
  trocar a identidade do objeto; quem errou o tipo exclui e cadastra de novo, que é permitido
  enquanto a conta não tem lançamento.
- **`category[nature]` não é aceito em `update`** (FR-020, ver [data-model.md](../data-model.md)): a
  natureza é imutável, e em subcategoria é herdada do pai, não informada.

`category[parent_id]` é resolvido dentro das categorias da própria pessoa
(`Current.user.categories.find`), nunca por `Category.find` direto.

---

## Escopo e autorização

Não há camada de autorização: o escopo **é** a autorização.

| O que | Como o registro é encontrado |
|---|---|
| contas | `Current.user.accounts.find(params[:id])` |
| categorias | `Current.user.categories.find(params[:id])` |
| saldo consolidado | `Current.user.accounts.merge(Accounts::Deposit.active).sum(:balance)` |

Um id de outra pessoa levanta `ActiveRecord::RecordNotFound` e responde `404`, sem revelar que o
registro existe (FR-033). Nenhuma ação busca por id fora do escopo do usuário (FR-032).

---

## Privacidade dos parâmetros

`config/initializers/filter_parameter_logging.rb` já lista `:account` e `:balance`, e o
`ActiveSupport::ParameterFilter` redige o hash inteiro quando a chave casa — então `account[name]` e
`account[institution]` saem do log como `[FILTERED]` (FR-034). Isso deixa de ser presunção e passa a
ser asseverado em `spec/config/data_privacy_spec.rb`.

---

## Efeitos no que a Fase 1 já entregou

| Onde | O que muda |
|---|---|
| `Components::MainNav` | `Contas` e `Categorias` passam a ter caminho; só `Transações` e `Cartões` seguem com o badge "Em breve" (FR-028) |
| `DashboardController#show` | passa a calcular o saldo consolidado e informá-lo à view |
| `Views::Dashboard::Show` | o `StatCard` de saldo consolidado recebe o valor real, ou `nil` quando não há conta ativa (FR-025, FR-026) |
| `Components::StatCard` | `amount: nil` passa a renderizar o estado vazio em vez de `R$ 0,00` |
| `Components::Money` | ganha `tone: :signed`, que pinta valor negativo com o token `destructive` (FR-027) |

Os outros seis blocos do dashboard não são tocados (FR-029).
