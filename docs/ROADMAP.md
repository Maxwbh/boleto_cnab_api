# Roadmap — Boleto CNAB API

> Atualizado em 28/05/2026 | API v1.3.0 | brcobranca v12.8.0

## Estado Atual

| Metrica | Valor |
|---------|-------|
| Versao da API | 1.3.0 |
| brcobranca | 12.8.0 |
| Bancos suportados | 18 |
| Endpoints | 15 |
| Testes Ruby | 172 |
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
| `GET /api/bancos` (capacidades dinamicas) | v1.3.0 |
| Swagger UI (`/api/docs`) + OpenAPI JSON/YAML | v1.3.0 |
| 3 campos nosso_numero (cru, formatado, DV) | v1.3.0 |
| Brcobranca::Bancos v12.7.0+ integrado | v1.3.0 |

---

## Proximo Release: v1.4.0

### Prioridade Alta

#### 1. Validacao de payload por banco

Hoje a API aceita qualquer campo e delega validacao para a gem. Muitos erros so aparecem na hora de gerar o PDF.

**Proposta:** Endpoint `POST /api/boleto/validate` aceitar `bank` e retornar validacoes especificas:
- Campos obrigatorios por banco (ex: `variacao` para Sicoob)
- Tamanho do `nosso_numero` conforme convenio (BB)
- Carteiras validas por banco
- Usar `Brcobranca::Bancos.find(codigo)[:carteiras]` para validar

**Esforco:** Baixo

#### 2. Suporte a CNAB 444 (Itau)

O Itau usa CNAB 444 alem de CNAB 400. A gem ja suporta (`Cnab444`). A API precisa:
- Adicionar `cnab444` ao `CNAB_TYPES` em Config::Constants
- Testar geracao de remessa Itau com CNAB 444

**Esforco:** Baixo

#### 3. Cache de `/api/bancos`

O endpoint `/api/bancos` instancia todas as classes de banco a cada request. Pode cachear em memoria (dados nao mudam em runtime).

**Esforco:** Baixo

### Prioridade Media

#### 4. Cliente Python atualizado

O `python-client` esta em v1.1.0 e nao conhece os novos endpoints:
- `/api/bancos`
- `/api/ofx/parse`
- `include_data=true`
- `template=prawn`
- `pix=true` na remessa
- Campos PIX (`chave_pix`, `tipo_chave_pix`, `txid`)

**Proposta:** Atualizar para v1.3.0 com metodos dedicados.

**Esforco:** Medio

#### 5. Rate limiting basico

A API nao tem rate limiting. No Render free tier isso nao e problema, mas em producao real pode ser necessario.

**Proposta:** Middleware `Rack::Attack` com configuracao via env var.

**Esforco:** Medio

#### 6. Testes de integracao para Remessa PIX

Os testes atuais cobrem remessa normal mas nao remessa com `pix=true`. Adicionar testes para os 7 bancos PIX.

**Esforco:** Medio

### Prioridade Baixa

#### 7. Webhook para notificacao de pagamento

Endpoint para receber webhooks de bancos (Sicoob V3, BB) quando um boleto e pago. Requer:
- `POST /api/webhook/receive`
- Validacao de assinatura do banco
- Armazenamento temporario ou repasse

**Esforco:** Alto

#### 8. Suporte a novos bancos

Bancos que podem ser adicionados na gem brcobranca:
- **Banco Inter (077)** — popular para fintechs
- **Banco Original (212)** — digital
- **Pagbank/PagSeguro (290)** — e-commerce

Requer implementacao na gem primeiro (Fase brcobranca).

**Esforco:** Alto (gem + API)

#### 9. Migrar para Prawn como padrao

Quando o template Prawn estiver estavel em producao, considerar:
- Tornar Prawn o padrao (`BOLETO_TEMPLATE=prawn`)
- Remover GhostScript do Dockerfile principal
- Manter RGhost como fallback para JPG/PNG/TIF

**Esforco:** Baixo (apos validacao em producao)

### Fora do Escopo (requer APIs externas)

| Feature | Prerequisito |
|---------|-------------|
| Sicoob API V3 (registro online) | Certificado ICP-Brasil, OAuth2, mTLS |
| C6 Bank API (registro online) | Homologacao no C6 Developers |
| Banco Inter API | API publica disponivel |

---

## Melhorias Tecnicas

| Melhoria | Esforco | Impacto |
|----------|:-------:|:-------:|
| Atualizar Ruby para 3.4 | Baixo | Medio |
| Adicionar Rubocop (linter) | Baixo | Baixo |
| Coverage report (SimpleCov) | Baixo | Medio |
| Health check mais detalhado (DB, gems, disco) | Baixo | Baixo |
| Compressao gzip nas respostas JSON | Baixo | Medio |
| CORS configuravel via env var | Baixo | Medio |

---

## Comparacao com Upstream (akretion/boleto_cnab_api)

| Feature | Upstream (akretion) | Fork (@maxwbh) |
|---------|:-------------------:|:--------------:|
| brcobranca | 12.0.0 | **12.8.0** |
| Bancos | 16 | **18** (+C6, +Ailos) |
| PIX hibrido | — | **8 bancos** |
| Remessa PIX | — | **7 bancos** |
| Parsing OFX | — | **✅** |
| Template Prawn | — | **✅** |
| Swagger UI | — | **✅** |
| `include_data` | — | **✅** |
| `nosso_numero` (3 campos) | — | **✅** |
| `/api/bancos` | — | **✅** |
| Dockerfile Alpine | ✅ (3.20) | ✅ (ruby:3.3-alpine) |
| Testes | ~30 | **172** |

O fork @maxwbh esta significativamente a frente do upstream em funcionalidades, bancos e testes.

---

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) — M&S do Brasil LTDA
