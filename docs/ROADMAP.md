# Roadmap — Boleto CNAB API

> Baseado no [TODO_INTEGRACAO.md do brcobranca](https://github.com/Maxwbh/brcobranca/blob/master/docs/TODO_INTEGRACAO.md)

## Status por Feature

| Feature | brcobranca | boleto_cnab_api | Versão |
|---------|:----------:|:---------------:|--------|
| Banco C6 (336) — CNAB 400 | ✅ v12.6.1 | ✅ | v1.3.0 |
| PIX Híbrido (8 bancos) | ✅ v12.6.1 | ✅ docs | v1.3.0 |
| Sicoob Carteira 9 (`numero_contrato`) | ✅ v12.6.1 | ✅ funcional | v1.3.0 |
| Parsing OFX | n/a (gem `ofx`) | ✅ | v1.2.0 |
| `GET /api/bancos` | n/a | ✅ | v1.3.0 |
| `GET /api/metadata` | n/a | ✅ | v1.3.0 |
| Template Prawn (sem GhostScript) | ✅ v12.6.1 | 🟡 pendente | — |
| `POST /api/boleto/prawn` | ✅ | 🟡 pendente | — |
| Remessa PIX (`POST /api/remessa/pix`) | ✅ | 🟡 pendente | — |
| Dockerfile sem GhostScript (Prawn) | ✅ | 🟡 pendente | — |
| Sicoob Layout 810 | ✅ v12.6.1 | 🟡 pendente | — |
| Sicoob API V3 (registro online) | n/a | 🔴 futuro | — |
| C6 Bank API (registro online) | n/a | 🔴 futuro | — |

**Legenda:** ✅ implementado | 🟡 pendente (gem pronta, falta endpoint) | 🔴 futuro (requer integração com API externa)

---

## Próximas Prioridades

### 1. Template Prawn (alternativa ao GhostScript)

**O que é:** A brcobranca v12.6.1 introduziu `PrawnBolepix`, um template que gera boletos
usando a gem Prawn (Ruby puro) ao invés de RGhost (que precisa de GhostScript binário).

**Benefícios:**
- Container Docker 50-70MB menor (sem GhostScript + fonts)
- Deploy mais rápido (menos dependências)
- Compatibilidade com ambientes sem `gs` binário
- QR Code PIX renderizado nativamente

**Gems necessárias:**
```ruby
group :prawn do
  gem 'prawn'
  gem 'rqrcode'
  gem 'chunky_png'
end
```

**Endpoint proposto:** `POST /api/boleto/prawn` ou parâmetro `template=prawn` no endpoint existente.

**Esforço estimado:** Médio

---

### 2. Remessa PIX

**O que é:** Geração de arquivos de remessa CNAB com campos PIX incorporados,
usando os novos `PixMixin` para CNAB 400 e CNAB 240.

**Bancos suportados:** Bradesco, Itaú, Banco C6, Sicoob, Caixa, Banco do Brasil

**Diferença da remessa normal:** Inclui registros adicionais com chave PIX, EMV e QR Code
para que o boleto gerado pelo banco seja híbrido.

**Endpoint proposto:** `POST /api/remessa/pix` ou campo `pix=true` no endpoint existente.

**Esforço estimado:** Médio

---

### 3. Sicoob Layout 810

**O que é:** Layout onde o cliente calcula seu próprio dígito verificador do nosso_numero,
ao invés de receber do banco. Útil para cooperativas com sistema legado.

**Como usar:** `versao_layout: '810'` no payload do Sicoob. O boleto_cnab_api já aceita
o campo se passado, mas não há documentação ou validação específica.

**Esforço estimado:** Baixo (apenas documentação + testes)

---

### 4. Dockerfile sem GhostScript

**O que é:** Variante do Dockerfile que usa apenas Prawn (sem GhostScript). Resulta em
imagem ~50-70MB menor e deploy mais rápido.

**Pré-requisito:** Item 1 (Template Prawn)

**Esforço estimado:** Baixo (após Prawn implementado)

---

### 5. APIs Online (Registro em Tempo Real)

**O que é:** Integração com APIs REST dos bancos para registro de boletos em tempo real
(ao invés do fluxo CNAB em lote).

| Banco | API | Status | Pré-requisito |
|-------|-----|--------|---------------|
| Sicoob | Cobrança Bancária V3 | Documentação pública | Certificado ICP-Brasil, OAuth2, mTLS |
| C6 Bank | API de Boleto | Portal fechado | Homologação no C6 Developers |

**Esforço estimado:** Alto (requer infra OAuth2, cache de tokens, mTLS, WebMock para testes)

---

## Concluído (Histórico)

### v1.3.0 (2026-04-10)
- ✅ Banco C6 (336) — CNAB 400 completo
- ✅ brcobranca atualizado para v12.6.1
- ✅ `GET /api/bancos` — lista bancos com capacidades
- ✅ `GET /api/metadata` — versão da API e gem
- ✅ PIX híbrido documentado (8 bancos)
- ✅ Sicoob Carteira 9 funcional (`numero_contrato`)
- ✅ Documentação reorganizada e modernizada

### v1.2.0 (2026-04-09)
- ✅ Endpoint `POST /api/ofx/parse`
- ✅ NossoNumeroExtractor (6 bancos + genérico)
- ✅ Fix remessa: kwargs Ruby 3.0+, `formato:` correto
- ✅ ErrorHandler: ordem correta, backtrace nos logs
- ✅ BoletoService: filtragem de campos por banco
- ✅ Logging unbuffered para Render.com

### v1.1.0 (2026-01-06)
- ✅ Arquitetura modular (12 arquivos)
- ✅ Cliente Python com TypedDict
- ✅ OpenAPI 3.0 + Swagger
- ✅ Docker multi-stage build

### v1.0.0 (2025-11-27)
- ✅ API REST com Grape
- ✅ 17 bancos suportados
- ✅ CNAB 240/400 remessa e retorno
- ✅ Testes RSpec

---

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) — M&S do Brasil LTDA
