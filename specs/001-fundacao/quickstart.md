# Quickstart: validando a Fundação

**Feature**: `001-fundacao` | **Date**: 2026-09-14

Como provar que a entrega funciona de ponta a ponta. Detalhes de rotas e parâmetros estão em
[contracts/routes.md](./contracts/routes.md); o esquema está em [data-model.md](./data-model.md).

---

## Pré-requisitos

```bash
docker compose -f docker/compose-dev.yaml up -d   # PostgreSQL 18 com pgvector + Mailpit
bin/setup --skip-server                           # dependências, bancos, migrations
```

O `.env` local precisa de `SIMI_ALLOWED_SIGNUP_EMAILS` com o endereço que será usado no teste
manual — sem isso, nenhum cadastro é aceito, que é o comportamento esperado (`research.md` R8).

---

## Verificação automatizada

```bash
bundle exec rspec        # suíte completa, verde
bin/rubocop              # rails-omakase, sem ofensas
bin/ci                   # setup, estilo, auditorias, Brakeman e RSpec
```

Cobertura esperada por história:

| História | Specs que a provam |
|---|---|
| US1 — criar conta e entrar | `spec/requests/registrations_spec.rb`, `confirmations_spec.rb`, `sessions_spec.rb`, `spec/mailers/user_mailer_spec.rb`, `spec/models/user_spec.rb` |
| US2 — recuperar o acesso | `spec/requests/passwords_spec.rb`, `spec/mailers/passwords_mailer_spec.rb` |
| US3 — dashboard e navegação | `spec/requests/dashboard_spec.rb`, `spec/components/{app_shell,main_nav,stat_card,money}_spec.rb` |
| US4 — perfil e tema | `spec/requests/settings_spec.rb` |

Pontos que merecem um exemplo dedicado, por serem os mais fáceis de quebrar sem perceber:

- Cadastro com e-mail fora da lista autorizada não cria conta, não envia e-mail, e responde igual a um
  cadastro bem-sucedido (FR-009a).
- Entrar com senha correta numa conta não confirmada não abre sessão (FR-008).
- Um link de redefinição deixa de valer assim que a senha muda (FR-020).
- Abrir uma página privada sem sessão leva à entrada e, depois de autenticar, volta ao endereço
  pedido (FR-016).
- Nenhum e-mail, senha ou token aparece no log durante os três fluxos (FR-033, SC-007). O spec
  `spec/config/data_privacy_spec.rb`, já existente, cobre a configuração; aqui o que se verifica é o
  comportamento durante as requisições.

---

## Verificação manual

```bash
bin/dev        # servidor + tailwindcss:watch
```

Mailpit em <http://localhost:8025>, aplicação em <http://localhost:3000>.

1. **Acesso protegido** — abrir `/` deslogado leva a `/session/new`.
2. **Cadastro recusado** — tentar se cadastrar com um e-mail fora de `SIMI_ALLOWED_SIGNUP_EMAILS`.
   Nenhuma conta é criada, nenhum e-mail chega ao Mailpit, e a tela não revela o motivo.
3. **Cadastro aceito** — repetir com um endereço autorizado. O e-mail de confirmação aparece no
   Mailpit, com as partes HTML e texto.
4. **Confirmação pendente** — tentar entrar antes de clicar no link. O acesso é recusado e a tela
   oferece reenviar a confirmação.
5. **Confirmação** — abrir o link do Mailpit. A conta é confirmada e a sessão abre no dashboard.
6. **Dashboard vazio** — conferir os sete blocos, cada um com estado vazio explicativo, e a navegação
   com as áreas da Fase 2 marcadas como indisponíveis.
7. **Tema** — alternar pelo botão do topo, recarregar e confirmar que não há flash do tema anterior.
   Abrir em outro navegador, autenticado na mesma conta, e confirmar que a preferência acompanhou.
   No perfil, escolher "sistema" e alternar o modo escuro do sistema operacional.
8. **Perfil** — alterar o nome e confirmar que a navegação passa a exibi-lo.
9. **Recuperação** — sair, pedir a redefinição, abrir o link do Mailpit, definir uma senha nova,
   confirmar que a antiga não funciona mais e que reabrir o mesmo link de redefinição é recusado.
10. **Celular** — repetir os passos 6 e 7 com a janela em 360 px de largura: a barra lateral recolhe
    e o conteúdo continua legível, sem rolagem horizontal.
11. **Logs** — inspecionar `log/development.log` e confirmar que e-mail, senha e tokens aparecem
    filtrados.

---

## Sinais de que algo saiu do trilho

- Qualquer `.erb` novo fora de `app/views/layouts/` viola o Princípio II.
- Um `User.find(params[:id])` em qualquer controller viola o Princípio VI.
- `bin/ci` vermelho, ou uma regra de lint desligada para passar, barra a entrega (Princípio III).
