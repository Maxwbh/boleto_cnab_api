# Remodelagem — arquitetura de serviços (Engine Ruby + Gateway + gestao-contrato)

> Documento de decisão/arquitetura (ADR de remodelamento).
> Status: **proposta** · Data: 2026-06-17 · Autor: Maxwell da Silva Oliveira
> Complementa e **revisa a topologia** do [spike de gateway bancário](./gateway-bancario-spike.md).
>
> **Correção (2026-06-17):** o `gestao-contrato` **não é greenfield** — já existe em
> **Python/Django 4.2** ([`maxwbh/Gestao-Contrato`](https://github.com/Maxwbh/Gestao-Contrato))
> e já consome o Boleto-API. **Decisão final de topologia** (ver
> [separação em 3 produtos](./separacao-3-produtos.md), documento autoritativo):
> **todo o Ruby fica no BrCobrança** (engine de renderização) e o **Boleto-API é só
> Python** (gateway). A recomendação de stack abaixo (§3) fica assim resolvida.

---

## 0. O que muda em relação ao spike

O [spike](./gateway-bancario-spike.md) decidiu **evoluir o `boleto_cnab_api` in-place** para um gateway Ruby único (Adapter). Esta remodelagem **mantém a estratégia** (adapter multi-banco, contrato estável, CNAB → API) mas **revisa a topologia** a partir de duas decisões novas:

1. **`gestao-contrato` é greenfield** (vai ser criado) — não há stack legado a preservar.
2. **Serviços separados via REST** (não um monólito).

Consequência: em vez de **um** serviço Ruby fazendo tudo, dividimos em **3 serviços** com responsabilidades e estado distintos, e a linguagem **segue o ativo** — Ruby fica só onde o `brcobranca` justifica.

---

## 1. Princípio que guia o remodelamento

> **A linguagem segue o ativo, não a moda.**

O `brcobranca` (boleto/CNAB de 18 bancos) é o **fosso** e **não tem equivalente maduro em Python**. Reescrevê-lo = reimplementar a lógica de 18 bancos com risco de regressão e zero ganho. Já os conectores de banco (C6/Sicoob: OAuth + mTLS + JSON) são **commodity** — qualquer linguagem.

Logo: **isola-se o `brcobranca` atrás de REST** e o resto é construído no stack mais produtivo pro time.

---

## 2. Os 3 serviços

```
┌──────────────────┐    REST     ┌───────────────────────────┐
│  gestao-contrato │ ──────────► │       Bank Gateway        │
│  (domínio)       │             │ (providers + conciliação) │
└──────────────────┘             └─────────┬─────────────────┘
  imobiliárias, contratos,          │       │
  cronograma, reajuste,             │       ├─ HTTPS+mTLS ─► C6 (336) / Sicoob (756)
  janela do carnê,                  │       │
  decide QUANDO emitir              │ REST  ▼
                            ┌───────┴──────────────┐
                            │   Boleto Engine       │
                            │  (Ruby + brcobranca)  │  ← STATELESS, sem segredo
                            └───────────────────────┘
                              PDF / linha digitável / CNAB / carnê
```

| Serviço | Responsabilidade | Estado | Stack |
|---|---|---|---|
| **Boleto Engine** | Renderizar boleto/carnê (PDF/QR) e CNAB (18 bancos) | **Stateless, sem segredo** | **Ruby/brcobranca** (é o `boleto_cnab_api` atual) |
| **Bank Gateway** | Providers C6/Sicoob (OAuth+mTLS), webhook, conciliação, normalização de status, cofre de credenciais | **Stateful** (ver §4) | **Python/FastAPI** (recomendado) |
| **gestao-contrato** | Imobiliárias, contratos, cronograma, reajuste, carnê, *quando* emitir | Stateful (domínio) | **Python** (mesmo ecossistema do Gateway) |

---

## 3. Stack — recomendação (greenfield)

- **Boleto Engine: Ruby** (fixo). É o `boleto_cnab_api`; só passa a expor endpoints `render/*` (já tem quase tudo).
- **Bank Gateway + gestao-contrato: Python (FastAPI)** — **um ecossistema só** pro time. Motivos:
  - **Contratos tipados** (pydantic) entre serviços e na fronteira REST.
  - **`httpx` com mTLS** nativo — encaixe direto em C6/Sicoob (certificado por tenant).
  - **I/O assíncrono** para muitas chamadas de banco.
  - **Worker maduro** (Celery/arq) para o **polling de conciliação do Sicoob** (§4).
- *Alternativa válida:* **Rails** no Gateway+domínio, se quiser ActiveRecord/admin forte no `gestao-contrato`. Para "conectores + I/O + scheduler", FastAPI é mais enxuto.

**Poliglota mínimo:** Ruby só na ilha do `brcobranca` (atrás de REST), Python no resto. Sem reescrever o motor.

---

## 4. Consequência do Sicoob: o Gateway é *stateful* ⚠️

O spike e o esqueleto inicial assumiam um gateway que recebe credencial **por request** (stateless). **O Sicoob quebra isso:** a conciliação de boleto dele é por **polling agendado** (consulta diária), não webhook — o Gateway precisa chamar o banco **sem um request do usuário na frente**.

Portanto o **Bank Gateway é stateful** e assume 3 estados:

1. **Cofre de credenciais** por tenant (client_id, secret, **certificado .pfx**, chave PIX) — criptografado em repouso (KMS/Vault ou envelope no DB). Nunca em log/git.
2. **Cache de token** OAuth por tenant (~300s).
3. **Scheduler de conciliação** (worker) — polling Sicoob + reprocessamento de webhooks falhos.

> O **Boleto Engine continua 100% sem segredo.** Todo o risco de credencial fica concentrado no Gateway — que é exatamente o papel dele.

Isto torna explícito o "épico de segurança" do spike (§6): ele **mora no Gateway**.

---

## 5. Mapear um banco = preencher 8 dimensões

Para plugar **qualquer** banco no gate genérico, mapeia-se contra o contrato único:

| # | Dimensão | C6 (336) | Sicoob (756) |
|---|---|---|---|
| 1 | **Auth** | mTLS (PFX) + OAuth client_credentials | mTLS (PFX) + OAuth + **scopes** + header **`client_id`** em toda chamada |
| 2 | **Certificado / onboarding** | gerado no **Web Banking** | **ICP-Brasil A1 do cooperado** (chave pública PEM no portal) |
| 3 | **Identificadores da conta** | agência/conta/convênio | **cooperativa + numeroContaCorrente + numeroCliente + codigoModalidade** |
| 4 | **Endpoints** | boleto registrado (incluir/consultar/alterar/baixar) | Cobrança Bancária (idem) + PIX BACEN |
| 5 | **Campos do payload** | `ourNumber`, `amount`, `dueDate`… | **`nossoNumero`, `seuNumero`**, `numeroCliente`, `codigoModalidade`… |
| 6 | **Resposta** | id/linha digitável/QR/PDF | nossoNumero/linha digitável/QR |
| 7 | **Vocabulário de status** | REGISTERED/PAID/CANCELLED → normalizado | REGISTRADO/LIQUIDADO/BAIXADO → normalizado |
| 8 | **Conciliação** | **webhook** de liquidação | **PIX por webhook**; **boleto por polling** (liquidação diária) |

**Diferenças que o gate precisa absorver** (vs. o esqueleto C6-only já commitado):
- OAuth com **`scopes`** opcional (Sicoob exige; C6 não).
- **Headers extras por provider** (Sicoob: `client_id` em toda request).
- **Estratégia de conciliação plugável**: `webhook` (C6) vs `polling` (Sicoob boleto).

---

## 6. Modelo canônico (contrato estável do gestao-contrato → Gateway)

O `gestao-contrato` sempre manda o **mesmo shape**; cada Provider traduz para o seu banco.

```jsonc
{
  "tenant_id": "imob_123",
  "provider": "sicoob",            // ou "c6" | "brcobranca" (offline/fallback)
  "account_config": { ... },       // blob por provider (não unificado):
                                   //   c6:     { agencia, conta, convenio }
                                   //   sicoob: { cooperativa, conta, numeroCliente, codigoModalidade }
  "cobranca": {
    "valor": 1000.00,
    "vencimento": "2026-07-10",
    "nosso_numero": "...",          // ou seu_numero
    "pagador": { "nome": "...", "documento": "...", "endereco": { ... } },
    "multa": { ... }, "juros": { ... }, "desconto": { ... }
  }
}
```

- **`credentials`** **não** viajam no request do `gestao-contrato`: ficam no **cofre do Gateway** (§4), resolvidas por `tenant_id`. (Diferença chave vs. o esqueleto stateless inicial.)
- **`account_config`** é um blob por provider — o gate não tenta unificar cooperativa/convênio; cada Provider lê o seu.

---

## 7. Contratos REST entre serviços

```jsonc
// gestao-contrato → Bank Gateway
POST   /cobrancas               { tenant_id, provider, account_config, cobranca } → { id, status, linha_digitavel, pix_emv, pdf_url }
GET    /cobrancas/{id}          → { id, status, ... }
DELETE /cobrancas/{id}          → { id, status: "baixado" }
POST   /carnes                  { tenant_id, provider, parcelas[] }              → { carne_pdf_url, cobrancas[] }
POST   /webhooks/{banco}        ← banco (Gateway recebe, normaliza, repassa)
GET    /eventos?since=...       → eventos de pagamento normalizados (ou push)

// Bank Gateway → Boleto Engine (Ruby/brcobranca) — caminho offline/CNAB e PDF
POST   /render/boleto           { bank, data }       → { pdf_base64, linha_digitavel, codigo_barras }
POST   /render/carne            { bank, boletos[] }  → { pdf_base64 }
POST   /render/remessa          { bank, boletos[] }  → { cnab }
```

- **Normalização**: a resposta do `/cobrancas` é igual para qualquer provider (o `gestao-contrato` não sabe qual banco está atrás).
- **Engine reaproveitado**: `/render/*` é essencialmente o que o `boleto_cnab_api` já faz (`/api/boleto`, `/api/boleto/multi`, `/api/remessa`).

---

## 8. Reaproveitamento do que já existe

| Ativo atual | Papel no remodelamento |
|---|---|
| `boleto_cnab_api` (Grape/brcobranca) | Vira o **Boleto Engine** — só expõe `/render/*` |
| Esqueleto de providers commitado (`providers/`) | Vira **spec de referência** do Gateway Python (contrato, normalização de status, payloads) — a lógica migra, muda só a linguagem |
| `PrawnCarne` | Montagem do **carnê PDF** no Engine |
| Motor de conciliação OFX/retorno | **Fallback** para extratos avulsos; conciliação principal vira webhook+polling no Gateway |

---

## 9. Fases (revisadas para 3 serviços)

| Fase | Entrega | Onde |
|---|---|---|
| 0 | Onboarding técnico C6 + Sicoob (apps, cert, sandbox) | — |
| 1 | **Boleto Engine**: expor `/render/*` no `boleto_cnab_api` (já existe quase tudo) | Ruby |
| 2 | **Bank Gateway** base: `OAuthMtlsClient` (scopes + headers), `BankProvider`, cofre de credenciais | Python |
| 3 | `SicoobProvider` (cobrança + PIX `cob` + webhook + **polling**) em sandbox | Python |
| 4 | `C6Provider` (boleto/PIX + webhook) | Python |
| 5 | **gestao-contrato** greenfield: domínio + cliente do Gateway | Python |
| 6 | Conciliação (webhook + scheduler) + carnê sobre cobranças registradas | Python+Ruby |

**Não fazer big-bang:** Engine e Gateway sobem antes; `gestao-contrato` consome contrato estável.

---

## 10. Decisões em aberto

- **Cofre**: KMS/Vault vs criptografia envelope no DB do Gateway.
- **Conciliação Sicoob**: periodicidade do polling + idempotência de eventos.
- **Chave de conciliação**: `nosso_numero`/`seu_numero` → `id`/`txid` do banco (impacta model `Parcela` no gestao-contrato).
- **Carnê**: montado no Engine (Prawn) a partir das N cobranças registradas.
- **Sandbox/scopes** reais de C6 e Sicoob (confirmar na homologação).

---

## Fontes

- [Spike — gateway bancário C6 + Sicoob](./gateway-bancario-spike.md)
- [Comparativo de PSP para imobiliária](./comparativo-psp-imobiliaria.md)
- Sicoob Developers: https://developers.sicoob.com.br · [Postman Cobrança](https://documenter.getpostman.com/view/20565799/Uzs6yNhe)
- C6 Developers: https://developers.c6bank.com.br · [APIs de integração](https://www.c6bank.com.br/apis-integracao/)
- API PIX BACEN: https://github.com/bacen/pix-api
