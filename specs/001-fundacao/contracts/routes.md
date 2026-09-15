# Contrato de Interface: rotas HTML e e-mails

**Feature**: `001-fundacao` | **Date**: 2026-09-14

O SIMI não expõe API nesta fase. A superfície externa são as rotas HTML consumidas pelo navegador e
os dois e-mails transacionais.

---

## Rotas

Autenticação exigida em tudo, exceto onde marcado com `allow_unauthenticated_access`.

| Verbo | Caminho | Ação | Aberta | Sucesso | Falha |
|---|---|---|---|---|---|
| `GET` | `/` | `dashboard#show` | não | dashboard | redireciona para `/session/new` |
| `GET` | `/session/new` | `sessions#new` | sim | formulário de entrada | — |
| `POST` | `/session` | `sessions#create` | sim | redireciona para `after_authentication_url` | volta a `/session/new` com alerta genérico |
| `DELETE` | `/session` | `sessions#destroy` | não | `/session/new`, `303 See Other` | — |
| `GET` | `/registration/new` | `registrations#new` | sim | formulário de cadastro | — |
| `POST` | `/registration` | `registrations#create` | sim | `/session/new` com aviso de e-mail enviado | reexibe o formulário, `422` |
| `GET` | `/confirmations/:token` | `confirmations#show` | sim | confirma, abre sessão, vai ao dashboard | `/confirmations/new` com alerta |
| `GET` | `/confirmations/new` | `confirmations#new` | sim | formulário de reenvio | — |
| `POST` | `/confirmations` | `confirmations#create` | sim | `/session/new` com aviso genérico | — |
| `GET` | `/passwords/new` | `passwords#new` | sim | formulário de recuperação | — |
| `POST` | `/passwords` | `passwords#create` | sim | `/session/new` com aviso genérico | — |
| `GET` | `/passwords/:token/edit` | `passwords#edit` | sim | formulário de nova senha | `/passwords/new` com alerta |
| `PATCH` | `/passwords/:token` | `passwords#update` | sim | `/session/new` com aviso | reexibe o formulário, `422` |
| `GET` | `/settings/profile` | `settings/profiles#show` | não | formulário de perfil | — |
| `PATCH` | `/settings/profile` | `settings/profiles#update` | não | reexibe com aviso | reexibe o formulário, `422` |
| `PATCH` | `/settings/theme` | `settings/themes#update` | não | reexibe a página de origem no novo tema | — |
| `GET` | `/up` | `rails/health#show` | sim | `200` | `500` |

`resources :passwords, param: :token` e `resource :session` são adicionadas pelo generator; as demais
são escritas manualmente.

---

## Parâmetros aceitos

Strong parameters com `params.expect`, conforme o Princípio I.

| Ação | Parâmetros |
|---|---|
| `sessions#create` | `email_address`, `password` |
| `registrations#create` | `user[name]`, `user[email_address]`, `user[password]`, `user[password_confirmation]` |
| `confirmations#create` | `email_address` |
| `passwords#create` | `email_address` |
| `passwords#update` | `password`, `password_confirmation` |
| `settings/profiles#update` | `user[name]`, `user[time_zone]`, `user[theme]` |
| `settings/themes#update` | `theme` |

`email_address` nunca é aceito em `settings/profiles#update`: trocar o e-mail exigiria reconfirmação,
o que está fora desta entrega. O campo aparece no perfil apenas para leitura.

---

## Respostas indistinguíveis

Três ações respondem de forma idêntica exista ou não a conta, para não permitir enumeração
(FR-011, FR-018, FR-009a). O contrato é o mesmo destino, a mesma mensagem e o mesmo código:

| Ação | Resposta única |
|---|---|
| `sessions#create` com senha errada, e-mail inexistente ou conta não confirmada | redireciona para `/session/new` com a mesma mensagem — exceto conta não confirmada, que recebe a mensagem específica de confirmação pendente, já que a pessoa provou conhecer a senha |
| `passwords#create` | redireciona para `/session/new` com "Se existir uma conta com esse e-mail, o link foi enviado" |
| `confirmations#create` | mesma forma da anterior |
| `registrations#create` com e-mail já cadastrado ou fora da lista autorizada | mesma resposta de sucesso aparente, sem criar conta e sem enviar e-mail |

---

## E-mails

| Mailer | Gatilho | Assunto | Conteúdo | Validade do link |
|---|---|---|---|---|
| `UserMailer#confirmation` | cadastro e reenvio | "Confirme seu cadastro no SIMI" | saudação pelo nome e o link de confirmação | 24 h |
| `PasswordsMailer#reset` | pedido de recuperação | "Redefina sua senha do SIMI" | o link de redefinição | 15 min |

Ambos são multipart: a parte HTML é uma classe Phlex, a parte texto é montada como string no mailer
(`research.md` R3). Nenhum dos dois inclui senha ou dado financeiro (FR-035). Ambos são enviados com
`deliver_later`, pela fila `solid_queue`.

---

## Contrato visual do dashboard

`dashboard#show` renderiza sete blocos, nesta ordem, cada um identificável para teste:

| Bloco | Estado nesta fase |
|---|---|
| Saldo consolidado | métrica em `R$ 0,00` com nota de que não há contas cadastradas |
| Receitas do mês | métrica em `R$ 0,00` |
| Despesas do mês | métrica em `R$ 0,00` |
| Gastos por categoria | estado vazio |
| Despesas por projeto | estado vazio |
| Evolução mensal | estado vazio |
| Últimas movimentações | estado vazio |

Estados vazios explicam o que aparecerá ali, sem valores fictícios (FR-023). Valores monetários usam
Real brasileiro (FR-024).

A navegação principal lista Dashboard, Transações, Contas, Cartões, Categorias e Configurações; as
quatro áreas da Fase 2 aparecem marcadas como indisponíveis e não são clicáveis (FR-021).
