# SIMI

## Stack

- Ruby `4.0.6`
- Rails `8.1.3`
- PostgreSQL `18`

## UI / Frontend

- TailwindCSS
- Phlex (ViewComponent) [Docs](https://www.phlex.fun/introduction/)
- RubyUI (Component Library) [Docs](https://www.rubyui.com/docs/introduction)

## Tests

- Rspec
- FactoryBot
- FFaker (refactor of faker) [reference](https://github.com/ffaker/ffaker/blob/main/REFERENCE.md)

## AI / Embeddings
- RubyLLM
- Development -> Local Models (Ollama/Docker)

## Mail

- Mailtip for development/test
- Resend for production

## Authentication
- Rails Authenticate (https://guides.rubyonrails.org/security.html)

## Infra / Observability

- Docker / Docker compose
- Sentry
- Github Actions (CI/CD)
- Kamal
- Cloudflare R2 (Storage Prod) -> Free tier and S3 compatible

## Cadastro fechado

SIMI é um produto pessoal: só se cadastra quem está numa lista explícita.

`SIMI_ALLOWED_SIGNUP_EMAILS` guarda os endereços liberados, separados por vírgula
ou por quebra de linha. A variável não tem padrão permissivo — **vazia ou ausente,
ninguém consegue criar conta**, e é assim que a aplicação sobe se você esquecer
de configurá-la.

```
SIMI_ALLOWED_SIGNUP_EMAILS=voce@exemplo.com,outra.pessoa@exemplo.com
```

Em desenvolvimento ela vem do `.env` (veja `.env.example`); em produção precisa
chegar pelo ambiente do Kamal. Um endereço fora da lista recebe a mesma resposta
de um cadastro aceito, sem criar conta nem enviar e-mail — a tela nunca revela
quem está ou não autorizado.
