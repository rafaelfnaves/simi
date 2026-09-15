# Feature Specification: Fundação — Acesso, Navegação e Dashboard Inicial

**Feature Branch**: `001-fundacao`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "Fundação do SIMI: autenticação completa (cadastro, login, confirmação de cadastro por link enviado por e-mail, recuperação de senha, logout), layout principal autenticado com sidebar de navegação e topbar, tema claro/escuro persistido, e dashboard inicial montando os blocos do PRD §9 (saldo consolidado, receitas do mês, despesas do mês, gastos por categoria, despesas por projeto, evolução mensal, últimas movimentações) em estado vazio, mais uma página de perfil em Configurações. Corresponde à Fase 1 — Fundação do roadmap em docs/PRD.md."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Criar conta e entrar no SIMI (Priority: P1)

Uma pessoa que decidiu organizar sua vida financeira chega ao SIMI, informa nome, e-mail e senha, e
recebe um e-mail com um link de confirmação. Ao clicar no link, sua conta é confirmada e ela entra
direto na área privada. Nas visitas seguintes, entra com e-mail e senha e sai quando quiser.

**Why this priority**: Sem uma conta confirmada não existe área privada, e sem área privada nenhum
dado financeiro pode ser guardado. Todo o resto do produto depende deste fluxo.

**Independent Test**: Pode ser testado inteiro sem nenhuma outra história — cadastrar, confirmar
pelo link do e-mail, sair, entrar de novo — e já entrega o valor de ter um espaço privado e
identificado.

**Acceptance Scenarios**:

1. **Given** uma pessoa sem conta cujo e-mail consta na lista de autorizados, **When** ela informa
   nome, e-mail e senha válidos, **Then** a conta é criada e um e-mail com o link de confirmação é
   enviado para o endereço informado.
2. **Given** uma pessoa cujo e-mail não consta na lista de autorizados, **When** ela tenta se
   cadastrar, **Then** nenhuma conta é criada e a resposta não revela o motivo da recusa.
3. **Given** uma conta recém-criada e não confirmada, **When** a pessoa abre o link de confirmação,
   **Then** a conta passa a constar como confirmada e ela é levada ao dashboard já autenticada.
4. **Given** uma conta confirmada, **When** a pessoa informa e-mail e senha corretos, **Then** ela é
   autenticada e levada ao dashboard.
5. **Given** uma conta ainda não confirmada, **When** a pessoa informa e-mail e senha corretos,
   **Then** a sessão não é aberta e ela recebe a opção de reenviar o link de confirmação.
6. **Given** uma conta confirmada, **When** a pessoa informa a senha errada, **Then** o acesso é
   negado com uma mensagem que não revela se o e-mail existe.
7. **Given** uma pessoa autenticada, **When** ela sai da aplicação, **Then** a sessão é encerrada e
   qualquer página privada volta a exigir autenticação.
8. **Given** um e-mail já cadastrado, **When** alguém tenta se cadastrar com o mesmo e-mail,
   **Then** nenhuma conta duplicada é criada e a resposta não confirma que aquele e-mail já existe.

---

### User Story 2 - Recuperar o acesso (Priority: P2)

Quem esqueceu a senha informa o e-mail, recebe um link de redefinição e escolhe uma nova senha, sem
depender de suporte.

**Why this priority**: Perder a senha bloqueia o acesso a todo o histórico financeiro. É o segundo
fluxo mais crítico, mas o produto já é utilizável sem ele.

**Independent Test**: Com uma conta existente, pedir a redefinição, abrir o link do e-mail, definir
uma senha nova e entrar com ela.

**Acceptance Scenarios**:

1. **Given** uma conta existente, **When** a pessoa pede a redefinição informando seu e-mail,
   **Then** um e-mail com o link de redefinição é enviado.
2. **Given** um e-mail que não pertence a nenhuma conta, **When** a redefinição é solicitada,
   **Then** a resposta é idêntica à do caso anterior e nenhum e-mail é enviado.
3. **Given** um link de redefinição válido, **When** a pessoa define uma nova senha, **Then** ela
   consegue entrar com a nova senha e a antiga deixa de funcionar.
4. **Given** um link de redefinição expirado ou já utilizado, **When** a pessoa o abre, **Then** o
   sistema recusa a redefinição e oferece solicitar um novo link.

---

### User Story 3 - Enxergar a estrutura da vida financeira (Priority: P3)

Ao entrar, a pessoa encontra um dashboard que já mostra como suas informações serão organizadas —
saldo consolidado, receitas e despesas do mês, gastos por categoria, despesas por projeto, evolução
mensal e últimas movimentações — e uma navegação lateral com as áreas do produto. Como ainda não há
lançamentos, cada bloco explica o que aparecerá ali e o que fazer para começar.

**Why this priority**: Estabelece a casca do produto e a promessa de valor do PRD, e é o alicerce
sobre o qual a Fase 2 apenas ligará os dados reais.

**Independent Test**: Entrar com uma conta sem nenhum lançamento e verificar que os sete blocos
aparecem em estado vazio, que a navegação leva às áreas previstas e que a página funciona em tela de
celular.

**Acceptance Scenarios**:

1. **Given** uma pessoa autenticada sem lançamentos, **When** ela abre o dashboard, **Then** os sete
   blocos previstos são exibidos, cada um com um estado vazio explicativo em vez de números falsos.
2. **Given** uma pessoa autenticada, **When** ela usa a navegação principal, **Then** enxerga as
   áreas do produto e distingue claramente as que ainda não estão disponíveis.
3. **Given** uma pessoa não autenticada, **When** ela tenta abrir o dashboard diretamente pela URL,
   **Then** é levada à tela de entrada e, após autenticar, retorna ao endereço que havia pedido.
4. **Given** uma tela estreita de celular, **When** o dashboard é aberto, **Then** o conteúdo
   permanece legível e a navegação continua acessível.

---

### User Story 4 - Ajustar perfil e aparência (Priority: P4)

A pessoa abre Configurações, corrige seu nome, confere seu e-mail e fuso horário, e escolhe entre
tema claro, escuro ou o do sistema. A escolha vale nas próximas visitas e em qualquer dispositivo.

**Why this priority**: Melhora o uso diário e cumpre o item "Configurações" do PRD, mas nenhum outro
fluxo depende dela.

**Independent Test**: Alterar nome e tema, recarregar a página e entrar de outro navegador para
confirmar que as preferências acompanharam a conta.

**Acceptance Scenarios**:

1. **Given** uma pessoa autenticada, **When** ela altera seu nome no perfil, **Then** o novo nome é
   salvo e passa a aparecer na navegação.
2. **Given** uma pessoa autenticada, **When** ela escolhe o tema escuro, **Then** a aparência muda
   imediatamente e continua escura após recarregar e em uma nova sessão.
3. **Given** uma pessoa com o tema definido como "sistema", **When** o dispositivo está em modo
   escuro, **Then** a aplicação é exibida em modo escuro.
4. **Given** uma pessoa autenticada, **When** ela abre o perfil, **Then** encontra um caminho para
   alterar a própria senha.

---

### Edge Cases

- **Link de confirmação expirado**: a pessoa vê que o link não vale mais e pode pedir o reenvio
  informando o e-mail, sem recomeçar o cadastro.
- **Link de confirmação já usado**: abrir um link já consumido não muda nada na conta; se a pessoa
  estiver autenticada, é levada ao dashboard; se não, à tela de entrada.
- **Cadastro com e-mail já existente**: nenhuma conta nova é criada, nenhuma senha existente é
  alterada, e a resposta não permite descobrir quais e-mails estão cadastrados.
- **Variações de caixa e espaços no e-mail**: `Maria@Exemplo.com ` e `maria@exemplo.com` identificam
  a mesma conta, tanto no cadastro quanto na entrada.
- **Tentativa de entrar sem confirmar**: as credenciais corretas não abrem sessão; a pessoa é
  informada de que precisa confirmar o e-mail e pode pedir o reenvio do link ali mesmo.
- **Lista de autorizados vazia ou não configurada**: nenhum cadastro é aceito, e o ambiente sinaliza
  a falta de configuração em vez de liberar o acesso silenciosamente.
- **Sessão encerrada em outro dispositivo**: uma sessão revogada deixa de dar acesso na próxima
  requisição, sem exibir dados da conta.
- **Senha nova igual à antiga ou fora da política**: a redefinição é recusada com uma explicação do
  que é exigido.
- **Aparência no primeiro carregamento**: a página não pode piscar no tema errado antes de assumir o
  tema escolhido.
- **Sem conexão com o serviço de e-mail**: a falha no envio não deixa a conta em estado inconsistente
  e a pessoa consegue solicitar o reenvio.

## Requirements *(mandatory)*

### Functional Requirements

**Cadastro e confirmação**

- **FR-001**: O sistema MUST permitir a criação de uma conta a partir de nome, e-mail e senha.
- **FR-002**: O sistema MUST tratar o e-mail como identificador único da conta, ignorando diferenças
  de caixa e espaços nas extremidades.
- **FR-003**: O sistema MUST exigir uma senha com no mínimo 8 caracteres e recusar senhas mais curtas
  explicando o requisito.
- **FR-004**: O sistema MUST enviar, na criação da conta, um e-mail contendo um link de confirmação
  de uso único.
- **FR-005**: O link de confirmação MUST perder a validade após 24 horas.
- **FR-006**: O sistema MUST, ao consumir um link de confirmação válido, marcar a conta como
  confirmada e autenticar a pessoa.
- **FR-007**: O sistema MUST permitir solicitar o reenvio do link de confirmação.
- **FR-008**: O sistema MUST recusar a entrada de uma conta ainda não confirmada, explicando que a
  confirmação é necessária e oferecendo o reenvio do link no mesmo lugar.
- **FR-009**: O sistema MUST aceitar cadastros apenas de endereços que constem em uma lista de
  e-mails autorizados, definida fora do código e ajustável sem nova publicação.
- **FR-009a**: Uma tentativa de cadastro com e-mail fora da lista autorizada MUST ser recusada sem
  revelar que existe uma lista nem quem está nela, e MUST responder de forma indistinguível de uma
  tentativa com e-mail já cadastrado.

**Entrada e sessão**

- **FR-010**: O sistema MUST autenticar por e-mail e senha.
- **FR-011**: O sistema MUST responder a credenciais inválidas sem revelar se o e-mail existe.
- **FR-012**: O sistema MUST manter a sessão entre visitas até que a pessoa saia explicitamente.
- **FR-013**: O sistema MUST permitir encerrar a sessão a qualquer momento.
- **FR-014**: O sistema MUST registrar, para cada sessão, a origem do acesso, de modo que sessões
  possam ser auditadas e revogadas no futuro.
- **FR-015**: O sistema MUST exigir autenticação em todas as páginas exceto entrada, cadastro,
  confirmação, recuperação de senha e o endpoint de saúde.
- **FR-016**: O sistema MUST, após autenticar alguém que tentou abrir uma página privada, levá-la ao
  endereço originalmente pedido.

**Recuperação de senha**

- **FR-017**: O sistema MUST permitir solicitar a redefinição de senha informando o e-mail.
- **FR-018**: O sistema MUST responder à solicitação de redefinição de forma idêntica, exista ou não
  uma conta com aquele e-mail.
- **FR-019**: O link de redefinição MUST ser de uso único e perder a validade após 15 minutos.
- **FR-020**: O sistema MUST invalidar o link de redefinição assim que a senha for alterada.

**Navegação e dashboard**

- **FR-021**: O sistema MUST apresentar, em toda página autenticada, uma navegação principal com as
  áreas Dashboard, Transações, Contas, Cartões, Categorias e Configurações, sinalizando quais ainda
  não estão disponíveis.
- **FR-022**: O sistema MUST exibir no dashboard os sete blocos do PRD §9: saldo consolidado,
  receitas do mês, despesas do mês, gastos por categoria, despesas por projeto, evolução mensal e
  últimas movimentações.
- **FR-023**: Cada bloco do dashboard sem dados MUST exibir um estado vazio que explique o que
  aparecerá ali, em vez de valores fictícios ou de exemplo.
- **FR-024**: O sistema MUST exibir valores monetários em Real brasileiro, com a formatação usada no
  Brasil.
- **FR-025**: O sistema MUST permanecer utilizável em telas a partir de 360 pixels de largura.
- **FR-026**: O sistema MUST identificar a pessoa autenticada na navegação e oferecer ali o acesso ao
  perfil e à saída.

**Perfil e aparência**

- **FR-027**: O sistema MUST permitir alterar nome e fuso horário no perfil.
- **FR-028**: O sistema MUST permitir escolher entre tema claro, escuro e o do sistema.
- **FR-029**: O sistema MUST vincular a preferência de tema à conta, de modo que ela acompanhe a
  pessoa em qualquer dispositivo onde ela se autentique.
- **FR-030**: O sistema MUST aplicar o tema escolhido já no primeiro desenho da página, sem exibir
  momentaneamente o tema errado.
- **FR-031**: O sistema MUST oferecer, a partir do perfil, um caminho para alterar a própria senha.

**Privacidade**

- **FR-032**: O sistema MUST manter senhas apenas em forma irreversível, nunca recuperável.
- **FR-033**: O sistema MUST impedir que e-mails, senhas e tokens apareçam em registros de log ou em
  relatórios de erro.
- **FR-034**: Toda consulta a dados de uma conta MUST partir da pessoa autenticada, nunca de um
  identificador informado pelo navegador.
- **FR-035**: O conteúdo de um e-mail transacional MUST se limitar ao necessário para a ação, sem
  incluir senha ou dados financeiros.

### Key Entities

- **Usuário**: a pessoa dona dos dados financeiros. Guarda nome, e-mail (único), a forma
  irreversível da senha, o momento da confirmação do cadastro e as preferências de fuso horário e
  tema.
- **Sessão**: um acesso ativo de um usuário a partir de um dispositivo. Guarda a origem do acesso e
  o momento em que foi criada, e pode ser encerrada.
- **Link de confirmação**: concessão temporária e de uso único, derivada do usuário, que comprova a
  posse do e-mail informado. Expira em 24 horas.
- **Link de redefinição**: concessão temporária e de uso único, derivada do usuário, que autoriza a
  troca de senha. Expira em 15 minutos e é invalidada ao ser usada.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Uma pessoa sem conta consegue se cadastrar, confirmar o e-mail e chegar ao dashboard em
  menos de 3 minutos, sem ajuda externa.
- **SC-002**: Quem esqueceu a senha volta a acessar a conta em menos de 2 minutos a partir do pedido
  de redefinição.
- **SC-003**: Nenhuma resposta do sistema — mensagem, redirecionamento ou tempo de resposta — permite
  descobrir se um determinado e-mail possui conta.
- **SC-004**: Qualquer página privada aberta sem autenticação leva à tela de entrada em 100% das
  tentativas, sem exibir qualquer dado da conta.
- **SC-005**: O dashboard e todas as telas de acesso permanecem legíveis e operáveis em larguras de
  360 a 1920 pixels.
- **SC-006**: A preferência de tema é respeitada em 100% dos carregamentos, sem exibição momentânea
  do tema anterior.
- **SC-007**: Nenhum e-mail, senha ou token aparece nos registros de log ou nos relatórios de erro
  gerados durante os fluxos de cadastro, entrada e recuperação.
- **SC-008**: Todos os fluxos desta entrega são cobertos por testes automatizados que passam antes de
  a entrega ser considerada concluída.

## Assumptions

- O SIMI é, nesta fase, uma aplicação de uso individual: cada conta enxerga apenas os próprios dados
  e não há compartilhamento, times ou papéis distintos. Compartilhamento está fora do MVP
  (docs/PRD.md §10).
- Nenhum dado financeiro existe ainda. Os blocos do dashboard são a casca definitiva; a Fase 2 apenas
  substituirá os estados vazios por dados reais, sem redesenhar a página.
- Autenticação por e-mail e senha é suficiente. Login social, segundo fator e chaves de acesso estão
  fora desta entrega.
- O idioma da interface é o português do Brasil, a moeda é o Real e o fuso horário padrão é
  `America/Sao_Paulo`.
- Os e-mails transacionais são entregues pela infraestrutura de e-mail já configurada no projeto;
  esta entrega não escolhe nem configura um novo provedor.
- As áreas Transações, Contas, Cartões e Categorias aparecem na navegação como destinos previstos,
  mas sua implementação pertence à Fase 2.
- Limitação de tentativas de entrada e bloqueio por força bruta não fazem parte desta entrega; a
  proteção nesta fase se apoia na política de senha, nos prazos curtos dos links e na lista de
  cadastros autorizados.
- A lista de e-mails autorizados atende à observação do PRD §5 de que, no início, o próprio
  desenvolvedor é o usuário principal. Abrir o cadastro depois é remover essa checagem, sem outras
  mudanças no fluxo.
