# Spike — Integração direta C6 + Sicoob e evolução para *gateway* bancário

> Documento de decisão/arquitetura (ADR + spike técnico).
> Status: **proposta** · Data: 2026-06-17 · Autor: Maxwell da Silva Oliveira
> Contexto: avaliação de modernização da `boleto_cnab_api` consumida pelo produto **Gestao-Contrato**.

---

## 1. Decisão e contexto

O produto **Gestao-Contrato** (gestão de contratos de compra/venda e **aluguel/prestação** de imóveis, multi-imobiliária) usa hoje a `boleto_cnab_api` para **gerar PDF de boleto/carnê** e **montar arquivos CNAB** (remessa/retorno), enviados ao banco via convênio próprio.

Duas dores motivam a modernização: **faltam features bancárias** (boleto registrado, confirmação de pagamento em tempo real, conciliação automática, PIX com liquidação) e **percepção de modernidade** (CNAB é datado).

Avaliamos dois caminhos: **PSP/agregador** vs **integração direta** com os bancos efetivamente usados (**C6 – 336** e **Sicoob – 756**).

**Decisão:** seguir com **integração direta C6 + Sicoob** e **evoluir a `boleto_cnab_api` para um *gateway* de API bancária** (em vez de aposentá-la). Justificativas:

- **Fluxo de dinheiro de terceiros:** em aluguel, o valor é do proprietário/imobiliária. Direto, cai **na conta do cliente**; via PSP, passaria por **subconta/escrow** (regulação de subadquirência) — risco e fricção desnecessários.
- **Custo:** direto paga só a tarifa do banco; PSP adiciona taxa por transação.
- **Escopo fechado:** são **2 bancos** — multiplicação de integração controlada.
- **Reaproveitamento:** a API já abstrai bancos e o Gestao-Contrato já isola o consumo numa **camada de serviços** (ponto de troca limpo). Evoluir > reescrever.

> **PSP como fallback** (futuro, plugável): para clientes que usem outros bancos, sem custódia — cada um na sua conta. Fora do escopo deste spike.

---

## 2. Comparação técnica — Sicoob × C6

| Aspecto | **Sicoob (756)** | **C6 Bank (336)** |
|---|---|---|
| Portal | [developers.sicoob.com.br](https://developers.sicoob.com.br) | [C6 Developers / apis-integracao](https://www.c6bank.com.br/apis-integracao/) |
| Cobrança (boleto registrado) | ✅ API Cobrança Bancária (registrar, consultar, 2ª via, baixar, alterar) | ✅ API de Boleto (emitir registrado, alterar, cancelar) |
| Boleto híbrido com PIX | ✅ | ✅ (Pix Cobrança PJ) |
| PIX recebimento | ✅ API PIX padrão BACEN (`cob`, `cobv`, `lotecobv`, `pix`, `webhook`) | ✅ API PIX (Pix Cobrança PJ) |
| Autenticação | **OAuth2 client_credentials** + **mTLS X.509 (.pfx)**; token ~300s; `client_id` do app no portal; validação Sicoobnet | **OAuth2 + certificado** (confirmar detalhes no C6 Developers) |
| Scopes (PIX) | `cob`, `cobv`, `lotecobv`, `pix`, `webhook`, `payloadlocation` | a confirmar |
| Certificado | **ICP-Brasil (e-CNPJ)** convertido p/ `.pfx` | a confirmar (provável cert + chave) |
| Sandbox | Existe, porém pouco documentado | Ambiente de testes citado; a validar |
| Webhook de pagamento | ✅ (PIX: callback `<url>/pix`, array JSON) | ✅ (a detalhar) |
| Maturidade da doc | ⚠️ **Reconhecidamente incompleta** (confirmado por SDKs community: vários endpoints descobertos por tentativa/erro) | ⚠️ Doc pública limitada; portal fechado a clientes PJ |
| Referências/SDK | [SharpSistemas/SicoobAPI](https://github.com/SharpSistemas/SicoobAPI) (C#), [Postman](https://documenter.getpostman.com/view/20565799/Uzs6yNhe) | docs de ERPs (SoftenDocs, ISPCloud) |
| **Esforço/risco** | **Médio-alto** — API completa, mas doc fraca e mTLS/cert por cooperado | **Médio** — escopo menor exposto; **risco de disponibilidade/onboarding** PJ |

**Leitura:** os dois cobrem **boleto registrado + PIX + webhook**. O Sicoob é o mais **completo e documentado por terceiros** (apesar da doc oficial fraca) e segue **API PIX padrão BACEN** — bom ponto de partida. O C6 cobre o necessário, mas tem **menos detalhe público**; tratar como **2º conector**, validando onboarding/sandbox cedo.

> ⚠️ **Itens a confirmar com gerente/onboarding** (não dá pra fechar só por doc pública): C6 — scopes, formato de cert, URLs de sandbox; Sicoob — disponibilidade de sandbox de Cobrança (não só PIX) e limites de rate.

---

## 3. Paridade — o que o Gestao-Contrato usa hoje → equivalente direto

O consumo da `boleto_cnab_api` está isolado em `financeiro/services/` do Gestao-Contrato:

| Serviço (Gestao-Contrato) | Hoje (CNAB/PDF) | Alvo (API direta via gateway) |
|---|---|---|
| `boleto_service.py` (`GET /api/boleto*`) | Gera PDF + `nosso_numero` calculado | **Registrar cobrança** no banco → banco devolve `nosso_numero`/linha digitável/PDF |
| `carne_service.py` (`POST /api/boleto/multi`) | Carnê PDF montado | N cobranças registradas + **PDF de carnê** montado no gateway (template Prawn já existe) |
| `cnab_service.py` (`POST /api/remessa`/`/retorno`) | Arquivo CNAB enviado/processado | **Desaparece** — registro é via API; baixa/alteração via API |
| `ofx_service.py` (`POST /api/ofx/parse`) | Parse OFX (tem fallback Python) | Mantido p/ extratos avulsos; conciliação principal via **webhook** |
| `bancos.py` (`GET /api/boleto/data`) | Testa se banco é suportado | Idem (catálogo de bancos/conectores do gateway) |

**Ganhos diretos:** o **CNAB sai do caminho principal**; **registro + confirmação de pagamento** passam a ser via API/webhook; **conciliação** deixa de depender de parse de retorno/OFX.

**Pontos de atenção (mesmos do estudo anterior):**
1. **Carnê** — bancos registram cobranças individuais; o **PDF 3-vias/A4** continua montado pelo gateway (já temos `PrawnCarne`).
2. **`nosso_numero_formatado`/`_dv`** — chave de conciliação atual; com registro via API, a chave passa a ser o **id da cobrança/`txid`** do banco. Impacta o model `Parcela` (migration) e a lógica de conciliação.

---

## 4. Arquitetura-alvo do *gateway*

A `boleto_cnab_api` deixa de ser "geradora de documento" e vira **orquestradora multi-banco multi-tenant**, mantendo o **contrato que o Gestao-Contrato já consome** e adicionando registro/PIX/webhook.

```
Gestao-Contrato (financeiro/services/*)
        │  contrato estável (HTTP)
        ▼
┌─────────────────────────────────────────────┐
│            boleto_cnab_api (gateway)         │
│                                              │
│  BankProvider (interface)                    │
│    ├── SicoobProvider  (Cobrança + PIX)      │
│    ├── C6Provider      (Boleto + PIX)        │
│    └── CnabProvider    (legado/fallback)     │
│                                              │
│  Núcleo reaproveitado:                       │
│    • PDF/QR (Prawn, PrawnCarne, EMV PIX)     │
│    • catálogo de bancos / OpenAPI            │
│    • conciliação (motor OFX/retorno → webhook)│
│                                              │
│  Novo:                                       │
│    • credenciais/cert por tenant (cofre)     │
│    • OAuth2+mTLS por banco                    │
│    • webhooks de pagamento → eventos         │
└─────────────────────────────────────────────┘
        │                 ▲
        ▼  mTLS+OAuth2     │ webhook pagamento
   API Sicoob / API C6 ────┘
```

### Padrão Adapter
```ruby
# Interface comum a todos os bancos
module BankProvider
  def registrar_cobranca(dados);            end  # -> { id, nosso_numero, linha_digitavel, pdf?, pix_emv }
  def consultar_cobranca(id);               end
  def baixar_cobranca(id);                  end
  def segunda_via(id);                      end
  def criar_pix_cob(dados);                 end  # cob/cobv (BACEN)
  def registrar_webhook(url, chave);        end
  def parse_webhook(payload);               end  # -> evento normalizado de pagamento
end
```
`SicoobProvider`/`C6Provider` implementam a interface; o restante do app fala só com `BankProvider`. Acrescentar um banco = novo provider, sem tocar no contrato.

---

## 5. Contrato HTTP (evolução, retrocompatível)

Mantém o que existe e adiciona o "registrado":

| Endpoint | Status | Observação |
|---|---|---|
| `GET /api/boleto`, `/data`, `/validate`, `/nosso_numero` | mantido | geração/cálculo local (não-registrado) — fallback |
| `POST /api/boleto/multi` | mantido | carnê PDF |
| `POST /api/remessa`, `/api/retorno` | **depreca** | CNAB legado vira fallback |
| **`POST /api/cobranca`** | **novo** | registra boleto no banco (provider por tenant) |
| **`GET /api/cobranca/:id`** | **novo** | consulta status |
| **`POST /api/cobranca/:id/baixa`** | **novo** | baixa/cancela |
| **`POST /api/pix/cob`** / **`/cobv`** | **novo** | PIX cobrança (BACEN) |
| **`POST /api/webhooks/:banco`** | **novo** | recebe callback de pagamento → evento normalizado |
| **`GET /api/eventos`** ou push | **novo** | entrega de eventos de pagamento ao Gestao-Contrato |

**Multi-tenant:** cada requisição identifica a **imobiliária/credencial** (header `X-Tenant` + API key). O gateway resolve o provider + credenciais/cert daquele tenant.

---

## 6. Gestão de credenciais e certificados por tenant ⚠️ (ponto crítico)

Cada imobiliária tem **suas** credenciais no banco (client_id, secret, **certificado .pfx**, chave PIX). O gateway precisa:

- **Cofre de segredos** (não em git/DB plano): KMS/Vault, ou DB com criptografia envelope; cert nunca em log.
- **Onboarding** do cliente: passo-a-passo para habilitar a API no Sicoob/C6 e subir o certificado (fricção real — prever suporte).
- **Rotação/expiração** de certificado (ICP-Brasil expira) — alertas.
- **Isolamento** estrito por tenant (um tenant nunca usa credencial de outro).

Este é o item de **maior esforço e risco** da migração — mais do que os endpoints em si.

---

## 7. Webhooks e conciliação

- **Substitui** parse de retorno CNAB pela **confirmação via webhook** (Sicoob PIX: callback `<url>/pix`; cobrança/boleto: notificação de liquidação).
- O motor de conciliação atual (OFX/`nosso_numero`) é **reaproveitado**, passando a casar por **id da cobrança/`txid`** do evento.
- Manter `ofx_service` (com fallback Python) para **extratos avulsos**/bancos sem webhook.

---

## 8. Plano faseado, esforço e riscos

| Fase | Entrega | Esforço | Risco |
|---|---|---|---|
| 0 | Onboarding técnico Sicoob + C6 (apps, cert, sandbox) — **validar incertezas da §2** | baixo (burocrático) | **alto** (disponibilidade C6) |
| 1 | `BankProvider` + `SicoobProvider` (cobrança + PIX `cob` + webhook) em sandbox | médio | médio (doc fraca) |
| 2 | Multi-tenant + cofre de credenciais/cert | médio-alto | **alto** (segurança) |
| 3 | `C6Provider` | médio | médio |
| 4 | Conciliação por webhook + ajuste `Parcela`/`nosso_numero`→`txid` no Gestao-Contrato | médio | médio |
| 5 | Carnê sobre cobranças registradas (PDF Prawn) | baixo-médio | baixo |
| 6 | Cutover por tenant (paralelo CNAB↔API) → depreca CNAB | médio | médio |

**Não fazer big-bang:** rodar **em paralelo** (CNAB atual + registro via API) num subconjunto de contratos antes do cutover.

### Decisões em aberto (precisam de você / banco)
- C6: sandbox, scopes, formato de certificado, disponibilidade PJ.
- Sicoob: sandbox de **Cobrança** (não só PIX), limites de rate.
- Modelo multi-tenant de certificados: KMS/Vault vs cripto no DB.
- Onde montar o carnê (gateway) e como tratar `nosso_numero`→`txid` no Gestao-Contrato.

---

## Nota de revisão (volume atual)

> **Atualização (volume ≈ 500 boletos/mês):** nesse patamar, o **build/manutenção da
> integração direta não se paga** — o custo marginal economizado (~R$1k/mês) não
> amortiza um build de R$30–60k. Para o volume atual a recomendação vira
> **PSP-first**, com **subconta white-label** (beneficiário = imobiliária). Ver
> [comparativo de PSP](./comparativo-psp-imobiliaria.md) (recomendado: **Asaas**).
> A arquitetura de gateway/adapter abaixo **continua válida** — muda só **qual é o
> primeiro provider** (PSP agora; **direto C6/Sicoob entra por gatilho de volume**,
> ~2–4 mil boletos/mês).

## 9. Recomendação

1. **Começar pelo Sicoob** (mais completo/BACEN-padrão) como primeiro `BankProvider` **direto**, em **sandbox** — válido **quando o volume justificar** (ver nota acima).
2. **C6 como 2º conector** direto, depois de validar onboarding/sandbox PJ.
3. **Evoluir a `boleto_cnab_api`** como gateway (Adapter), preservando o contrato do Gestao-Contrato e depreciando o CNAB gradualmente — **com PSP como primeiro provider** no volume atual.
4. Tratar **credenciais/cert por tenant** como épico de segurança próprio (maior risco).

---

## Fontes

- API PIX BACEN (padrão `cob`/`cobv`/`webhook`): https://github.com/bacen/pix-api
- Sicoob Developers: https://developers.sicoob.com.br
- SDK Sicoob (referência de endpoints/auth/scopes): https://github.com/SharpSistemas/SicoobAPI
- Sicoob Cobrança (Postman): https://documenter.getpostman.com/view/20565799/Uzs6yNhe
- Ativação PIX Sicoob (cert ICP-Brasil/client_id): https://ajuda.kobana.com.br/pt-BR/articles/8861634
- C6 APIs de integração: https://www.c6bank.com.br/apis-integracao/
- C6 Pix Cobrança PJ: https://www.c6bank.com.br/blog/c6-bank-lanca-pix-cobranca-para-clientes-pj
