# PRD --- SIMI

**Versão:** 1.1
**Status:** Em elaboração
**Produto:** SIMI
**Tipo:** Plataforma de Gestão Financeira Pessoal

---

# 1. Visão do Produto

## Visão

O **SIMI** é uma plataforma de gestão financeira pessoal projetada para
fornecer clareza, organização e inteligência sobre toda a vida
financeira do usuário.

Mais do que controlar receitas e despesas, o SIMI busca consolidar todas
as informações financeiras em um único ambiente, permitindo compreender
hábitos, registrar gastos em viagens, acompanhar a evolução patrimonial, identificar oportunidades de
economia e apoiar decisões financeiras melhores.

## Missão

Permitir que qualquer pessoa compreenda e controle sua vida financeira de forma
simples e inteligente.

## Propósito

Transformar dados financeiros dispersos em informações claras,
organizadas e úteis para tomada de decisão.

## Visão de Longo Prazo

Ser uma plataforma capaz de centralizar toda a vida financeira do
usuário.

No futuro, o SIMI deverá permitir controlar:

- Contas bancárias
- Cartões de crédito
- Receitas
- Despesas
- Patrimônio
- Investimentos
- Assinaturas
- Parcelamentos
- Open Finance/Carteiras digitais

---

# 2. Problema

Hoje a maioria das pessoas possui informações financeiras distribuídas
entre diferentes instituições financeiras.

É comum possuir:

- Múltiplos bancos
- Diversos cartões
- Investimentos
- Carteiras digitais
- Planilhas
- Aplicativos distintos

Como consequência:

- Não existe visão consolidada;
- É difícil entender para onde o dinheiro está indo;
- Controlar gastos exige esforço manual;
- Aplicativos existentes possuem baixa flexibilidade ou dependem de
  sincronizações específicas;
- Muitos usuários deixam de acompanhar sua vida financeira por
  considerarem o processo complexo.

---

# 3. Solução

O SIMI centraliza todas essas informações em uma única plataforma.

Através da importação de extratos bancários, categorização automática,
dashboards e pesquisas inteligentes, o usuário passa a compreender
rapidamente sua situação financeira.

O objetivo do sistema não é apenas registrar transações.

O objetivo é transformar dados financeiros em conhecimento.

---

# 4. Objetivos do Produto

## Objetivo Principal

Fornecer uma visão completa da vida financeira do usuário.

## Objetivos Secundários

- Centralizar informações financeiras
- Automatizar tarefas repetitivas
- Reduzir trabalho manual
- Facilitar acompanhamento financeiro
- Auxiliar planejamento financeiro
- Gerar confiança sobre os próprios dados

---

# 5. Público-Alvo

## MVP

Usuários que desejam controlar melhor sua vida financeira através da
importação de extratos bancários e categorização automática.

Inicialmente, o próprio desenvolvedor será o principal usuário,
permitindo evolução contínua baseada em uso real.

## Futuro

Pessoas físicas que:

- Possuem contas em diferentes bancos
- Utilizam múltiplos cartões
- Desejam maior organização financeira
- Preferem uma solução simples e intuitiva

---

# 6. Princípios do Produto

- Clareza
- Simplicidade
- Organização
- Inteligência
- Performance
- Privacidade
- Evolução Contínua

---

# 7. Proposta de Valor

O SIMI permite que o usuário concentre toda sua vida financeira em um
único ambiente.

Em poucos minutos deve ser possível responder perguntas como:

- Quanto gastei em restaurantes este ano?
- Quanto pago por mês em assinaturas?
- Qual banco utilizo mais?
- Como meus gastos evoluíram?
- Onde posso economizar?
- Quanto gastei em determinada viagem?

---

# 8. Diferenciais

- Importação inteligente de PDF e CSV, com **reconciliação automática** contra lançamentos já registrados (manual, Telegram, ou outras origens), evitando duplicidade
- Categorização automática, combinando regras explícitas do usuário com sugestão por similaridade semântica quando não há regra aplicável
- Pesquisa global rápida (inclui busca textual/semântica sobre a descrição das transações)
- Interface minimalista
- Evolução baseada em dados
- Múltiplos pontos de entrada de gastos (importação, cadastro manual, bot/assistente via Telegram, e futuramente Open Finance e carteiras digitais) tratados de forma unificada

---

# 9. Escopo do MVP

## Autenticação

- Cadastro
- Login
- Link para confirmacao de cadastro/login
- Recuperação de senha

## Dashboard

- Saldo consolidado
- Receitas do mês
- Despesas do mês
- Despesas por projeto (viagem, reforma, etc)
- Evolução mensal
- Gastos por categoria
- Últimas movimentações

## Contas

- Bancos/Contas
- Carteiras

## Cartões

- Cadastro
- Limites
- Fechamento
- Vencimento

## Transações

- CRUD
- Busca
- Filtros
- Tags
- Observações
- Origem da transação rastreável (`source`: manual, importação, Telegram — extensível para Open Finance/carteiras digitais no futuro)

## Categorias

- Categorias
- Subcategorias
- Ícones
- Cores
- Regras de categorização automática (correspondência exata/por padrão)
- Sugestão de categoria por similaridade semântica (embedding), usada como fallback quando nenhuma regra é aplicável

## Importações

- PDF
- CSV
- **Reconciliação de duplicidade:** correspondência por valor exato + janela de data; em caso de mais de um candidato, desempate por similaridade semântica da descrição (embedding)

## Assistente Conversacional

- Chat com IA generativa (RubyLLM) sobre os dados financeiros do usuário
- Automações via tools/agentes (ex.: consulta de gastos por período/categoria, busca de transações por descrição, registro de gasto via linguagem natural)
- Reutilizando o mesmo modelo de dados e regras de reconciliação/categorização já definidos para as demais origens de transação

## Configurações

- Perfil
- Preferências
- Tema

---

# 10. Fora do Escopo (MVP)

- Open Finance (sincronização automática e carga histórica via API bancária)
- Investimentos
- Criptomoedas
- Gestão patrimonial
- Compartilhamento entre usuários
- Metas

---

# 11. Roadmap

## Fase 1 --- Fundação

- Autenticação
- Layout principal
- Tema claro/escuro
- Navegação
- Dashboard inicial

## Fase 2 --- Núcleo Financeiro

- Contas
- Cartões
- Categorias
- Transações
- Pesquisa
- Filtros

## Fase 3 --- Importação Inteligente

- PDF
- CSV
- Validação
- **Reconciliação de duplicidade** (valor + data + desempate por embedding via RubyLLM)
- Geração de embedding da descrição no momento em que a transação é salva (independente da origem)
- Histórico de importações

## Fase 4 --- Insights

- Gráficos
- Evolução mensal
- Distribuição por categorias
- Comparativos
- Relatórios
- Busca semântica sobre transações (ex.: "gastos parecidos com esse")

## Fase 5 --- Automação

- Regras automáticas
- Categorização inteligente (regras explícitas + fallback por similaridade semântica)
- Recorrências
- Assinaturas (detecção via agrupamento de comerciante por embedding + regularidade de valor/data)
- Assistente conversacional (RubyLLM chat + tools) e registro de gastos via bot/Telegram

## Fase 6 --- Plataforma Financeira

- Patrimônio
- Investimentos
- Open Finance (incluindo carga histórica em lote — único cenário do produto onde concorrência via `async`/Fiber se justifica, dado o volume potencialmente alto de transações importadas de uma vez)
- Compartilhamento familiar

---

# 12. Critérios de Sucesso

O MVP será considerado bem-sucedido quando permitir que o usuário:

- Importe extratos de diferentes bancos sem perda de dados;
- Encontre qualquer transação rapidamente;
- Acompanhe sua evolução financeira pelo dashboard;
- Categorize automaticamente a maior parte das transações recorrentes;
- Reconcilie automaticamente a maior parte das transações já lançadas manualmente (ou via Telegram) contra o extrato importado, sem duplicar registros;
- Deixe de depender de planilhas, notas e cadernos.

---

# 13. Arquitetura de Dados e IA (nova)

## Camada de IA

- **RubyLLM** é adotado como camada única de acesso a modelos de IA — embeddings (deduplicação/categorização) e chat/tools (assistente conversacional) desde o MVP —, evitando manter integrações distintas para cada capability.
- **pgvector** (via gem `neighbor`) é o mecanismo de armazenamento e busca vetorial, integrado diretamente ao Postgres já usado pela aplicação — sem necessidade de infraestrutura de banco vetorial separada.

## Estratégia de deduplicação/reconciliação

1. Filtro primário: valor exato + janela de data (±2-3 dias) — resolve a maioria dos casos sem custo de API.
2. Desempate (somente quando há mais de um candidato): similaridade semântica da descrição via embedding.
3. Abaixo de um limiar de confiança na comparação, a reconciliação não é automática — o usuário confirma manualmente, para evitar duplicar ou mesclar gastos incorretamente.

## Concorrência (async/Fiber)

- Para os volumes típicos do MVP (extrato mensal de conta/cartão, ~20-150 transações; lançamento manual ou via Telegram, unitário), o processamento **sequencial** de embeddings é suficiente — geração em lote numa única chamada por importação.
- `async`/Fiber e semáforos de rate limit ficam reservados para cenários de volume alto e concorrente, especificamente a carga histórica inicial do Open Finance (Fase 6), quando múltiplas contas podem ser importadas ao mesmo tempo.

## Rastreabilidade de origem

- Toda transação carrega um campo de origem (`source`), permitindo que qualquer ponto de entrada futuro (Open Finance, Apple Pay, Google Pay) se beneficie da mesma lógica de embedding/categorização/reconciliação já implementada, sem código duplicado por canal.
