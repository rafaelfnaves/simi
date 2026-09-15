# Research: Fundação — Acesso, Navegação e Dashboard Inicial

**Feature**: `001-fundacao` | **Date**: 2026-09-14

Todas as descobertas abaixo foram verificadas contra as gems realmente instaladas neste projeto
(`Gemfile.lock`), não contra documentação genérica.

---

## R1. O que o generator de autenticação do Rails 8.1 entrega

**Decisão**: usar `bin/rails generate authentication --no-template-engine` e estender o resultado.

**Verificado em** `railties-8.1.3.1/lib/rails/generators/rails/authentication/`. O generator cria:

| Arquivo | Conteúdo relevante |
|---|---|
| `app/models/user.rb` | `has_secure_password`, `has_many :sessions, dependent: :destroy`, `normalizes :email_address, with: ->(e) { e.strip.downcase }` |
| `app/models/session.rb` | `belongs_to :user` |
| `app/models/current.rb` | `ActiveSupport::CurrentAttributes` com `session` e `delegate :user` |
| `app/controllers/concerns/authentication.rb` | `require_authentication`, `allow_unauthenticated_access`, `start_new_session_for`, `terminate_session`, e `after_authentication_url` lendo `session[:return_to_after_authenticating]` |
| `app/controllers/sessions_controller.rb` | `User.authenticate_by`, `rate_limit to: 10, within: 3.minutes` |
| `app/controllers/passwords_controller.rb` | `find_by_password_reset_token!`, `rate_limit`, resposta idêntica para e-mail inexistente |
| `app/mailers/passwords_mailer.rb` + duas views ERB | envio do link de redefinição |
| migrations | `CreateUsers` (`email_address:string!:uniq`, `password_digest:string!`) e `CreateSessions` (`user:references`, `ip_address`, `user_agent`) |

Também injeta `include Authentication` em `ApplicationController`, adiciona as rotas
`resources :passwords, param: :token` e `resource :session`, e descomenta `bcrypt` no Gemfile.

**O que isso já resolve da spec**: FR-002 (`normalizes`), FR-010/FR-011 (`authenticate_by` digere a
senha mesmo quando o e-mail não existe, defendendo contra enumeração por tempo), FR-012/FR-013
(cookie assinado permanente + `terminate_session`), FR-014 (`ip_address`/`user_agent` na sessão),
FR-015/FR-016 (`require_authentication` + `return_to_after_authenticating`), FR-018.

**Alternativas rejeitadas**: Devise traz controllers e views próprias que colidem com o Princípio II
e com o Rails Omakase do Princípio I; `authentication-zero` gera um volume grande de código para
revisar e duplica o que o framework já entrega desde o Rails 8.

---

## R2. `--no-template-engine` evita ERB gerado

**Decisão**: passar `--no-template-engine`.

O template engine padrão deste projeto é `tailwindcss` (registrado por `tailwindcss-rails`), e um
`bin/rails generate authentication --pretend` mostra que ele criaria
`app/views/{sessions/new,passwords/new,passwords/edit}.html.erb`. Com `--no-template-engine` esses
três arquivos não são criados — evita adicionar ERB proibido pelo Princípio II só para apagar
depois.

**Ressalva**: as duas views do `PasswordsMailer` (`reset.html.erb` e `reset.text.erb`) vêm do
generator principal, não do hook de template engine, e são criadas de qualquer forma. Elas devem ser
removidas e reescritas — ver R3.

---

## R3. E-mails sem ERB, mantendo a parte texto

**Decisão**: o corpo HTML é uma classe Phlex; a parte texto é montada como string Ruby no mailer.

O Princípio II proíbe novos `.erb` fora de `app/views/layouts/`, o que inclui corpos de e-mail. Phlex
cobre o HTML (`format.html { render Views::Mailers::... }`), mas não serve para `text/plain`.
Abandonar a parte texto pioraria a entregabilidade sem necessidade, então ela é gerada no próprio
mailer a partir de uma string, sem template.

**Alternativa rejeitada**: e-mail só HTML — mais simples, mas provedores penalizam mensagens sem
alternativa em texto.

---

## R4. Token de redefinição de senha já vem pronto

**Decisão**: não escrever nada para o token de redefinição.

`has_secure_password` (verificado em `activemodel-8.1.3.1/lib/active_model/secure_password.rb`) define
automaticamente:

```ruby
generates_token_for :password_reset, expires_in: 15.minutes do
  password_salt&.last(10)
end
```

com `DEFAULT_RESET_TOKEN_EXPIRES_IN = 15.minutes` e os finders `find_by_password_reset_token(!)`.

**Consequências para a spec**: FR-019 (15 minutos) é o padrão, sem configuração. FR-020 (link
invalidado ao trocar a senha) é automático — o payload do token é um trecho do salt da senha, que
muda quando a senha muda, invalidando qualquer link emitido antes.

---

## R5. Token de confirmação de cadastro

**Decisão**: `generates_token_for :email_confirmation, expires_in: 24.hours { email_address }`.

Mesmo mecanismo do token de redefinição, sem tabela nova. Usar `email_address` como payload faz o
link deixar de valer se o e-mail da conta mudar, que é o comportamento desejado.

**Uso único (FR-004, FR-005)**: o token em si é reutilizável até expirar; a unicidade efetiva vem de
`confirmed_at` — consumir um link já usado não altera nada na conta e apenas redireciona.

**Alternativa rejeitada**: tabela `email_confirmations` com coluna `used_at`. Resolveria uso único de
forma literal, mas acrescenta uma tabela e um ciclo de limpeza para um ganho que `confirmed_at` já
entrega.

---

## R6. RubyUI 1.6 cobre mais do que o esperado

**Decisão**: usar os componentes do RubyUI para sidebar, estado vazio e tema; escrever à mão apenas
o que não existe lá.

`ls ruby_ui-1.6.0/lib/ruby_ui/` mostra 50 componentes, incluindo três que o plano inicial imaginava
ter de construir:

- **`Sidebar`** — conjunto completo (`CollapsibleSidebar`, `MobileSidebar`, `SidebarMenu`,
  `SidebarMenuItem`, `SidebarMenuButton`, `SidebarInset`, `SidebarTrigger`, `SidebarGroup`...), com
  `sidebar_controller.js` próprio. Cobre FR-021 e o comportamento em celular de FR-025.
- **`Empty`** — `EmptyHeader`, `EmptyMedia`, `EmptyTitle`, `EmptyDescription`, `EmptyContent`. Cobre
  FR-023.
- **`ThemeToggle`** — ver R7.

Componentes ainda necessários da Fase 1 e já disponíveis: `Button`, `Input`, `Form`, `Card`, `Avatar`,
`DropdownMenu`, `Sheet`, `Separator`, `Alert`, `Badge`, `Table`, `Typography`, `Link`, `Select`,
`Tooltip`.

Restam de fabricação própria apenas os componentes de domínio: cartão de métrica, cabeçalho de
página e formatação de moeda.

---

## R7. Tema: o `ThemeToggle` do RubyUI não atende sozinho

**Decisão**: usar `RubyUI::ThemeToggle` como o botão do topo, mas manter a preferência na conta e
aplicar a classe no servidor.

`theme_toggle_controller.js` do RubyUI grava em `localStorage.theme` e alterna entre exatamente dois
estados, `light` e `dark`. A spec pede três (FR-028, incluindo "sistema") e exige que a preferência
acompanhe a pessoa entre dispositivos (FR-029), o que `localStorage` não faz.

Desenho adotado:

1. `users.theme` guarda `system` | `light` | `dark` e é a fonte da verdade.
2. O layout renderiza a classe no `<html>` a partir da preferência salva, de modo que a página já
   nasce no tema certo — atende FR-030 sem depender de JavaScript.
3. Quando a preferência é `system`, o layout não emite classe e um script inline curto no `<head>`
   aplica `dark` a partir de `prefers-color-scheme` antes da primeira pintura.
4. O botão do topo envia a mudança ao servidor via Turbo e um controller Stimulus curto vira a classe
   na hora, para a resposta ser imediata.
5. A página de perfil tem o seletor de três estados.

Isto é um desvio consciente do "use o RubyUI antes de escrever markup" (Princípio II): o componente
foi avaliado, cobre parte do problema e é reaproveitado, mas a persistência por conta e o terceiro
estado não existem nele. Registrado em Complexity Tracking no `plan.md`.

**Alternativa rejeitada**: aceitar o comportamento do RubyUI e guardar o tema só no navegador. Viola
FR-029 e faz a preferência sumir quando o usuário troca de máquina — justamente o cenário de um
produto pessoal usado no celular e no computador.

---

## R8. Lista de cadastros autorizados

**Decisão**: variável de ambiente `SIMI_ALLOWED_SIGNUP_EMAILS`, com endereços separados por vírgula,
lida por um método de classe em `User`.

Atende FR-009 ("definida fora do código e ajustável sem nova publicação") sem tabela nem interface de
administração. Em produção, o valor vem do Kamal; em desenvolvimento, do `.env`.

Regras de leitura: comparação após o mesmo `strip.downcase` que `normalizes` aplica; lista vazia ou
ausente significa nenhum cadastro aceito, nunca cadastro liberado (FR-009a e o caso de borda "lista
não configurada"). A leitura MUST usar `ENV.fetch` com valor padrão, para não quebrar o
`bin/rails db:prepare` em ambientes onde a variável não existe (Princípio V).

**Alternativas rejeitadas**: convites com tabela própria (fluxo inteiro fora do roadmap da Fase 1);
cadastro desligado com usuário via seed (descarta um item explícito do escopo do MVP, PRD §9).

---

## R9. `rate_limit` e o cache de teste

**Achado com risco**: o `rate_limit` que o generator coloca em `SessionsController#create` e
`PasswordsController#create` se apoia em `Rails.cache`. Este projeto usa `solid_cache` em
desenvolvimento e produção, mas `config/environments/test.rb` define `cache_store :null_store`.

**Decisão**: manter o `rate_limit` gerado — é proteção gratuita contra força bruta, melhor do que a
suposição original da spec de deixar isso fora da entrega. Nos specs, o `:null_store` não contabiliza
nada, então o limite não dispara e não torna os testes instáveis. Um spec que precise exercitar o
limite deve trocar o cache store explicitamente no exemplo.

A suposição correspondente na spec ("limitação de tentativas não faz parte desta entrega") passa a
estar defasada para melhor e é anotada aqui em vez de alterar a spec já aprovada.

---

## R10. Layout: o ERB permitido continua sendo o melhor lugar

**Decisão**: manter `app/views/layouts/application.html.erb` como esqueleto e mover toda a moldura
para componentes Phlex.

`phlex-rails` oferece `Phlex::Rails::Layout`, que permite substituir o layout por uma classe Phlex.
Foi avaliado e descartado nesta fase: o esqueleto precisa carregar a classe de tema no `<html>` e o
script anti-flash no `<head>`, o Princípio II autoriza explicitamente ERB em
`app/views/layouts/`, e trocar o mecanismo de layout acrescenta risco sem ganho visível.

O `<body>` atual traz um `<main class="container mx-auto mt-28 px-5 flex">` do scaffold, que não serve
a um app com barra lateral, e é reduzido a um `yield`.

---

## Riscos em aberto

| Risco | Mitigação |
|---|---|
| Phlex como corpo de e-mail pode exigir ajuste na chamada de `render` dentro do mailer | Cobrir com spec de mailer logo na primeira tarefa de e-mail, antes de construir os dois mailers |
| `Empty` e `Sidebar` do RubyUI podem depender de pacotes JS via importmap | Rodar o generator de componentes e conferir `config/importmap.rb` e `dependencies.yml` antes de assumir que não há pin novo |
| Script inline do tema é incompatível com CSP estrita | `config/initializers/content_security_policy.rb` está inteiramente comentado hoje; ao ativar CSP no futuro, o script precisará de nonce |
