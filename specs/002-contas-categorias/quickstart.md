# Quickstart: validando Contas e Categorias

**Feature**: `002-contas-categorias` | **Date**: 2026-10-05

Como provar que a entrega funciona de ponta a ponta. Rotas e parâmetros estão em
[contracts/routes.md](./contracts/routes.md); o esquema e as regras em
[data-model.md](./data-model.md); as decisões técnicas em [research.md](./research.md).

---

## Pré-requisitos

```bash
docker compose -f docker/compose-dev.yaml up -d   # PostgreSQL 18 + Mailpit
bin/rails db:prepare                              # aplica CreateAccounts e CreateCategories
```

Uma conta de usuário confirmada é necessária. Se o ambiente estiver limpo, criar uma pelo fluxo da
Fase 1 (`SIMI_ALLOWED_SIGNUP_EMAILS` no `.env`, cadastro, link de confirmação no Mailpit em
`localhost:8025`) ou pelo console:

```bash
bin/rails runner 'User.create!(name: "Teste", email_address: "teste@exemplo.com", password: "senha12345", confirmed_at: Time.current)'
```

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
| US1 — cadastrar contas | `spec/models/account_spec.rb`, `spec/requests/accounts_spec.rb`, `spec/types/money_type_spec.rb` |
| US2 — organizar categorias | `spec/models/category_spec.rb`, `spec/requests/categories_spec.rb`, `spec/components/category_badge_spec.rb` |
| US3 — saldo no dashboard | `spec/requests/dashboard_spec.rb`, `spec/components/{stat_card,money}_spec.rb` |
| Transversal | `spec/config/data_privacy_spec.rb` |

Pontos que merecem exemplo dedicado, por serem os mais fáceis de quebrar sem perceber:

- **Entrada em formato brasileiro**: `"1.234,56"` precisa chegar ao banco como `1234.56`, e `"-90,00"`
  como `-90.0` (FR-004, FR-035, research D4).
- **Unicidade só entre ativas**: criar `"Itaú"`, arquivar, criar `"Itaú"` de novo — deve passar.
  Criar duas `"Itaú"` ativas — deve falhar, inclusive com grafia diferente (`"itaú"`) e sob dois
  envios simultâneos, porque o invariante é do índice, não só da validação (FR-006, research D6).
- **Duas raízes homônimas de categoria**: duas categorias raiz chamadas `"Alimentação"` devem ser
  recusadas pelo banco. É o caso que falha silenciosamente sem `nulls_not_distinct` (FR-018).
- **Profundidade dois**: criar subcategoria dentro de subcategoria deve ser recusado (FR-015).
- **Cascata de arquivamento**: arquivar a raiz arquiva as filhas na mesma transação (FR-021).
- **Idempotência da sugestão**: aceitar duas vezes não duplica nem revive arquivadas (FR-024a).
- **Escopo**: `GET /accounts/:id/edit` com o id de uma conta de outra pessoa responde `404` e não
  revela nada (FR-032, FR-033).
- **`type` não é mass-assignable**: `POST /accounts` com `account[type]=Accounts::CreditCard` precisa
  ser ignorado — a subclasse vem do mapa de `kind` (contracts/routes.md).
- **Saldo consolidado é um `SUM`**: a ação do dashboard não deve carregar os registros para somar em
  Ruby.

---

## Validação manual, na ordem das histórias

```bash
bin/dev    # servidor + watcher do Tailwind
```

Entrar com a conta de teste e seguir:

**US1 — contas (FR-001 a FR-012)**

1. Abrir `/accounts` pela navegação lateral: Contas não deve mais exibir o badge "Em breve" (FR-028),
   e a tela mostra um estado vazio explicativo com o caminho para cadastrar (US1 cenário 1).
2. Cadastrar `Itaú` / conta corrente / instituição `Itaú` / saldo `1.234,56`. A conta aparece na lista
   com `R$ 1.234,56`.
3. Cadastrar `Carteira` / carteira digital / saldo `-90,00`. O valor negativo é aceito e exibido com
   destaque distinto do positivo (FR-004, FR-027).
4. Cadastrar `Dinheiro` / espécie, preenchendo instituição: deve ser recusado — espécie não tem
   emissor (data-model).
5. Tentar salvar uma segunda conta chamada `Itaú`: recusada (FR-006).
6. Salvar uma conta sem nome: recusada com a explicação do que falta (FR-005).
7. Editar `Itaú` para `Itaú — conta salário`: o novo nome aparece na lista (US1 cenário 5).
8. Arquivar `Carteira`: sai da listagem do dia a dia e some do saldo consolidado (FR-009).
   Reativar: volta com o mesmo saldo.
9. Excluir uma conta recém-criada e sem nada vinculado: permitido (FR-010).
10. Abrir `/accounts` em uma janela de 360 px: a lista continua legível (FR-030).

**US2 — categorias (FR-013 a FR-024b)**

11. Abrir `/categories`: estado vazio oferecendo criar o conjunto sugerido em um passo (FR-024).
12. Aceitar a sugestão: as categorias aparecem separadas entre despesa e receita, `Alimentação` com
    `Mercado`, `Restaurantes` e `Delivery` (FR-024, US2 cenário 2).
13. Recarregar: a oferta não aparece mais (FR-024b).
14. Criar `Academia` como despesa, com cor e ícone: aparece na lista com o badge colorido.
15. Criar uma subcategoria dentro de `Mercado` (que já é subcategoria): a opção não é oferecida
    (FR-015, US2 cenário 7).
16. Criar outra categoria raiz de despesa chamada `Alimentação`: recusada (FR-018).
17. Editar `Academia`: nome, cor e ícone são editáveis; natureza **não** aparece no formulário
    (FR-020).
18. Arquivar `Alimentação`: as três subcategorias são arquivadas junto (FR-021).
19. Excluir `Academia`, que não tem uso nem filha: permitido (FR-022).

**US3 — dashboard (FR-025 a FR-029)**

20. Com `Itaú` ativa, abrir `/`: o bloco de saldo consolidado exibe a soma das contas ativas em reais
    (FR-025).
21. Arquivar todas as contas e recarregar `/`: o bloco volta ao estado vazio convidando a cadastrar a
    primeira conta — **não** `R$ 0,00` (FR-026).
22. Deixar ativa apenas uma conta com saldo negativo: o consolidado aparece negativo, com destaque
    (FR-027, US3 cenário 3).
23. Conferir que os outros seis blocos continuam em estado vazio (FR-029) e que apenas `Transações` e
    `Cartões` seguem marcados como indisponíveis na navegação (FR-028).

**Transversal — privacidade (FR-032 a FR-035)**

24. Com `log/development.log` aberto, cadastrar uma conta e confirmar que nome, instituição e saldo
    saem como `[FILTERED]` (FR-034).
25. Autenticar com uma segunda conta de usuário e tentar `GET /accounts/:id/edit` com o id de uma
    conta da primeira: responde `404` sem conteúdo (FR-032, FR-033).

---

## Critérios de pronto

- `bin/ci` verde, incluindo Brakeman sem achado novo e sem supressão.
- Os 25 passos acima reproduzidos no ambiente local.
- Todos os FRs da spec cobertos por pelo menos um exemplo automatizado (SC-008).
- Nenhum `.erb` novo, nenhuma gem nova, nenhum nome de classe Tailwind interpolado.
