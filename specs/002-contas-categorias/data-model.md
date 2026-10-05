# Data Model: Contas e Categorias

**Feature**: `002-contas-categorias` | **Date**: 2026-10-05

Duas tabelas novas, as primeiras do produto a guardar dado financeiro. `accounts` nasce como raiz de
uma hierarquia STI compartilhada com os cartões de crédito da feature 003 ([research.md](./research.md)
D1); `categories` é uma árvore de dois níveis sobre si mesma.

---

## `accounts`

| Coluna | Tipo | Nulo | Padrão | Observação |
|---|---|---|---|---|
| `id` | `bigint` | não | identidade | |
| `user_id` | `bigint` | não | — | FK → `users`, `on_delete: :cascade` |
| `type` | `string` | não | — | discriminador STI |
| `name` | `string` | não | — | como a pessoa chama o lugar |
| `institution` | `string` | sim | `nil` | banco ou emissor |
| `balance` | `decimal(15,2)` | não | `0` | aceita negativo |
| `archived_at` | `datetime` | sim | `nil` | nulo = ativa |
| `created_at` / `updated_at` | `datetime` | não | — | |

**Índices**

- `(user_id, type, archived_at)` — atende a listagem por subclasse e o saldo consolidado, que filtra
  pelos três.
- `(user_id, lower(name))` **único e parcial**, `WHERE archived_at IS NULL` — é o que implementa
  FR-006. Um nome pode se repetir entre uma conta ativa e uma arquivada.

**Hierarquia**

```
Account                   raiz: nunca instanciada diretamente
├── Accounts::Deposit     guarda dinheiro, soma no patrimônio
│   ├── Accounts::Checking   conta corrente
│   ├── Accounts::Savings    poupança
│   ├── Accounts::Wallet     carteira digital
│   └── Accounts::Cash       espécie
└── Accounts::CreditCard  concede crédito — feature 003, não existe nesta entrega
```

**Regras**

- `name` obrigatório, sem espaços nas extremidades (`normalizes`).
- `balance` obrigatório, numérico, qualquer sinal, dois decimais (FR-004). A conversão da entrada
  brasileira é do `MoneyType` (research D4), não do controller.
- `institution` é opcional na raiz (FR-003). `Accounts::Cash` **exige que fique em branco**: dinheiro
  em espécie não tem emissor, e deixar o campo aberto ali convidaria a inventar um.
- `type` restrito às subclasses registradas. A subclasse vem da rota e de um mapa de tokens
  (`"checking" → Accounts::Checking`), **nunca** de `params[:account][:type]`: aceitar o nome da
  classe do navegador deixaria alguém criar um cartão de crédito pelo formulário de conta.
- Unicidade de `name` entre as contas ativas da mesma pessoa, garantida por índice e por validação —
  a validação dá a mensagem, o índice garante o invariante sob concorrência (research D6).
- A exclusão definitiva (FR-010) é permitida enquanto não houver registro vinculado. Como
  `transactions` só existe na feature 003, nesta entrega nada bloqueia a exclusão; o
  `dependent: :restrict_with_error` que transforma a tentativa em "arquive em vez de apagar" entra
  junto com aquela tabela.

**Estado**

```
ativa  --(arquivar)-->  arquivada
   <--(reativar)----
```

`archived_at` nulo significa ativa. Os scopes são explícitos (`active`, `archived`); não há
`default_scope` (research D6). Reativar devolve a conta às listagens e ao saldo consolidado com o
mesmo saldo que tinha.

**Saldo consolidado**

Valor derivado, nunca armazenado: `Accounts::Deposit.active.sum(:balance)` escopado pelo usuário. Um
`SUM` agregado, não um `map` sobre registros carregados. Linhas de crédito ficam fora da soma por
construção — a query parte de `Deposit` e não precisa saber que cartão existe (FR-031a).

---

## `categories`

| Coluna | Tipo | Nulo | Padrão | Observação |
|---|---|---|---|---|
| `id` | `bigint` | não | identidade | |
| `user_id` | `bigint` | não | — | FK → `users`, `on_delete: :cascade` |
| `parent_id` | `bigint` | sim | `nil` | FK → `categories`; nulo = categoria raiz |
| `name` | `string` | não | — | |
| `nature` | `string` | não | — | `expense` ou `income` |
| `color` | `string` | não | — | token da paleta fixa |
| `icon` | `string` | não | — | token do catálogo fixo |
| `archived_at` | `datetime` | sim | `nil` | nulo = ativa |
| `created_at` / `updated_at` | `datetime` | não | — | |

**Índices**

- `(user_id, nature, archived_at)` — a listagem separa por natureza e esconde arquivadas.
- `(parent_id)` — FK, e a árvore é lida por ele.
- `(user_id, parent_id, lower(name))` **único e parcial**, `WHERE archived_at IS NULL`, com
  `nulls_not_distinct: true`. O `NULLS NOT DISTINCT` é indispensável: categoria raiz tem `parent_id`
  nulo e, sem ele, o Postgres trataria cada nulo como distinto e deixaria passar duas raízes
  homônimas (research D6).

**Regras**

- `name`, `nature`, `color` e `icon` obrigatórios; `color` e `icon` restritos aos conjuntos fixos
  (FR-017) — valor fora do conjunto é recusado, para a interface nunca exibir um vazio.
- `nature` é um enum de dois valores: despesa e receita (FR-014).
- `parent` precisa pertencer ao mesmo usuário.
- **Profundidade máxima dois** (FR-015): o `parent` precisa ser uma raiz. Uma subcategoria não aceita
  filhos.
- `nature` de uma subcategoria é copiada do pai antes da validação e precisa ser igual à dele
  (FR-016) — fica na linha, e não só no pai, para que "gastos por categoria" não precise de `JOIN`.
- `nature` é **imutável depois de criada**. Isso atende FR-020 por construção, sem depender de
  `transactions` existir: trocar a natureza de uma raiz inverteria o sinal de tudo o que está abaixo
  dela. Corrigir um cadastro recém-criado se faz excluindo e criando de novo, que é permitido
  enquanto a categoria não tem uso.
- Arquivar uma categoria arquiva suas subcategorias, na mesma transação (FR-021). Não restam ramos
  órfãos.
- A exclusão definitiva exige nenhuma subcategoria viva e nenhum registro classificado (FR-022). A
  segunda metade, como nas contas, só ganha efeito com a feature 003.
- Categoria arquivada continua legível no histórico e deixa de ser oferecida para novas
  classificações (FR-023).

**Estado**

```
ativa  --(arquivar: em cascata para as subcategorias)-->  arquivada
   <--(reativar)----
```

---

## Conjunto sugerido de categorias

Não é tabela: é uma constante do produto (`Category::SUGGESTED`), oferecida apenas enquanto a pessoa
não tem categoria nenhuma — nem ativa nem arquivada (FR-024, FR-024b).

| Natureza | Raiz | Subcategorias |
|---|---|---|
| Despesa | Moradia | — |
| Despesa | Alimentação | Mercado, Restaurantes, Delivery |
| Despesa | Transporte | Combustível, Transporte por app |
| Despesa | Saúde | — |
| Despesa | Educação | — |
| Despesa | Lazer | — |
| Despesa | Compras | — |
| Despesa | Assinaturas | — |
| Despesa | Outros gastos | — |
| Receita | Salário | — |
| Receita | Investimentos | — |
| Receita | Outras receitas | — |

`Category.create_suggested_for(user)` cria tudo em uma transação e é **idempotente**: ignora nomes que
a pessoa já tenha, ativos ou arquivados, de modo que aceitar duas vezes não duplica nem revive
arquivadas. As categorias criadas são comuns — sem marca de origem (FR-024a).

---

## Conjuntos fixos

- **Cores** (`Category::COLORS`): dez tokens, cada um mapeado para uma string de classes utilitárias
  **literal**. Nome de classe nunca é interpolado, porque o Tailwind varre o fonte em busca de
  literais e uma classe montada desapareceria em produção (research D5).
- **Ícones** (`Components::Icon::CATALOG`): cerca de catorze SVGs inline cobrindo o conjunto sugerido
  — casa, refeição, carro, saúde, educação, lazer, compras, recibo, viagem, trabalho, presente,
  cofre, carteira, e um genérico.

---

## Relações em `User`

```ruby
has_many :accounts,   dependent: :destroy
has_many :categories, dependent: :destroy
```

Toda leitura parte daí (`Current.user.accounts.find(params[:id])`), nunca de `Account.find` sobre um
id vindo do navegador (Princípio VI, FR-032, FR-033).
