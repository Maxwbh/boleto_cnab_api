# Roadmap — Boleto CNAB API

> Atualizado em 29/05/2026 | API v1.3.0 | brcobranca v12.8.0

## Estado Atual

| Metrica | Valor |
|---------|-------|
| Versao da API | 1.3.0 |
| brcobranca | 12.8.0 |
| Bancos suportados | 18 |
| Endpoints | 15 |
| Testes | 176 Ruby + 44 Python = 220 |
| Cobertura | 79.82% (SimpleCov) |
| Templates PDF | RGhost + Prawn |

## Concluido

| Feature | Versao |
|---------|--------|
| 18 bancos (BB, Sicoob, Itau, Bradesco, Caixa, Santander, C6, Sicredi, Banrisul, Banestes, Nordeste, BRB, Unicred, Credisis, Safra, Citibank, HSBC, Ailos) | v1.0-v1.3 |
| Parsing OFX com extracao de nosso_numero | v1.2.0 |
| Banco C6 (336) CNAB 400 | v1.3.0 |
| PIX hibrido no boleto (8 bancos) | v1.3.0 |
| Remessa PIX (`pix=true`) — 7 bancos | v1.3.0 |
| Sicoob Carteira 9 + Layout 810 | v1.3.0 |
| Template Prawn (sem GhostScript) | v1.3.0 |
| Dockerfile.prawn (imagem leve) | v1.3.0 |
| Campos `chave_pix`, `tipo_chave_pix`, `txid` | v1.3.0 |
| `include_data=true` (PDF + dados em 1 chamada) | v1.3.0 |
| `GET /api/bancos` (capacidades dinamicas via Brcobranca::Bancos) | v1.3.0 |
| Swagger UI (`/api/docs`) + OpenAPI JSON/YAML | v1.3.0 |
| 3 campos nosso_numero (cru, formatado, DV) | v1.3.0 |
| Cache de `/api/bancos` | v1.3.0 |
| Compressao gzip (Rack::Deflater) | v1.3.0 |
| SimpleCov (cobertura de testes) | v1.3.0 |
| Cliente Python v1.3.0 (8 novos metodos) | v1.3.0 |
| Testes de integracao Remessa PIX | v1.3.0 |

## Comparacao com Upstream (akretion/boleto_cnab_api)

| Feature | Upstream (akretion) | Fork (@maxwbh) |
|---------|:-------------------:|:--------------:|
| brcobranca | 12.0.0 | **12.8.0** |
| Bancos | 16 | **18** |
| PIX hibrido | — | **8 bancos** |
| Remessa PIX | — | **7 bancos** |
| Parsing OFX | — | **✅** |
| Template Prawn | — | **✅** |
| Swagger UI | — | **✅** |
| `include_data` | — | **✅** |
| `/api/bancos` | — | **✅** |
| Testes | ~30 | **220** |

---

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) — M&S do Brasil LTDA
