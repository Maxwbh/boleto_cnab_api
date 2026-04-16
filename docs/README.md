# Documentação — Boleto CNAB API

> **Versão:** 1.3.0

Documentação técnica da Boleto CNAB API — REST API para geração de boletos, CNAB (remessa/retorno) e parsing de extratos OFX.

## Início Rápido

- [README do projeto](../README.md) — Overview, quick start, exemplos
- [DEPLOY.md](../DEPLOY.md) — Guia de deploy no Render.com
- [CHANGELOG.md](../CHANGELOG.md) — Histórico de versões
- [CONTRIBUTING.md](../CONTRIBUTING.md) — Como contribuir

## Referência da API

| Recurso | Descrição |
|---------|-----------|
| [openapi.yaml](./openapi.yaml) | Especificação OpenAPI 3.0 completa |
| [api/troubleshooting.md](./api/troubleshooting.md) | Solução de problemas comuns |
| [api/ofx-parsing.md](./api/ofx-parsing.md) | Guia detalhado do endpoint OFX |
| [api/pix.md](./api/pix.md) | Guia de PIX híbrido em boletos |

### Endpoints

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/api/health` | GET | Health check |
| `/api/boleto/validate` | GET | Validar dados do boleto |
| `/api/boleto/data` | GET | Obter dados calculados |
| `/api/boleto/nosso_numero` | GET | Gerar nosso_numero |
| `/api/boleto` | GET | Gerar boleto (PDF/JPG/PNG/TIF) |
| `/api/boleto/multi` | POST | Gerar múltiplos boletos |
| `/api/remessa` | POST | Gerar arquivo de remessa CNAB |
| `/api/retorno` | POST | Processar arquivo de retorno CNAB |
| `/api/ofx/parse` | POST | Parsear extrato bancário OFX |

## Arquitetura

- [ARCHITECTURE.md](./ARCHITECTURE.md) — Estrutura modular, services, middleware, fluxos
- [development/brcobranca-fork.md](./development/brcobranca-fork.md) — Detalhes da gem brcobranca

## Guia de Campos por Banco

- [fields/README.md](./fields/README.md) — Overview dos campos
- [fields/all-banks.md](./fields/all-banks.md) — Compatibilidade por banco
- [fields/examples.md](./fields/examples.md) — Exemplos práticos de payloads

## Cliente Python

- [python-client/README.md](../python-client/README.md) — Cliente Python oficial
- [examples/python/](../examples/python/) — Exemplos executáveis

## Recursos Externos

- [brcobranca (fork @maxwbh)](https://github.com/Maxwbh/brcobranca) — Gem Ruby de boletos
- [ofx gem](https://github.com/amaurysilva/ofx) — Gem Ruby de parsing OFX
- [OpenAPI 3.0 Specification](https://spec.openapis.org/oas/v3.0.3)

---

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) - M&S do Brasil LTDA
