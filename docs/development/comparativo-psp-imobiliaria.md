# Comparativo de PSP para imobiliária — Asaas × Efí × Iugu × Woovi/OpenPix

> Complemento do [spike de gateway bancário](./gateway-bancario-spike.md).
> Status: **proposta** · Data: 2026-06-17.
> Contexto: **Gestao-Contrato**, cobrança de **aluguel/prestação** (boleto + PIX),
> **multi-imobiliária**, **volume atual ≈ 500 boletos/mês**.
> ⚠️ Tarifas mudam e são **negociáveis** — confirmar com cada PSP antes de fechar.

---

## Requisitos do nosso caso (filtro)

1. **Boleto + PIX** (híbrido) — boleto é requisito de 1ª classe, não secundário.
2. **Subconta/white-label por API** — o boleto precisa sair **no nome/CNPJ da imobiliária** (beneficiário correto) e liquidar para a conta dela. Multi-tenant sob **uma** integração.
3. **Split** (comissão da imobiliária/plataforma) — desejável.
4. **Webhook** de pagamento + conciliação.
5. **Baixo custo fixo** (volume baixo: 500/mês não comporta mensalidade alta).

---

## Comparativo

| Critério | **Asaas** | **Efí** | **Iugu** | **Woovi/OpenPix** |
|---|---|---|---|---|
| Boleto | ✅ maduro | ✅ (Bolix) | ✅ | ⚠️ **secundário/imaturo** |
| PIX | ✅ | ✅ (barato) | ✅ | ✅ (foco PIX) |
| **Subconta via API** (white-label) | ✅ **completo** (conta p/ cada cliente, emite no próprio nome) | ❌ **não cria subconta via API** | ✅ (BaaS/subadquirente) | ✅ (subconta c/ chave PIX p/ saque) |
| Split (boleto/PIX) | ✅ PIX, boleto e cartão | ⚠️ split **só PIX**, **só entre contas Efí**, máx. 20 | ✅ | ✅ (foco PIX) |
| Webhook | ✅ | ✅ | ✅ | ✅ |
| Custo fixo mensal | **R$0** | **R$0** | **R$49–499/mês** | plano (free → pago) |
| Tarifa boleto (liquidado) | ~**R$3,49** (cai por volume/plano) | barato (confirmar) | ~**R$1,99** | n/d (boleto novo) |
| Tarifa PIX | R$0,99→R$1,99; **100/mês grátis** por chave | 0,99% (<R$90) / R$0,89 (≥R$90) | 0,99% | ~1% |
| Beneficiário = imobiliária | ✅ (subconta) | ⚠️ só com 1 conta por cliente (sem API) | ✅ | ⚠️ modelo de comissão em subconta |
| Fit imobiliária | ✅ **forte no nicho** | médio | médio (marketplace grande) | PIX-first |

---

## Leitura por PSP

- **Asaas** — único que cobre **todos** os requisitos: boleto+PIX maduros, **subconta white-label por API** (beneficiário = imobiliária), split nos 3 meios, **sem mensalidade**, e é **forte no nicho imobiliário**. Contra: tarifa de **boleto mais alta (~R$3,49)** — negociar por volume.
- **Efí** — PIX/boleto baratos, ótimo para **uma** conta. **Mas não cria subconta via API** e split PIX é só entre contas Efí → **não atende o modelo multi-imobiliária white-label**. Descartado para esse desenho (serviria se você centralizasse tudo numa conta só).
- **Iugu** — subadquirente/marketplace robusto (licença BaaS), bom split. Contra: **mensalidade R$49–499** pesa em 500/mês; melhor quando escalar.
- **Woovi/OpenPix** — excelente em PIX e subconta, **mas boleto é imaturo/secundário** → arriscado quando o boleto é core do aluguel.

---

## TCO direcional — 500 boletos/mês (~400 liquidados)

> Estimativa grosseira; mix real boleto/PIX e plano mudam tudo.

| | Marginal/mês | Fixo/mês | Observação |
|---|---|---|---|
| **Asaas** | ~R$800–1.400 (boleto R$3,49; PIX com 100 grátis) | R$0 | beneficiário/cliente ok via subconta |
| **Iugu** | ~R$800 (boleto R$1,99) | **R$49–499** | mensalidade dilui só em volume |
| **Efí** | baixo | R$0 | **sem subconta API** → fora do modelo |
| **Woovi** | ~1% | plano | **boleto imaturo** |

A R$ marginal de Asaas vs Iugu é parecida; **Asaas vence por não ter mensalidade + subconta madura + nicho imobiliário**. A tarifa de boleto do Asaas é o ponto a negociar.

---

## Recomendação

1. **Asaas** como **PSP inicial** (1º provider do gateway). Atende boleto+PIX+subconta(white-label)+split+webhook, sem custo fixo, com o **beneficiário sendo a imobiliária**. Negociar a tarifa de boleto por volume.
2. A `boleto_cnab_api` vira **fachada fina** sobre o Asaas (mantém o contrato que o Gestao-Contrato já consome; troca o backend CNAB→PSP nos `financeiro/services/*`).
3. **Reavaliar Iugu** se a mensalidade se diluir (volume) ou se precisar de recursos de marketplace mais fortes.
4. **Direto C6/Sicoob** (spike) entra **por gatilho de volume** (~2–4 mil boletos/mês), não agora.

> **Atualização da recomendação do spike:** no volume atual (500/mês), o **PSP-first (Asaas)** ganha do **direto-first**; o direto continua válido como evolução por volume. Ver nota no [spike](./gateway-bancario-spike.md#nota-de-revisao-volume-atual).

---

## Parceria & monetização (split / revenue-share)

O Asaas tem **Programa de Parcerias** voltado a **SaaS/ERP/marketplaces** (além de
indicação/afiliados). Para a plataforma, isso transforma o PSP de **custo** em
**fonte de receita** — é o ângulo "embedded finance".

### Como se monetiza
1. **Split por transação** (principal): em cada cobrança da subconta (imobiliária),
   um split destina **uma fatia para a conta principal** (sua). Você vira
   **co-beneficiário** de cada boleto/PIX — receita **por transação**, na origem,
   automática. É como cobrar além (ou no lugar) da mensalidade do SaaS.
2. **Condições comerciais por volume**: tarifas diferenciadas pelo **volume agregado**
   de todas as subcontas; a diferença entre a tarifa que você paga e a que repassa à
   imobiliária pode virar **margem**. Negociado no programa de parceria.

### Custos/mecânica a considerar
- **Abertura de subconta é tarifada** — você escolhe **absorver** (conta principal)
  ou **repassar** à subconta.
- Split funciona em **PIX, boleto e cartão**, configurável por cobrança.

### ⚠️ Due diligence (pontos honestos)
- **% de split permitido, revenue-share e tarifas de parceiro NÃO são públicos** —
  dependem de negociação com o comercial/parceria.
- Há **reclamações** (Reclame Aqui) de "parceria white-label frustrada por falta de
  previsão/comunicação" — validar **SLA de homologação, prazos e suporte** antes de
  comprometer roadmap.

### Perguntas para a reunião comercial (Asaas)
- Tarifa de **boleto** e **PIX** por **faixa de volume agregado** (subcontas somadas).
- **% de split** permitido para a conta principal e **quem assume a tarifa** no split.
- **Custo de abertura/manutenção** de subconta e quem absorve.
- **KYC/onboarding** da subconta (documentos, prazo médio de aprovação por imobiliária).
- **Liquidação**: prazo do boleto (D+?), saque da subconta para o banco da imobiliária.
- **White-label**: nível de personalização (marca nos boletos/portal) e **SLA de homologação**.
- **Webhook**: eventos (criação/liquidação/estorno) e **assinatura/segurança**.
- **Condições do Programa de Parceria** (revenue-share, suporte dedicado, sandbox).

> **Impacto na decisão:** o revenue-share via split é um argumento **a favor do
> Asaas vs. integração direta** — no direto C6/Sicoob **não há** essa monetização
> embutida (você só evita tarifa; não ganha por transação de terceiros).

---

## A confirmar com o PSP escolhido (antes de codar)
- Tarifa real de **boleto** e **PIX** por volume/plano (negociação).
- **Subconta**: onboarding (KYC) de cada imobiliária, prazos, limites.
- **Liquidação**: prazo (boleto D+?, PIX na hora) e saque da subconta para o banco da imobiliária.
- **Split**: regras (percentual/fixo), e quem assume a tarifa.
- **Webhook**: eventos disponíveis (criação, liquidação, estorno) e segurança (assinatura).

## Fontes
- Asaas — white-label/subcontas: https://docs.asaas.com/docs/sobre-white-label · split: https://blog.asaas.com/split-de-pagamento/ · PIX: https://www.asaas.com/pix-asaas
- Efí — split/subcontas (limitações): https://comunidade.sejaefi.com.br/discussao/split-pix-criacao-subcontas-59 · tarifas: https://sejaefi.com.br/tarifas
- Iugu — split/marketplace: https://www.iugu.com/split-pagamentos · API: https://dev.iugu.com/docs/introdução
- Woovi/OpenPix — split/subconta: https://developers.woovi.com/en/docs/charge/how-to-create-charge-with-split-to-subbaccount-using-api · planos: https://woovi.com/planos-e-precos/
