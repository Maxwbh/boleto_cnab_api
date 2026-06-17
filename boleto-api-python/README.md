# Boleto-API (Python) — esqueleto da troca de tecnologia

Esqueleto do **Boleto-API reescrito em Python/FastAPI**, mantendo o **`brcobrança` (Ruby)**
como **motor de renderização** atrás de HTTP. É a "troca de tecnologia da API" sem jogar
fora o fosso.

## ⚠️ Dois "API" — não confundir (colisão de nome)

| | Produto | Repo / dir | Papel | Versão |
|---|---|---|---|---|
| **Este** | **Boleto-API** (gateway) | `boleto-api-python/` | providers C6/Sicoob, cofre, webhook, conciliação | FastAPI `version` em `app/main.py` |
| Outro | **BrCobrança** (engine) | `boleto_cnab_api` (Ruby) | renderização: `/api/render/*`, boleto/CNAB/OFX/PIX-QR | `BoletoApi::VERSION` (`lib/boleto_api/version.rb`) |

- O módulo/repo Ruby ainda se chama `BoletoApi`/`boleto_cnab_api`, mas pela
  [separação em 3 produtos](../docs/development/separacao-3-produtos.md) ele é o
  **engine BrCobrança**. O **produto "Boleto-API" é este (Python)**. O nome Ruby é legado.
- **Versionamento independente:** cada produto versiona o seu, na sua linguagem —
  o `version.rb` (Ruby) versiona o **engine**; este projeto versiona o **gateway**
  na própria app FastAPI. Nenhum release acopla os dois.

## Por que Ruby continua no jogo
- No caminho **registrado** (C6/Sicoob) o **banco devolve** linha digitável/PDF/QR → Python
  só orquestra OAuth+mTLS+JSON. **Não precisa de brcobrança.**
- No caminho **offline/CNAB/carnê** (18 bancos) → `brcobranca_proxy` chama o **engine
  BrCobrança (Ruby)** (`boleto_cnab_api`, expondo `/api/render/*`).

À medida que a adoção da API registrada cresce, o uso do motor Ruby encolhe.

## Estrutura
```
app/
  schemas.py              # contrato canônico (pydantic) — estável p/ os consumidores
  registry.py             # roteia provider + resolve credencial no cofre
  core/
    vault.py              # cofre de credenciais por tenant (stateful) — INTERFACE
    subscriptions.py      # registro de assinantes (callback por tenant) — multi-sistema
    forwarder.py          # push assinado (HMAC) do evento ao consumidor
  clients/
    oauth_mtls.py         # OAuth2 client_credentials sobre mTLS (PKCS12), scopes, headers
    engine.py             # cliente do engine BrCobrança (render boleto/carnê)
  providers/
    base.py               # interface BankProvider
    brcobranca_proxy.py   # proxy HTTP -> engine Ruby (offline/CNAB)
    c6.py                 # C6 (336) registrado
    sicoob.py             # Sicoob (756) registrado (+ scopes, header client_id, polling)
  routers/
    cobranca.py           # POST /cobranca, GET/DELETE /cobranca/{id}
    carne.py              # POST /carne (registra N parcelas + carnê 3-vias)
    webhooks.py           # POST /webhooks/{banco} e /webhooks/{banco}/{tenant_id}
```

## Endpoints
| Método | Rota | O que faz |
|---|---|---|
| POST | `/cobranca` | Registra cobrança no provider (por tenant) → resposta normalizada |
| GET | `/cobranca/{id}` | Consulta status (`?tenant_id=&provider=`) |
| DELETE | `/cobranca/{id}` | Baixa/cancela |
| POST | `/carne` | Registra N parcelas + monta carnê 3-vias (PDF) |
| POST | `/webhooks/{banco}` | Recebe webhook do banco → push ao destino **global** |
| POST | `/webhooks/{banco}/{tenant_id}` | Idem, roteando ao consumidor **dono do tenant** |
| GET | `/health` | Health check |

## Produto standalone — acopla a QUALQUER projeto
O Boleto-API **não pertence a nenhum consumidor**. Qualquer projeto integra pelo
mesmo contrato (`/cobranca`, `/carne`) e recebe os eventos de pagamento por **push
assinado** (HMAC). O Gestão-Contrato (Django) é apenas **um** consumidor — nada
no código é específico dele.

**Multi-sistema (implementado):** cada tenant pertence a um consumidor, que
registra um callback próprio (`subscriptions.resolve_callback`). O banco aponta o
webhook de cada conta para `/webhooks/{banco}/{tenant_id}` e o evento é empurrado
**só ao sistema dono** daquele tenant. Sem tenant na rota, cai no destino global.

```
imobA → SUB__imobA__URL (Sistema 1)
imobB → SUB__imobB__URL (Sistema 2)   # eventos roteados por tenant
```

## Configuração (env)
| Var | Para quê |
|---|---|
| `BOLETO_ENGINE_URL` | URL do engine BrCobrança (Ruby) p/ render/CNAB |
| `EVENT_WEBHOOK_URL` | webhook do consumidor **global** (push de eventos) |
| `EVENT_WEBHOOK_SECRET` | segredo HMAC do destino global (`X-Signature`) |
| `SUB__<tenant>__URL` | callback **por tenant** (multi-sistema) — sobrepõe o global |
| `SUB__<tenant>__SECRET` | segredo HMAC daquele tenant/consumidor |

## Rodar (dev)
```bash
cd boleto-api-python
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
export BOLETO_ENGINE_URL=http://localhost:9292   # motor Ruby
export EVENT_WEBHOOK_URL=https://meu-consumidor/webhooks/boleto-api
export EVENT_WEBHOOK_SECRET=troque-isto
uvicorn app.main:app --reload
# http://localhost:8000/docs
```

## Pendências (TODO no código)
- Fechar **paths/payloads/auth-urls** reais de C6 e Sicoob na homologação.
- Implementar **Vault** real (KMS/Vault/DB cifrado) — `EnvVault` é só dev.
- Trocar `subscriptions` por **store real** (DB) — `EnvSubscriptions` é só dev.
- **Worker de conciliação** (polling Sicoob) — não incluído neste esqueleto.
- **Validar a assinatura do webhook do BANCO** antes de confiar (entrada).
- **Retry/fila** no push de eventos (saída) — hoje é best-effort.

> ✅ Já feito: `/api/render/*` no engine Ruby; carnê 3-vias; push assinado por
> tenant (multi-sistema).

> Recomendação: extrair este diretório para um **repo próprio** (`boleto-api`) quando sair
> do esqueleto. Vive aqui temporariamente para versionar junto da decisão.
