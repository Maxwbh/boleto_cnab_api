# Separação em 3 produtos — Gestão-Contrato / Boleto-API / BrCobrança

> Documento de decisão/arquitetura (ADR de fronteiras de produto).
> Status: **proposta** · Data: 2026-06-17 · Autor: Maxwell da Silva Oliveira
> Reconcilia a [remodelagem em serviços](./remodelagem-gateway-servicos.md) no enquadramento de **3 produtos**.

---

## 0. Reconciliação (decisão final)

Evolução das decisões: a [remodelagem](./remodelagem-gateway-servicos.md) propôs um Bank Gateway em Python; depois cogitou-se colapsá-lo no Boleto-API Ruby. **Decisão final:** **todo o Ruby fica no BrCobrança** e o **Boleto-API é só Python**.

- **BrCobrança (Ruby)** = lib **+ engine HTTP de renderização** (boleto/CNAB/OFX/PDF/PIX-QR). Tudo que depende do brcobrança vive aqui.
- **Boleto-API (Python)** = **gateway bancário** (providers C6/Sicoob, OAuth+mTLS, cofre, webhook, conciliação). **Stateful** (ressalva do polling Sicoob, §4 da remodelagem).

**Efeito:** zero lógica duplicada entre idiomas. Os providers/endpoints Ruby de gateway (commit `432dddd`) foram **removidos** — não pertencem ao BrCobrança. O Ruby volta a ser **só renderização**.

---

## 1. Os 3 produtos

| Produto | É | Repo | Linguagem | Estado |
|---|---|---|---|---|
| **BrCobrança** | Lib de boleto/CNAB (18 bancos) **+ engine HTTP de renderização** | [`maxwbh/brcobranca`](https://github.com/maxwbh/brcobranca) (lib) + [`maxwbh/boleto_cnab_api`](https://github.com/maxwbh/boleto_cnab_api) (engine HTTP) | **Ruby** | Stateless, puro |
| **Boleto-API** | **Gateway bancário** (providers C6/Sicoob, PIX, webhook, conciliação, cofre) | a extrair p/ repo próprio (esqueleto em `boleto-api-python/`) | **Python/FastAPI** | **Stateful** (cofre + scheduler) |
| **Gestão-Contrato** | Produto de domínio: imobiliárias, contratos, cronograma, reajuste, carnê | [`maxwbh/Gestao-Contrato`](https://github.com/Maxwbh/Gestao-Contrato) (**já existe**) | **Python/Django 4.2** (PostgreSQL, Gunicorn) | Stateful (domínio) |

---

## 2. Dependência: estritamente unidirecional

```
Gestão-Contrato ──depende──► Boleto-API ──depende──► BrCobrança
   (domínio,         HTTP      (gateway,       HTTP     (Ruby: lib + engine)
    Django)                     Python)
```

**Regras de fronteira (invioláveis):**
- A seta **só aponta para baixo**. BrCobrança **não conhece** Boleto-API; Boleto-API **não conhece** Gestão-Contrato.
- **BrCobrança** não fala com API de banco, não tem segredo, não conhece tenant. Só **renderiza** boleto/CNAB/PIX-QR (Ruby).
- **Boleto-API** não tem regra de negócio de contrato/aluguel/reajuste. Só cobrança bancária (Python).
- **Gestão-Contrato** não fala com banco nem com BrCobrança direto — **sempre** via Boleto-API.

> Se uma regra de aluguel vazar para o Boleto-API, ou um detalhe de banco vazar para o Gestão-Contrato, a fronteira foi violada.

---

## 3. O que cada produto possui (e o que NÃO possui)

### BrCobrança (Ruby) — lib + engine HTTP
- **Possui:** algoritmos de linha digitável, código de barras, DV, CNAB400/240, particularidades por banco; geração de **PDF/carnê** (Prawn/RGhost) e **PIX-QR** (PrawnBolepix); parsing **OFX**. Exposto por um **engine HTTP** (este repo).
- **Não possui:** credenciais, chamadas a **API de banco**, multi-tenant, persistência, OAuth/mTLS.
- **Superfície pública (engine HTTP) — só renderização:**
  ```
  POST /api/render/boleto | /carne | /remessa   (gerar PDF/linha digitável/CNAB)
  GET  /api/boleto | /data | /validate | /nosso_numero   (cálculo offline)
  POST /api/retorno | /api/ofx/parse            (parsing CNAB retorno / OFX)
  ```

### Boleto-API (Python) — gateway bancário
- **Possui:** **providers** (`BrcobrancaProxy`, `C6`, `Sicoob`); OAuth2+mTLS por tenant; **cofre de credenciais/cert**; webhooks; **conciliação** (webhook + polling Sicoob); normalização de status. Para boleto offline/CNAB/carnê, faz **proxy HTTP ao BrCobrança**.
- **Não possui:** algoritmo de boleto/CNAB (delega ao BrCobrança); regra de contrato/aluguel/reajuste (é do Gestão-Contrato).
- **Superfície pública (contrato HTTP):**
  ```
  POST   /cobranca             registra cobrança (provider por tenant)
  GET    /cobranca/:id         consulta status
  DELETE /cobranca/:id         baixa/cancela
  POST   /webhooks/:banco      callback do banco → evento normalizado
  # (planejado) /carne, /pix/cob|cobv, /eventos
  ```

### Gestão-Contrato (domínio) — Django 4.2
- **Possui:** imobiliárias (tenants), contratos, parcelas, cronograma, **reajuste**, janela do carnê (12m), decide **quando/o que** emitir; consome eventos de pagamento para baixar parcelas. Apps `contratos` / `financeiro` / `notificacoes` / `portal_comprador`.
- **Já integra o Boleto-API** via HTTP (self-hosted Docker), isolado em `financeiro/services/` — **ponto de troca limpo** para evoluir CNAB → API registrada.
- **Não possui (nem deve):** mTLS, scopes, nosso_número, txid, CNAB — nada de banco.
- **Superfície pública:** API própria do produto (web/app), **fora** do escopo destes 3 contratos.

---

## 4. Estado atual → alvo (o que falta para "separar")

| Produto | Hoje | Ação para separar |
|---|---|---|
| **BrCobrança** | ✅ Lib (gem) + engine HTTP (este repo); gateway Ruby **removido** → só renderização | Expor `/api/render/*` enxuto p/ o proxy Python; manter lib versionada |
| **Boleto-API** | Esqueleto **Python/FastAPI** em `boleto-api-python/` (providers, cofre, OAuth+mTLS, testes) | Extrair p/ repo próprio; fechar paths C6/Sicoob na homologação; worker de conciliação |
| **Gestão-Contrato** | ✅ Existe (Django 4.2); já consome o engine via HTTP, isolado em `financeiro/services/` | Apontar para o Boleto-API Python; migrar CNAB → cobrança registrada/webhook; chave `nosso_numero` → `txid` |

> **A separação física já está feita:** os 3 já são produtos/repos distintos. Após esta decisão, o Ruby (BrCobrança) é **só renderização** e o **gateway é Python** (Boleto-API). O trabalho restante **não é separar** — é **fechar o contrato HTTP** entre os três e **migrar o consumo** no Django, mantendo CNAB como fallback.

---

## 5. Versionamento e release independentes

- **BrCobrança**: versão de gem; Boleto-API fixa por `git ref`/tag (evita quebra surpresa do fork).
- **Boleto-API**: versiona o **contrato HTTP** (header de versão já existe: `version 'v1'`). Mudança incompatível = `v2`, mantendo `v1`.
- **Gestão-Contrato**: depende de uma **versão do contrato** do Boleto-API, não de um commit. Atualiza quando quiser.
- **Cada produto tem seu CI/deploy.** Nenhum release acopla os três.

---

## 6. Decisões em aberto

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
