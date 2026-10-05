# Specification Quality Checklist: Contas e Categorias — Cadastros do Núcleo Financeiro

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-10-05
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- Items marked incomplete require spec updates before `/speckit-clarify` or `/speckit-plan`

### Iteração 1 — 2026-10-05

Três marcadores `[NEEDS CLARIFICATION]` foram abertos, todos com impacto em escopo e sem padrão
razoável que pudesse ser assumido sem consultar o dono do produto. Todos resolvidos na mesma data:

- **FR-012** — saldo de abertura. **Decisão: atributo da própria conta**, informado e corrigível,
  para que esta fatia não dependa do cadastro de transações. A conciliação entre saldo informado e
  soma dos lançamentos fica registrada em FR-012a como responsabilidade da feature 003.
- **FR-024** — categorias iniciais. **Decisão: oferta na tela vazia**, não semeadura automática. A
  conta nova nasce sem categorias e a área oferece criar o conjunto sugerido em um passo, enquanto a
  lista estiver vazia.
- **FR-031** — cartão de crédito. **Decisão: mesmo cadastro das contas**, com a distinção entre o que
  guarda dinheiro e o que concede crédito. O cartão de débito não é entidade — débito, PIX,
  transferência e saque são lançamentos da conta. O cadastro de limite, fechamento, vencimento e
  conta pagadora fica para a feature 003. A forma técnica (STI sobre uma tabela `accounts`, com
  `delegated_type` como saída se os campos de cartão crescerem) está analisada em
  [research.md](../research.md) D1.

As escolhas sem impacto de escopo — moeda única, dois níveis de categoria, tipos de conta fechados,
paleta e ícones fixos, arquivar em vez de excluir, projetos fora do escopo — estão registradas em
**Assumptions** na spec, em vez de abertas como pergunta.

Demais itens revisados e aprovados. Nenhum item pendente: a spec está pronta para `/speckit-plan`.
