# Feature Specification: Contas e Categorias — Cadastros do Núcleo Financeiro

**Feature Branch**: `002-contas-categorias`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "Cadastros base do núcleo financeiro do SIMI: contas (bancos, contas
correntes/poupança e carteiras, com saldo inicial, instituição e arquivamento) e categorias de
despesa/receita com subcategorias, ícone e cor, ambas escopadas ao usuário autenticado. Inclui ligar
o bloco 'Saldo consolidado' do dashboard à soma dos saldos das contas e habilitar os itens Contas e
Categorias na navegação principal. Corresponde à primeira fatia da Fase 2 — Núcleo Financeiro do
roadmap em docs/PRD.md (escopo de Transações, Cartões, Pesquisa e Filtros fica para as features 003
e 004)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cadastrar onde o dinheiro está (Priority: P1)

Uma pessoa que acabou de entrar no SIMI tem dinheiro espalhado por dois bancos, uma conta poupança e
uma carteira digital. Ela cadastra cada um desses lugares com um nome que reconhece, a instituição e
quanto há ali hoje, e passa a ver a lista de todas as suas contas com o saldo de cada uma. Quando
fecha uma conta no banco, ela arquiva a conta no SIMI em vez de apagar o histórico.

**Why this priority**: É o primeiro dado financeiro real que o produto guarda e a resposta para "qual
banco eu uso mais" (PRD §7). Nenhum lançamento pode ser registrado sem saber de onde o dinheiro sai
ou para onde entra, então toda a Fase 2 depende deste cadastro.

**Independent Test**: Pode ser testado inteiro sem nenhuma outra história — cadastrar duas contas de
tipos diferentes, editar uma, arquivar outra e conferir a lista — e já entrega o valor de ter o mapa
de onde o dinheiro está.

**Acceptance Scenarios**:

1. **Given** uma pessoa autenticada sem nenhuma conta cadastrada, **When** ela abre a área de Contas,
   **Then** encontra um estado vazio que explica o que é uma conta e um caminho direto para cadastrar
   a primeira.
2. **Given** uma pessoa autenticada, **When** ela cadastra uma conta informando nome, tipo e saldo
   atual, **Then** a conta passa a aparecer na lista com o saldo informado.
3. **Given** uma pessoa autenticada, **When** ela tenta cadastrar uma conta sem nome ou com um tipo
   não previsto, **Then** o cadastro é recusado com a explicação do que falta e nada é salvo.
4. **Given** duas contas cadastradas com o mesmo nome, **When** a segunda é salva, **Then** o cadastro
   é recusado, porque dois lugares com o mesmo nome tornam impossível saber a qual deles um lançamento
   pertence.
5. **Given** uma conta existente, **When** a pessoa corrige seu nome ou sua instituição, **Then** a
   alteração é refletida em todos os lugares onde a conta aparece.
6. **Given** uma conta que a pessoa não usa mais, **When** ela a arquiva, **Then** a conta deixa de
   aparecer nas listagens do dia a dia e de somar no saldo consolidado, mas continua existindo e pode
   ser reativada.
7. **Given** uma conta pertencente a outra pessoa, **When** alguém tenta abri-la ou editá-la pelo
   endereço direto, **Then** o acesso é negado sem revelar que aquela conta existe.
8. **Given** uma pessoa com um cartão de débito vinculado à sua conta, **When** ela registra um gasto
   no débito, um PIX, uma transferência ou um saque, **Then** tudo isso pertence à conta — o cartão de
   débito não é um cadastro à parte.

---

### User Story 2 - Organizar os gastos em categorias (Priority: P2)

A pessoa quer saber quanto gasta em restaurantes e quanto recebe de salário. Antes de lançar qualquer
coisa, ela organiza sua própria estrutura: cria categorias de despesa e de receita, dá a cada uma uma
cor e um ícone para reconhecê-las de relance, e desdobra as mais amplas em subcategorias — Alimentação
com Restaurantes, Mercado e Delivery.

**Why this priority**: É o vocabulário com que todo lançamento será classificado e a base dos blocos
"gastos por categoria" e "evolução mensal" do dashboard. Vem depois das contas porque uma conta é
indispensável para registrar um lançamento, enquanto uma categoria pode começar ausente.

**Independent Test**: Criar uma categoria de despesa com cor e ícone, desdobrá-la em duas
subcategorias, renomear uma delas e arquivar outra — tudo sem depender de contas ou lançamentos.

**Acceptance Scenarios**:

1. **Given** uma pessoa autenticada que ainda não criou nenhuma categoria, **When** ela abre a área de
   Categorias, **Then** encontra um estado vazio que explica para que servem categorias e oferece
   criar de uma vez um conjunto sugerido de categorias comuns no Brasil.
2. **Given** essa oferta na tela, **When** a pessoa aceita a sugestão, **Then** as categorias
   sugeridas passam a ser suas — editáveis, arquiváveis e excluíveis como qualquer outra — e a oferta
   deixa de aparecer.
3. **Given** essa oferta na tela, **When** a pessoa a ignora e cria a própria primeira categoria,
   **Then** a oferta também deixa de aparecer, sem nada ter sido criado em seu nome.
4. **Given** uma pessoa com categorias cadastradas, **When** ela abre a área de Categorias, **Then**
   encontra suas categorias separadas entre despesa e receita.
5. **Given** uma pessoa autenticada, **When** ela cria uma categoria informando nome, natureza
   (despesa ou receita), cor e ícone, **Then** a categoria passa a estar disponível para classificar
   lançamentos.
6. **Given** uma categoria existente, **When** a pessoa cria uma subcategoria dentro dela, **Then** a
   subcategoria aparece vinculada à categoria e herda sua natureza.
7. **Given** uma subcategoria, **When** a pessoa tenta criar outro nível dentro dela, **Then** a
   operação não é oferecida: a estrutura tem no máximo dois níveis.
8. **Given** uma categoria com subcategorias, **When** a pessoa a arquiva, **Then** suas subcategorias
   são arquivadas junto, para que não restem ramos órfãos.
9. **Given** uma categoria de despesa já usada, **When** a pessoa tenta mudar sua natureza para
   receita, **Then** a mudança é recusada, porque inverteria o sinal do histórico já classificado.
10. **Given** duas categorias irmãs com o mesmo nome e a mesma natureza, **When** a segunda é salva,
   **Then** o cadastro é recusado.

---

### User Story 3 - Ver o saldo consolidado no dashboard (Priority: P3)

Ao entrar, a pessoa vê no topo do dashboard quanto dinheiro tem somando todos os lugares — e não mais
um bloco vazio. Os itens Contas e Categorias aparecem navegáveis na lateral, sem o aviso de "em
breve".

**Why this priority**: É a primeira vez que o dashboard mostra um número real e cumpre a promessa de
visão consolidada do PRD §7. Depende da US1 para ter o que somar, e por isso vem depois dela.

**Independent Test**: Com duas contas cadastradas e uma arquivada, abrir o dashboard e verificar que
o saldo consolidado soma apenas as ativas; depois arquivar todas e verificar que o bloco volta ao
estado vazio.

**Acceptance Scenarios**:

1. **Given** uma pessoa com contas ativas cadastradas, **When** ela abre o dashboard, **Then** o
   bloco de saldo consolidado exibe a soma dos saldos dessas contas em Real brasileiro.
2. **Given** uma pessoa sem nenhuma conta ativa, **When** ela abre o dashboard, **Then** o bloco de
   saldo consolidado mantém o estado vazio convidando a cadastrar a primeira conta, em vez de exibir
   zero como se fosse um saldo real.
3. **Given** contas cujos saldos somados resultam em valor negativo, **When** o dashboard é aberto,
   **Then** o saldo consolidado é exibido como negativo, com destaque visual distinto de um valor
   positivo.
4. **Given** uma pessoa autenticada, **When** ela usa a navegação principal, **Then** Contas e
   Categorias levam às suas respectivas áreas, e apenas Transações e Cartões continuam sinalizados
   como indisponíveis.
5. **Given** uma pessoa autenticada, **When** ela abre o dashboard, **Then** os outros seis blocos
   continuam em estado vazio, sem números inventados.

---

### Edge Cases

- **Saldo informado com sinal negativo**: uma conta pode começar negativa (conta corrente no
  cheque especial) e isso precisa ser aceito, não tratado como erro de digitação.
- **Valor monetário em formato brasileiro**: um saldo digitado como `1.234,56` é interpretado como mil
  duzentos e trinta e quatro reais e cinquenta e seis centavos, não como `1,23456`.
- **Centavos**: valores são guardados sem perda de precisão; somar vários saldos não pode produzir
  arredondamento visível.
- **Conta arquivada e reativada**: reativar uma conta a traz de volta às listagens e ao saldo
  consolidado com o mesmo saldo que tinha.
- **Nome repetido entre uma conta ativa e uma arquivada**: permitido, porque a arquivada não concorre
  pelo mesmo papel no dia a dia.
- **Exclusão definitiva**: enquanto não houver nada vinculado a uma conta ou categoria, a exclusão é
  permitida; havendo vínculo, o sistema oferece arquivar em vez de apagar.
- **Primeira visita à área de Categorias**: a pessoa não deve ficar diante de uma tela vazia sem saber
  por onde começar.
- **Ícone ou cor fora do conjunto oferecido**: um valor não previsto é recusado, para que a interface
  não quebre nem exiba um espaço em branco.
- **Contas de outra pessoa**: nenhum identificador vindo do navegador pode alcançar dados que não
  sejam da pessoa autenticada.
- **Cartão sem conta na mesma instituição**: um cartão de crédito de um banco onde a pessoa não tem
  conta precisa caber no cadastro sem exigir uma conta inventada para sustentá-lo.
- **Sugestão de categorias aceita duas vezes**: aceitar a sugestão não pode duplicar categorias nem
  reviver as que a pessoa já arquivou.

## Requirements *(mandatory)*

### Functional Requirements

**Contas**

- **FR-001**: O sistema MUST permitir cadastrar uma conta informando nome, tipo e saldo atual.
- **FR-002**: O sistema MUST oferecer um conjunto fechado de tipos de conta que cubra conta corrente,
  poupança, carteira digital e dinheiro em espécie.
- **FR-003**: O sistema MUST permitir registrar opcionalmente a instituição financeira de uma conta.
- **FR-004**: O sistema MUST aceitar saldo negativo, zero ou positivo, com precisão de centavos e sem
  perda de valor em somas.
- **FR-005**: O sistema MUST exigir nome e tipo, recusando o cadastro incompleto com a explicação do
  que falta.
- **FR-006**: O sistema MUST impedir duas contas ativas com o mesmo nome para a mesma pessoa.
- **FR-007**: Usuários MUST ser capazes de editar nome, tipo, instituição e saldo de uma conta.
- **FR-008**: Usuários MUST ser capazes de arquivar e reativar uma conta.
- **FR-009**: Uma conta arquivada MUST deixar de aparecer nas listagens do dia a dia e de somar no
  saldo consolidado, sem ser apagada.
- **FR-010**: O sistema MUST permitir a exclusão definitiva de uma conta somente enquanto não houver
  nenhum registro vinculado a ela; havendo vínculo, MUST oferecer o arquivamento.
- **FR-011**: O sistema MUST listar as contas da pessoa com o saldo de cada uma e distinguir
  visualmente as arquivadas.
- **FR-012**: O saldo de uma conta MUST ser um atributo dela própria, informado no cadastro e
  corrigível a qualquer momento, sem depender da existência de lançamentos.
- **FR-012a**: Esta entrega MUST NOT presumir que o saldo é derivado de lançamentos. A conciliação
  entre o saldo informado e a soma das movimentações é responsabilidade da feature que introduz o
  cadastro de transações.

**Categorias**

- **FR-013**: O sistema MUST permitir cadastrar categorias informando nome, natureza, cor e ícone.
- **FR-014**: Cada categoria MUST ter natureza de despesa ou de receita, e o sistema MUST apresentá-las
  separadas por essa natureza.
- **FR-015**: O sistema MUST permitir que uma categoria tenha subcategorias, com profundidade máxima
  de dois níveis.
- **FR-016**: Uma subcategoria MUST herdar a natureza da categoria à qual pertence.
- **FR-017**: O sistema MUST oferecer conjuntos fechados de cores e de ícones, recusando valores fora
  deles.
- **FR-018**: O sistema MUST impedir duas categorias irmãs com o mesmo nome e a mesma natureza para a
  mesma pessoa.
- **FR-019**: Usuários MUST ser capazes de editar nome, cor e ícone de uma categoria.
- **FR-020**: O sistema MUST recusar a alteração da natureza de uma categoria que já tenha registros
  classificados nela.
- **FR-021**: Usuários MUST ser capazes de arquivar e reativar uma categoria, e arquivar uma categoria
  MUST arquivar suas subcategorias.
- **FR-022**: O sistema MUST permitir a exclusão definitiva de uma categoria somente enquanto não
  houver nenhum registro classificado nela nem subcategoria viva.
- **FR-023**: Uma categoria arquivada MUST permanecer legível no histórico já classificado, deixando
  de ser oferecida para novas classificações.
- **FR-024**: A lista de categorias de uma conta nova MUST nascer vazia, e a área de Categorias MUST
  oferecer, enquanto estiver vazia, a criação em um único passo de um conjunto sugerido de categorias
  comuns no Brasil, cobrindo despesa e receita.
- **FR-024a**: As categorias criadas a partir da sugestão MUST ser categorias normais da pessoa —
  editáveis, arquiváveis e excluíveis como qualquer outra — sem marca de origem que as trate de forma
  diferente.
- **FR-024b**: A oferta da sugestão MUST deixar de aparecer depois que a pessoa aceitá-la ou criar sua
  primeira categoria manualmente.

**Dashboard e navegação**

- **FR-025**: O sistema MUST exibir no bloco de saldo consolidado do dashboard a soma dos saldos de
  todas as contas ativas da pessoa que guardam dinheiro.
- **FR-026**: O sistema MUST manter o estado vazio do bloco de saldo consolidado enquanto não houver
  nenhuma conta ativa que guarde dinheiro, em vez de exibir zero.
- **FR-027**: O sistema MUST exibir saldos negativos com destaque visual distinto dos positivos.
- **FR-028**: O sistema MUST tornar Contas e Categorias acessíveis pela navegação principal, mantendo
  Transações e Cartões sinalizados como indisponíveis.
- **FR-029**: Os demais seis blocos do dashboard MUST permanecer em estado vazio nesta entrega.
- **FR-030**: O sistema MUST manter as novas telas utilizáveis em larguras a partir de 360 pixels.

**Cartões de crédito — estrutura, não cadastro**

- **FR-031**: O cadastro desta entrega MUST distinguir o que guarda dinheiro do que concede crédito,
  de modo que um cartão de crédito seja mais um registro deste mesmo cadastro — com nome, instituição
  e arquivamento idênticos aos de uma conta — e não uma entidade paralela com cadastro próprio.
- **FR-031a**: Uma linha de crédito MUST NOT somar no saldo consolidado: dívida não é dinheiro
  disponível.
- **FR-031b**: O cadastro de cartões propriamente dito — limite, dia de fechamento, dia de vencimento
  e a conta que paga a fatura — MUST ficar para a feature 003, que acrescenta esses dados ao cadastro
  criado aqui sem reescrevê-lo.
- **FR-031c**: O sistema MUST NOT tratar o cartão de débito como registro próprio: um gasto no débito,
  um PIX, uma transferência e um saque são lançamentos da conta que guarda o dinheiro, não de um
  cartão.
- **FR-031d**: Uma linha de crédito MUST poder existir sem vínculo com nenhuma conta, porque é comum
  ter cartão de crédito de uma instituição onde não se mantém conta.

**Privacidade e integridade**

- **FR-032**: Toda conta e toda categoria MUST pertencer a uma única pessoa, e toda consulta a elas
  MUST partir da pessoa autenticada, nunca de um identificador informado pelo navegador.
- **FR-033**: Uma tentativa de acessar conta ou categoria de outra pessoa MUST ser negada sem revelar
  que o registro existe.
- **FR-034**: Nomes de conta, instituições e saldos MUST NOT aparecer em registros de log nem em
  relatórios de erro.
- **FR-035**: O sistema MUST exibir valores monetários em Real brasileiro, com a formatação usada no
  Brasil, e MUST aceitar entrada nesse mesmo formato.

### Key Entities

- **Conta**: um lugar de onde o dinheiro da pessoa entra e sai. Guarda nome, tipo, instituição
  opcional, saldo e situação (ativa ou arquivada), e pertence a um usuário. Divide-se em duas
  naturezas: as que **guardam dinheiro** (conta corrente, poupança, carteira digital, espécie), que
  somam no patrimônio, e as que **concedem crédito** (cartão de crédito), que representam dívida e
  cujo cadastro completo chega na feature 003. As duas naturezas compartilham o mesmo cadastro.
- **Categoria**: um rótulo com que a pessoa classifica seus lançamentos. Guarda nome, natureza
  (despesa ou receita), cor, ícone, situação (ativa ou arquivada) e, quando é subcategoria, a
  categoria de que faz parte. Pertence a um usuário.
- **Saldo consolidado**: valor derivado, não armazenado — a soma dos saldos das contas ativas que
  guardam dinheiro, em um instante. Linhas de crédito não entram nessa soma.
- **Conjunto sugerido de categorias**: uma lista fixa definida pelo produto, oferecida apenas enquanto
  a pessoa não tem categoria nenhuma. Não é uma entidade persistida: ao ser aceita, vira categorias
  comuns da pessoa.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Uma pessoa que acabou de criar sua conta no SIMI cadastra suas três primeiras contas
  financeiras em menos de 3 minutos, sem ajuda externa.
- **SC-002**: Uma pessoa monta uma estrutura de categorias com duas categorias e quatro subcategorias
  em menos de 5 minutos.
- **SC-003**: O saldo consolidado exibido no dashboard é igual à soma dos saldos das contas ativas que
  guardam dinheiro em 100% dos casos, incluindo saldos negativos e valores com centavos.
- **SC-004**: Nenhuma tentativa de acessar conta ou categoria de outra pessoa retorna dado algum, em
  100% das tentativas.
- **SC-005**: Nenhum nome de conta, instituição ou saldo aparece nos registros de log ou relatórios de
  erro gerados durante os fluxos desta entrega.
- **SC-006**: Arquivar uma conta ou categoria nunca resulta em perda de dado: 100% dos registros
  arquivados podem ser reativados com o mesmo conteúdo.
- **SC-007**: As telas de Contas e Categorias permanecem legíveis e operáveis em larguras de 360 a
  1920 pixels.
- **SC-008**: Todos os fluxos desta entrega são cobertos por testes automatizados que passam antes de
  a entrega ser considerada concluída.

## Assumptions

- **Autenticação reaproveitada**: a Fase 1 já entrega conta de usuário, sessão e layout autenticado;
  esta feature apenas pendura dados nela.
- **Moeda única**: todos os valores são em Real brasileiro. Multimoeda não aparece no escopo do MVP
  (PRD §9) e fica fora desta entrega.
- **Dois níveis de categoria**: o PRD §9 fala em "Categorias" e "Subcategorias" — dois níveis,
  interpretados aqui como limite e não como ponto de partida de uma árvore arbitrária.
- **Tipos de conta fechados**: a lista deriva de "Bancos/Contas" e "Carteiras" do PRD §9; abrir para
  texto livre impediria agrupar contas por tipo em relatórios futuros.
- **Cores e ícones de um conjunto fixo**: a escolha vem de uma paleta e de um conjunto de ícones
  definidos pelo produto, não de entrada livre, para manter a interface minimalista coerente.
- **Arquivar é a regra, excluir é exceção**: dado financeiro não se apaga quando há histórico; a
  exclusão existe apenas para corrigir um cadastro recém-criado.
- **Contas e cartões no mesmo cadastro**: a contabilidade trata tanto uma conta bancária quanto um
  cartão de crédito como contas — uma de ativo, outra de passivo —, e é assim que esta spec os
  organiza. A forma técnica de representar isso é decidida em `research.md`/`plan.md`, não aqui.
- **Cartão de débito não é entidade**: o cartão de débito é apenas um canal de acesso ao dinheiro que
  já está na conta; modelá-lo separadamente criaria um registro sem saldo, sem fatura e sem
  comportamento próprio.
- **Projetos ficam fora**: o bloco "Despesas por projeto" do dashboard continua vazio. Projeto
  (viagem, reforma) é uma forma de agrupar lançamentos, não uma categoria, e não aparece na lista da
  Fase 2 do roadmap.
- **Nada de categorização automática**: regras explícitas e sugestão por similaridade semântica são
  Fase 5 (PRD §11). Esta feature entrega apenas o vocabulário manual.
- **Transações, Cartões, Pesquisa e Filtros ficam fora**: são as features 003 e 004. Onde esta spec
  menciona "registros vinculados" ou "lançamentos classificados", trata-se de preparar a regra, não
  de implementar o cadastro deles.
