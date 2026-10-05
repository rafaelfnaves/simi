# Research: Contas e Categorias

**Feature**: `002-contas-categorias` | **Date**: 2026-10-05

Decisões técnicas tomadas antes do `plan.md`. Cada uma registra o que foi decidido, as alternativas
descartadas e o porquê.

---

## D1 — Contas e cartões de crédito compartilham uma tabela, via Single Table Inheritance

**Decisão**: uma tabela `accounts`, com a coluna `type` do STI do Rails, e a hierarquia:

```
Account                      (abstrata na prática: nunca instanciada diretamente)
├── Accounts::Deposit        (guarda dinheiro, soma no patrimônio)
│   ├── Accounts::Checking   (conta corrente)
│   ├── Accounts::Savings    (poupança)
│   ├── Accounts::Wallet     (carteira digital)
│   └── Accounts::Cash       (dinheiro em espécie)
└── Accounts::CreditCard     (concede crédito, representa dívida) — chega na feature 003
```

`Account` carrega o que é comum a tudo: `user_id`, `name`, `institution`, `balance`, `archived_at`.
`Accounts::CreditCard` acrescenta, na 003, `credit_limit`, `closing_day`, `due_day` e
`settlement_account_id` (auto-referência à conta que paga a fatura, **opcional**).

### Por que o domínio pede uma raiz comum

O caso concreto: uma conta no Itaú, com um cartão que funciona no débito e no crédito, mais um cartão
só de crédito de outra instituição.

Separando o que é canal de acesso do que é fonte de dinheiro:

| O que a pessoa faz | A quem pertence o lançamento |
|---|---|
| PIX, transferência, saque, compra no **débito** | à conta — o dinheiro sai de lá na hora |
| Compra no **crédito** | à linha de crédito — o dinheiro só sai no pagamento da fatura |
| Pagamento da fatura | dois lados: sai da conta, zera a dívida do cartão |

Disso decorrem duas conclusões que orientam o modelo:

1. **O cartão de débito não é uma entidade.** Ele não tem saldo próprio, não tem fatura e não tem
   comportamento algum: é uma forma de alcançar o dinheiro que já está na conta. Modelá-lo criaria
   uma tabela sem invariante própria. O "cartão do Itaú" que faz débito **é** a conta do Itaú.
2. **O cartão de crédito é uma entidade**, e o que o distingue não é ter plástico — é ter um ciclo de
   faturamento (fechamento/vencimento), um limite, e um saldo que significa **dívida**, não dinheiro
   disponível.

E o que conta e cartão de crédito têm em comum é justamente tudo o que esta feature cadastra: dono,
nome, instituição, situação (ativa/arquivada), e o fato de serem **a ponta de onde um lançamento
sai**. A contabilidade de partidas dobradas já resolve isso há séculos chamando os dois de *conta* —
uma de ativo, outra de passivo — e é o que GnuCash, Ledger e YNAB fazem. Vale a pena herdar o
vocabulário em vez de inventar um.

### Por que STI e não as alternativas

**Alternativa A — duas tabelas independentes (`accounts` + `credit_cards`)**. Descartada. Obrigaria
`transactions` a apontar para uma de duas tabelas, via associação polimórfica ou duas chaves
estrangeiras anuláveis. Isso contamina todo o resto do roadmap: o filtro da Fase 2, a reconciliação
da importação na Fase 3, os relatórios da Fase 4 e as regras da Fase 5 passariam a precisar de
`UNION` ou de um `if` por canal — exatamente o acoplamento que o `source` do PRD §13 existe para
evitar. E duplicaria CRUD, listagem, arquivamento e autorização.

**Alternativa B — `delegated_type` (tabela pai + tabelas filhas)**. É a opção tecnicamente mais
rigorosa: nenhuma coluna esparsa, e cada filha pode impor `NOT NULL` nos seus campos. Descartada por
custo/benefício neste produto: são quatro colunas específicas de cartão contra um `INSERT` extra por
registro, um `JOIN` em toda leitura e dois objetos para montar em cada factory e cada teste. Fica
registrada como a saída natural **se** o cadastro de cartões crescer (bandeira, titular, últimos
quatro dígitos, moeda, múltiplas faturas em aberto): a migração de STI para `delegated_type` é
mecânica, a de duas tabelas independentes para qualquer coisa não é.

**STI** entrega o que importa aqui: uma chave estrangeira só em `transactions`, um índice, uma
query; um CRUD, uma listagem, uma autorização; e as diferenças de comportamento expressas em
polimorfismo de verdade, não em condicional espalhada.

### O que isso resolve de SOLID, concretamente

O risco real a evitar não é "poucas tabelas" — é `if conta.cartao?` aparecendo no dashboard, na
listagem, no formulário e no relatório. Com a raiz comum, cada subclasse responde pelo seu próprio
comportamento e quem chama não pergunta o tipo:

- `#asset?` / `#liability?` — o saldo consolidado soma `Accounts::Deposit.active`, e a dívida dos
  cartões aparece em um bloco à parte. Nenhuma soma precisa saber que cartão existe (FR-031a).
- `#spendable?`, `#available_limit` — só o cartão tem limite; a conta não finge ter.
- Substituição (Liskov) de fato: qualquer subclasse serve onde se espera um `Account`, porque a
  interface comum é só o que é comum.
- Aberto para extensão: a 003 acrescenta `Accounts::CreditCard` sem tocar no que a 002 escreveu, e
  uma futura conta de investimento entra como outra subclasse de `Accounts::Deposit`.

### Custos aceitos e como são contidos

- **Colunas esparsas**: `credit_limit`, `closing_day`, `due_day` e `settlement_account_id` ficam
  nulas para contas de depósito. Em Postgres o custo é desprezível, e a integridade é garantida por
  validação na subclasse — com `CHECK` condicionado a `type` no banco se a revisão julgar necessário.
- **`type` exposto na URL/parâmetros**: nunca aceitar `type` de parâmetro direto do navegador; a rota
  determina a subclasse. Caso contrário, alguém cria um `Accounts::CreditCard` pelo formulário de
  conta.
- **Duas áreas, um cadastro**: a navegação do PRD §9 pede "Contas" e "Cartões" separados. São duas
  rotas e dois controladores sobre a mesma tabela, cada um escopado à sua subclasse — não um
  controlador com um seletor de tipo.

### Fronteira desta feature

A 002 cria a tabela, a raiz `Account` e a subárvore `Accounts::Deposit`. `Accounts::CreditCard` e
suas colunas são da 003. A estrutura nasce pronta para recebê-lo; o cadastro dele não entra aqui.

---

## D2 — Saldo é atributo da conta, não derivado de lançamentos

**Decisão**: `accounts.balance` é informado pela pessoa e corrigível (FR-012).

**Alternativa descartada**: criar um lançamento de abertura e derivar o saldo da soma das
movimentações. É mais auditável e elimina divergência por construção, mas exige o cadastro de
transações — que é a feature 003 — e com isso a 002 deixaria de ser entregável de forma
independente, quebrando o recorte das fatias.

**Consequência a tratar na 003**: com lançamentos existindo, saldo informado e soma das movimentações
podem divergir. A decisão de qual dos dois manda (e se a 003 converte o saldo informado em um
lançamento de abertura) pertence àquela feature, e está registrada em FR-012a para não ser esquecida.

---

## D3 — Categorias sugeridas são oferta na tela vazia, não semeadura automática

**Decisão**: a conta nova nasce sem categoria alguma; a área de Categorias oferece criar um conjunto
sugerido em um passo enquanto a lista estiver vazia (FR-024).

**Alternativas descartadas**: semear na criação da conta (a pessoa herda categorias que não escolheu
e precisa arquivar o que não usa); nascer vazio sem oferta nenhuma (a primeira visita é uma tela sem
saída, e lançar algo passa a exigir criar categoria antes).

**Consequência**: a lista sugerida é um dado fixo do produto, não uma tabela; aceitar a sugestão cria
categorias comuns, sem marca de origem, e a oferta desaparece após aceita ou após a primeira
categoria manual (FR-024a, FR-024b). Aceitar duas vezes não pode duplicar nem reviver arquivadas.

---

## D4 — Valor monetário: `decimal(15,2)` e um tipo próprio para entrada brasileira

**Decisão**: a coluna é `decimal` com `precision: 15, scale: 2`. A entrada é convertida por um tipo de
atributo próprio (`app/types/money_type.rb`, subclasse de `ActiveRecord::Type::Decimal`) aplicado com
`attribute :balance, MoneyType.new`, que aceita tanto `1234.56` quanto `1.234,56`. A exibição continua
pelo `Components::Money` já existente.

**Rationale**: `normalizes` **não** resolve este caso — ele roda depois do type cast do Active Record,
então `"1.234,56"` já teria chegado ao lambda como `1.234`. FR-038 exige aceitar o formato brasileiro,
o que empurra a conversão para antes do cast, e é exatamente aí que um `ActiveModel::Type` age. Como
tipo de atributo, a regra fica em um lugar só e a importação de extratos da Fase 3 a reaproveita sem
duplicar parser.

**Alternativas consideradas**:

- `input type="number"` e deixar o navegador normalizar: não aceita separador de milhar, e joga no
  cliente uma regra que o servidor precisa garantir de qualquer forma.
- Converter no controller: espalha formato de moeda pela camada HTTP e não serve à importação.
- Centavos em `integer`: exato, mas `numeric` do Postgres também é, e somas e relatórios em SQL ficam
  ilegíveis com valores em centavos.
- Gem `money-rails`: dependência nova para resolver multimoeda que o MVP não tem (Princípio V).

**Dispensar `attribute` e registrar o tipo em um initializer** foi descartado para não referenciar uma
constante autoloaded no boot.

---

## D5 — Ícones inline e paleta como classes literais

**Decisão**: um `Components::Icon` com catálogo fixo de SVGs inline (traçados do Lucide, o mesmo
vocabulário visual dos componentes RubyUI já vendorizados) e uma paleta fixa de cores expressa como
**classes utilitárias literais** em um mapa de constante Ruby — nunca nome de classe interpolado.

**Rationale**: zero gem nova (Princípio V), e é o que os componentes RubyUI do projeto já fazem —
`sidebar_trigger.rb`, `empty_media.rb` e outros escrevem SVG inline. O ponto crítico é o Tailwind: ele
varre o fonte em busca de classes **literais**, então `"bg-#{color}-500"` compila em desenvolvimento
com o cache quente e desaparece em produção. Um mapa `ROSE => "bg-rose-500 text-white"` é encontrado
pelo detector de fontes do Tailwind 4, que já varre `app/**/*.rb` — é o que a Fase 1 faz hoje.

**Alternativas consideradas**:

- Gem `rails_icons`: dependência nova para um conjunto fechado de cerca de doze ícones.
- Variáveis CSS com `style` inline: o Princípio II proíbe `style` inline.
- Classe montada por interpolação: quebra silenciosamente no build, e o bug só aparece em produção.

---

## D6 — Arquivamento por timestamp e unicidade por índice parcial

**Decisão**: `archived_at` (datetime, nulo = ativo), com scopes explícitos `active` e `archived` e
**sem** `default_scope`. A unicidade de FR-006 e FR-018 é imposta no banco por índice único parcial
sobre `lower(name)`, restrito a `archived_at IS NULL`, e nas categorias com `nulls_not_distinct: true`.

**Rationale**: `default_scope` vaza para associações e é difícil de desfazer em relatório ou
auditoria; os dois scopes explícitos custam uma palavra por query e não escondem nada. O índice
parcial é o que de fato implementa "duas contas **ativas** não podem ter o mesmo nome" — uma validação
sozinha perde a corrida sob concorrência. E `NULLS NOT DISTINCT` (Postgres 15+, e estamos no 18) é
indispensável nas categorias: categoria raiz tem `parent_id` nulo, e sem ele o Postgres consideraria
cada nulo distinto, deixando passar duas raízes homônimas.

**Alternativas consideradas**:

- Boolean `archived`: perde a informação de *quando*, que o histórico financeiro vai querer.
- Gem de soft delete (`discard`, `paranoia`): dependência nova para duas colunas e dois scopes.
- Unicidade só na validação: passa em teste e falha em produção com dois envios simultâneos.
