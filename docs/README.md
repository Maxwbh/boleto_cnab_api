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

| Endpoint | Método | Retorno |
|----------|--------|---------|
| `/api/health` | GET | `{"status": "OK"}` |
| `/api/info` | GET | Versao, bancos, formatos |
| `/api/metadata` | GET | Versao API + gem, lista de endpoints |
| `/api/bancos` | GET | 18 bancos com capacidades (boleto, CNAB, PIX, carteiras) |
| `/api/boleto/validate` | GET | `{"valid": true}` ou erros |
| `/api/boleto/data` | GET | JSON com `nosso_numero`, `nosso_numero_formatado`, `nosso_numero_dv`, `codigo_barras`, `linha_digitavel` |
| `/api/boleto/nosso_numero` | GET | Apenas campos do nosso_numero |
| `/api/boleto` | GET | PDF + headers `X-Nosso-Numero*`. Com `include_data=true`: JSON + base64 |
| `/api/boleto/multi` | POST | PDF multi + headers `X-Boletos-Info`. Com `include_data=true`: JSON + base64 |
| `/api/remessa` | POST | Arquivo CNAB 240/400 |
| `/api/retorno` | POST | JSON com pagamentos parseados |
| `/api/ofx/parse` | POST | JSON com transacoes do extrato OFX |

### Campos de nosso_numero retornados

Todos os endpoints de boleto retornam **3 campos** (nunca `nosso_numero_boleto`):

| Campo | Descricao | Exemplo (BB) |
|-------|-----------|:-------------|
| `nosso_numero` | Valor padronizado | `"000000123"` |
| `nosso_numero_formatado` | Impresso no boleto | `"01234567000000123"` |
| `nosso_numero_dv` | Digito verificador | `"9"` |

## Arquitetura

- [ARCHITECTURE.md](./ARCHITECTURE.md) — Estrutura modular, services, middleware, fluxos
- [ROADMAP.md](./ROADMAP.md) — Roadmap de funcionalidades (pendentes e concluídas)
- [development/brcobranca-fork.md](./development/brcobranca-fork.md) — Detalhes da gem brcobranca

## Guia de Campos por Banco

- [fields/README.md](./fields/README.md) — Overview dos campos
- [fields/nosso-numero.md](./fields/nosso-numero.md) — Nosso numero: entrada, saida, conciliacao
- [fields/all-banks.md](./fields/all-banks.md) — Compatibilidade por banco
- [fields/examples.md](./fields/examples.md) — Exemplos praticos de payloads

## Cliente Python

- [python-client/README.md](../python-client/README.md) — Cliente Python oficial
- [examples/python/](../examples/python/) — Exemplos executáveis

## Recursos Externos

- [brcobranca (fork @maxwbh)](https://github.com/Maxwbh/brcobranca) — Gem Ruby de boletos
- [ofx gem](https://github.com/amaurysilva/ofx) — Gem Ruby de parsing OFX
- [OpenAPI 3.0 Specification](https://spec.openapis.org/oas/v3.0.3)

---

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) - M&S do Brasil LTDA
