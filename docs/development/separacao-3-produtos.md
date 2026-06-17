# Separação em 3 produtos — Gestão-Contrato / Boleto-API / BrCobrança

> Documento de decisão/arquitetura (ADR de fronteiras de produto).
> Status: **proposta** · Data: 2026-06-17 · Autor: Maxwell da Silva Oliveira
> Reconcilia a [remodelagem em serviços](./remodelagem-gateway-servicos.md) no enquadramento de **3 produtos**.

---

## 0. Reconciliação com a remodelagem

A [remodelagem](./remodelagem-gateway-servicos.md) propôs um **Bank Gateway separado em Python**. Ao definir os produtos como **3** (com **Boleto-API** no meio), o **gateway colapsa para dentro do Boleto-API** — que continua **Ruby** e absorve os providers C6/Sicoob (exatamente o esqueleto já commitado em `lib/boleto_api/providers/`).

**Efeito:** menos um runtime, sem reescrever providers. O estado que o Gateway teria (cofre, scheduler de conciliação) passa a viver **dentro do Boleto-API**. A ressalva do Sicoob (§4 da remodelagem) continua válida: **Boleto-API é stateful**.

---

## 1. Os 3 produtos

| Produto | É | Repo | Linguagem | Estado |
|---|---|---|---|---|
| **BrCobrança** | Biblioteca de primitivas de boleto/CNAB (18 bancos) | [`maxwbh/brcobranca`](https://github.com/maxwbh/brcobranca) (**já separado**) | Ruby (gem) | Stateless, puro |
| **Boleto-API** | API HTTP + **gateway bancário** (providers C6/Sicoob, PIX, webhook, conciliação, cofre) | [`maxwbh/boleto_cnab_api`](https://github.com/maxwbh/boleto_cnab_api) (**este repo**) | Ruby (Grape) | **Stateful** (cofre + scheduler) |
| **Gestão-Contrato** | Produto de domínio: imobiliárias, contratos, cronograma, reajuste, carnê | **greenfield** (criar) | a definir (Python/Rails) | Stateful (domínio) |

---

## 2. Dependência: estritamente unidirecional

```
Gestão-Contrato ──depende──► Boleto-API ──depende──► BrCobrança
   (domínio)        HTTP        (API/gateway)   gem        (lib)
```

**Regras de fronteira (invioláveis):**
- A seta **só aponta para baixo**. BrCobrança **não conhece** Boleto-API; Boleto-API **não conhece** Gestão-Contrato.
- **BrCobrança** não fala HTTP, não tem segredo, não conhece tenant/banco-API. Só calcula boleto/CNAB.
- **Boleto-API** não tem regra de negócio de contrato/aluguel/reajuste. Só cobrança bancária.
- **Gestão-Contrato** não fala com banco nem com BrCobrança direto — **sempre** via Boleto-API.

> Se uma regra de aluguel vazar para o Boleto-API, ou um detalhe de banco vazar para o Gestão-Contrato, a fronteira foi violada.

---

## 3. O que cada produto possui (e o que NÃO possui)

### BrCobrança (lib)
- **Possui:** algoritmos de linha digitável, código de barras, DV, CNAB400/240, particularidades por banco; geração de PDF (Prawn/RGhost).
- **Não possui:** HTTP, credenciais, chamadas a API de banco, multi-tenant, persistência.
- **Superfície pública:** classes Ruby (`Brcobranca::Boleto::*`, remessa/retorno). Consumida **só** pelo Boleto-API.

### Boleto-API (API + gateway)
- **Possui:** endpoints HTTP; **providers** (`BrcobrancaProvider`, `C6Provider`, `SicoobProvider`); OAuth2+mTLS por tenant; **cofre de credenciais/cert**; webhooks; **conciliação** (webhook + polling Sicoob); normalização de status; montagem de carnê.
- **Não possui:** o que é contrato/parcela/reajuste/inquilino (isso é domínio do Gestão-Contrato).
- **Superfície pública (contrato HTTP):**
  ```
  POST   /api/cobranca            registra cobrança (provider por tenant)
  GET    /api/cobranca/:id        consulta status
  POST   /api/cobranca/:id/baixar baixa/cancela
  POST   /api/carne               carnê (N cobranças + PDF)
  POST   /api/pix/cob | /cobv     PIX cobrança (BACEN)
  POST   /api/webhooks/:banco     callback do banco → evento normalizado
  GET    /api/eventos             entrega de eventos de pagamento
  # legado/fallback (geração offline, não-registrado):
  GET    /api/boleto | /data | /validate | /nosso_numero
  POST   /api/remessa | /retorno  (CNAB — em depreciação)
  ```

### Gestão-Contrato (domínio)
- **Possui:** imobiliárias (tenants), contratos, parcelas, cronograma, **reajuste**, janela do carnê (12m), decide **quando/o que** emitir; consome eventos de pagamento para baixar parcelas.
- **Não possui:** mTLS, scopes, nosso_número, txid, CNAB — nada de banco.
- **Superfície pública:** API própria do produto (web/app), **fora** do escopo destes 3 contratos.

---

## 4. Estado atual → alvo (o que falta para "separar")

| Produto | Hoje | Ação para separar |
|---|---|---|
| **BrCobrança** | ✅ Já é repo/gem separado, consumido via Gemfile | Nada estrutural. Manter como dependência versionada |
| **Boleto-API** | Repo este; tem `/render`/CNAB + **esqueleto de providers** commitado | Evoluir providers (C6/Sicoob), adicionar **cofre** + **conciliação**; deprecar CNAB do caminho principal |
| **Gestão-Contrato** | ❌ Não existe | Criar repo greenfield; isolar consumo do Boleto-API numa camada de serviços (ponto de troca limpo) |

> **A separação física já está 2/3 feita:** BrCobrança é gem externa; Boleto-API é repo próprio. Falta **criar o Gestão-Contrato** e **fechar o contrato HTTP** do Boleto-API como superfície estável.

---

## 5. Versionamento e release independentes

- **BrCobrança**: versão de gem; Boleto-API fixa por `git ref`/tag (evita quebra surpresa do fork).
- **Boleto-API**: versiona o **contrato HTTP** (header de versão já existe: `version 'v1'`). Mudança incompatível = `v2`, mantendo `v1`.
- **Gestão-Contrato**: depende de uma **versão do contrato** do Boleto-API, não de um commit. Atualiza quando quiser.
- **Cada produto tem seu CI/deploy.** Nenhum release acopla os três.

---

## 6. Decisões em aberto

- **Stack do Gestão-Contrato** (greenfield): Python/FastAPI ou Rails.
- **Cofre** no Boleto-API: KMS/Vault vs criptografia envelope no DB.
- **Boleto-API stateful**: introduzir DB + worker (scheduler de polling Sicoob) — define infra do repo.
- **Entrega de eventos** Gestão-Contrato ← Boleto-API: pull (`GET /eventos`) vs push (webhook do Boleto-API para o Gestão-Contrato).
- **Chave de conciliação**: `nosso_numero` → `id`/`txid` do banco (impacta model de parcela no Gestão-Contrato).

---

## Fontes / relacionados

- [Remodelagem em serviços](./remodelagem-gateway-servicos.md)
- [Spike — gateway bancário C6 + Sicoob](./gateway-bancario-spike.md)
- [Comparativo de PSP](./comparativo-psp-imobiliaria.md)
- BrCobrança (fork): https://github.com/maxwbh/brcobranca · [nota do fork](./brcobranca-fork.md)
