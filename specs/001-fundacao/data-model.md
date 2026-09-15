# Data Model: Fundação

**Feature**: `001-fundacao` | **Date**: 2026-09-14

Duas tabelas, ambas criadas pelo generator de autenticação e estendidas por uma migration própria.
Nenhuma tabela financeira nasce nesta fase — elas pertencem à Fase 2.

---

## `users`

| Coluna | Tipo | Nulo | Padrão | Origem |
|---|---|---|---|---|
| `id` | `bigint` | não | identidade | generator |
| `email_address` | `string` | não | — | generator |
| `password_digest` | `string` | não | — | generator |
| `name` | `string` | não | — | esta feature |
| `confirmed_at` | `datetime` | sim | `nil` | esta feature |
| `theme` | `string` | não | `"system"` | esta feature |
| `time_zone` | `string` | não | `"America/Sao_Paulo"` | esta feature |
| `locale` | `string` | não | `"pt-BR"` | esta feature |
| `created_at` / `updated_at` | `datetime` | não | — | generator |

**Índices**

- `email_address` único (criado pelo generator via `:uniq`).

**Regras**

- `normalizes :email_address, with: ->(e) { e.strip.downcase }` — vem do generator e é o que faz
  `Maria@Exemplo.com ` e `maria@exemplo.com` identificarem a mesma conta (FR-002). Como `normalizes`
  também se aplica aos finders, `User.find_by(email_address:)` encontra a conta com qualquer grafia.
- `name` obrigatório, sem espaços nas extremidades.
- Senha com no mínimo 8 caracteres (FR-003). `has_secure_password` já rejeita senhas acima de 72
  bytes, limite do bcrypt.
- `theme` restrito a `system`, `light`, `dark` (FR-028).
- `time_zone` restrito aos nomes conhecidos pelo Rails.
- `email_address` precisa constar em `User.signup_allowed?` no momento da criação (FR-009). A
  validação vale apenas na criação: remover um endereço da lista não pode trancar uma conta que já
  existe.

**Tokens derivados** (nenhum guarda estado em tabela)

| Token | Validade | Payload | Invalida quando |
|---|---|---|---|
| `:email_confirmation` | 24 h | `email_address` | o e-mail da conta muda |
| `:password_reset` | 15 min | trecho do salt da senha | a senha muda |

O segundo é definido automaticamente por `has_secure_password` (ver `research.md` R4); apenas o
primeiro é declarado no modelo.

**Estado da conta**

```
não confirmada  --(abre link de confirmação válido)-->  confirmada
```

`confirmed_at` nulo significa não confirmada. A transição é de mão única e idempotente: consumir um
link já usado não altera `confirmed_at` nem gera erro. Só contas confirmadas abrem sessão (FR-008).

---

## `sessions`

| Coluna | Tipo | Nulo | Origem |
|---|---|---|---|
| `id` | `bigint` | não | generator |
| `user_id` | `bigint` | não | generator (`references`, com FK e índice) |
| `ip_address` | `string` | sim | generator |
| `user_agent` | `string` | sim | generator |
| `created_at` / `updated_at` | `datetime` | não | generator |

**Regras**

- `belongs_to :user`; `User has_many :sessions, dependent: :destroy`.
- Uma sessão por dispositivo. O identificador viaja em cookie assinado, permanente e `httponly`
  (`SameSite=Lax`), montado por `start_new_session_for`.
- Destruir a linha revoga o acesso na requisição seguinte, sem exibir dados da conta (FR-013 e o
  caso de borda de sessão encerrada em outro dispositivo).
- `PasswordsController#update` destrói todas as sessões do usuário ao trocar a senha — comportamento
  do generator, mantido.

---

## Escopo por usuário

Nesta fase o único dado pertencente a um usuário é a própria conta e suas sessões, e toda leitura
parte de `Current.user` ou `Current.session`. Nenhum controller recebe um identificador de conta pelo
navegador, o que satisfaz FR-034 de forma estrutural: a página de perfil edita `Current.user`, nunca
`User.find(params[:id])`.

Essa é a regra que a Fase 2 herda ao introduzir contas bancárias, cartões, categorias e transações.
