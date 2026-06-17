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
- No caminho **offline/CNAB/carnê** (18 bancos) → `brcobranca_proxy` chama o **Boleto-Engine
  Ruby** (`boleto_cnab_api` atual, expondo `/api/render/*`).

À medida que a adoção da API registrada cresce, o uso do motor Ruby encolhe.

## Estrutura
```
app/
  schemas.py              # contrato canônico (pydantic) — estável p/ o Django
  registry.py             # roteia provider + resolve credencial no cofre
  core/vault.py           # cofre de credenciais por tenant (stateful) — INTERFACE
  clients/oauth_mtls.py   # OAuth2 client_credentials sobre mTLS (PKCS12), scopes, headers
  providers/
    base.py               # interface BankProvider
    brcobranca_proxy.py   # proxy HTTP -> motor Ruby (offline/CNAB)
    c6.py                 # C6 (336) registrado
    sicoob.py             # Sicoob (756) registrado (+ scopes, header client_id, polling)
  routers/
    cobranca.py           # POST /cobranca, GET/DELETE /cobranca/{id}
    webhooks.py           # POST /webhooks/{banco}
```

## Produto standalone — acopla a QUALQUER projeto
O Boleto-API **não pertence a nenhum consumidor**. Qualquer projeto integra pelo
mesmo contrato (`/cobranca`, `/carne`) e recebe os eventos de pagamento por **push
assinado** (HMAC). O Gestão-Contrato (Django) é apenas **um** consumidor — nada
no código é específico dele.

Multi-consumidor: hoje há um destino global (`EVENT_WEBHOOK_URL`); `forward_event`
já aceita **override por chamada** (base para callback por tenant quando o
mapeamento webhook→tenant estiver pronto).

## Configuração (env)
| Var | Para quê |
|---|---|
| `BOLETO_ENGINE_URL` | URL do engine BrCobrança (Ruby) p/ render/CNAB |
| `EVENT_WEBHOOK_URL` | webhook do consumidor downstream (push de eventos) |
| `EVENT_WEBHOOK_SECRET` | segredo HMAC para assinar o evento (`X-Signature`) |

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
- **Worker de conciliação** (polling Sicoob) — não incluído neste esqueleto.
- **Validação de assinatura** dos webhooks.
- Expor `/api/render/*` no **Boleto-Engine Ruby** (hoje são `/api/boleto`, `/api/remessa`).

> Recomendação: extrair este diretório para um **repo próprio** (`boleto-api`) quando sair
> do esqueleto. Vive aqui temporariamente para versionar junto da decisão.
