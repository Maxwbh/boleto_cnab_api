# Handoff — integrar o Gestão-Contrato (Django) ao Boleto-API (Python)

> Prompt de entrega para a sessão Claude do repo `Maxwbh/Gestao-Contrato`.
> Data: 2026-06-17. Decisões confirmadas: **push de eventos = sim**, **`/carne` = sim**
> (ambos já implementados no lado Boleto-API).

## Esquema de assinatura do push (o Django valida igual)
O Boleto-API encaminha o evento via `POST` assinado:
- Header: `X-Signature: sha256=<hex(hmac_sha256(BOLETO_API_WEBHOOK_SECRET, raw_body))>`
- Body: JSON compacto (sem espaços), UTF-8.
- Validar com `hmac.compare_digest` (timing-safe) sobre o corpo **bruto**.

Contrato do evento (WebhookEvent): `{ event, id, status, paid_at, valor, raw }`,
`status ∈ registrado|pendente|liquidado|baixado|erro`.

---

## Prompt

```
Tarefa: integrar o Gestão-Contrato (Django) ao novo Boleto-API (Python/FastAPI),
migrando de geração CNAB/boleto direto para COBRANÇA REGISTRADA + conciliação por
evento (push), mantendo CNAB como fallback.

## Contexto (3 produtos)
- BrCobrança (Ruby): engine de renderização (boleto/CNAB/carnê/PIX-QR), em /api/render/*.
- Boleto-API (Python/FastAPI): GATEWAY bancário. Registra cobrança no banco
  (C6/Sicoob via OAuth+mTLS), guarda credenciais por tenant (cofre), recebe webhook
  do banco e ENCAMINHA (push) um evento normalizado assinado ao Gestão-Contrato.
- Gestão-Contrato (este repo, Django 4.2): domínio. Decide QUANDO/o que emitir e
  concilia pagamento -> baixa de parcela. Fala SÓ com o Boleto-API.

## Contrato do Boleto-API (já construído)
POST /cobranca
  body: { tenant_id, provider("c6"|"sicoob"|"brcobranca"), account_config{...},
          cobranca{ valor, vencimento, nosso_numero?, seu_numero?,
                    pagador{nome,documento,endereco?}, multa?, juros?, desconto? } }
  -> CobrancaOut { id, status, linha_digitavel, codigo_barras, pix_copia_cola, pdf_base64, raw }
  status ∈ registrado|pendente|liquidado|baixado|erro
GET    /cobranca/{id}?tenant_id=&provider=  -> CobrancaOut
DELETE /cobranca/{id}?tenant_id=&provider=  -> CobrancaOut (baixa)
POST   /carne  body: { tenant_id, provider, account_config, bank, parcelas:[cobranca...] }
  -> { carne_pdf_base64, cobrancas:[CobrancaOut...] }   (registra N + monta carnê 3-vias)

Push de pagamento (Boleto-API -> este repo):
  POST <GESTAO_CONTRATO_WEBHOOK_URL>
  header X-Signature: sha256=<hmac_sha256(secret, raw_body)>
  body { event, id, status, paid_at, valor, raw }

account_config (blob por provider): c6 {agencia,conta,convenio};
  sicoob {cooperativa,conta,numeroCliente,codigoModalidade}.
Credenciais bancárias (client_id/secret/.pfx) NÃO ficam no Django — ficam no cofre
do Boleto-API, resolvidas por tenant_id.

## Implementar neste repo (Django)
1. financeiro/services/boleto_api_client.py: registrar_cobranca / consultar / baixar /
   gerar_carne, com timeouts, retries e logging sem vazar dados sensíveis.
2. Multi-tenant: na imobiliária/conta adicionar provider, account_config (JSONField),
   tenant_id. Migration.
3. Emissão: ao gerar parcela, registrar_cobranca e PERSISTIR o id em
   Parcela.cobranca_id (nova coluna + migration). Carnê via POST /carne.
4. Receber push: endpoint POST /financeiro/webhooks/boleto-api que
   - valida X-Signature com hmac.compare_digest sobre o corpo bruto (REUSAR a
     proteção timing-attack do webhook de PIX já existente)
   - casa event.id com Parcela.cobranca_id e, em status=liquidado, dá BAIXA
     idempotente (não baixar 2x), gravando paid_at/valor.
5. Chave de conciliação: migrar nosso_numero_formatado -> cobranca_id/txid, com
   compatibilidade na transição.
6. Feature flag por imobiliária ("cobranca_registrada"): liga o novo fluxo; desligada
   mantém o CNAB atual. Cutover gradual, nunca big-bang.

## Configuração
BOLETO_API_URL, BOLETO_API_WEBHOOK_SECRET (o MESMO secret configurado no Boleto-API).
Não armazenar segredo bancário no Django.

## Verificação
- Testes mockando o Boleto-API: registrar persiste cobranca_id; push liquidado baixa
  a parcela idempotente; assinatura inválida é rejeitada.
- Suíte completa (1335+ testes) sem novas falhas.
- Fluxo CNAB funcionando com a flag desligada.

## Convenções
- Branch própria, commits descritivos, PR draft.
- Rodar novo fluxo em paralelo ao CNAB num subconjunto antes do cutover.
```
