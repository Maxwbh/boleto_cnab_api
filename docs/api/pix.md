# PIX Híbrido no Boleto

> **Versão:** 1.3.0 (brcobranca v12.6.1+)

O boleto híbrido combina **boleto bancário tradicional** com **QR Code PIX**, permitindo que o sacado escolha pagar via código de barras/linha digitável OU via PIX.

## Bancos com Suporte a PIX Híbrido

| Banco | Código | Suporte PIX |
|-------|--------|:-----------:|
| Banco do Brasil | 001 | ✅ |
| Santander | 033 | ✅ |
| Caixa | 104 | ✅ |
| Bradesco | 237 | ✅ |
| Banco C6 | 336 | ✅ |
| Itaú | 341 | ✅ |
| Sicredi | 748 | ✅ |
| Sicoob | 756 | ✅ |

Outros bancos (Banrisul, Unicred, Ailos, etc) ainda não têm suporte a PIX na gem.

## Como Gerar Boleto com PIX

Adicione o campo `emv` (payload EMV do PIX) nos dados do boleto:

```python
import requests, json

boleto_data = {
    # Dados padrão do boleto
    "agencia": "3073",
    "conta_corrente": "12345678",
    "convenio": "01234567",
    "carteira": "18",
    "nosso_numero": "123",
    "cedente": "Empresa LTDA",
    "documento_cedente": "12345678000100",
    "sacado": "João da Silva",
    "sacado_documento": "12345678900",
    "valor": 1500.00,
    "data_vencimento": "2026/12/31",

    # Campos PIX
    "emv": "00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-426614174000520400005303986540515005802BR5913Empresa LTDA6009SAO PAULO62070503***6304AB12",
    "pix_label": "Escaneie para pagar via PIX"
}

# Gerar boleto híbrido
response = requests.get(
    "http://localhost:9292/api/boleto",
    params={
        "bank": "banco_c6",
        "type": "pdf",
        "data": json.dumps(boleto_data)
    }
)

with open('boleto_pix.pdf', 'wb') as f:
    f.write(response.content)
```

O PDF gerado contém:

- Linha digitável tradicional
- Código de barras
- **QR Code PIX** embutido
- Texto do `pix_label` ao lado do QR Code

## Campo `emv`

O `emv` é o payload EMV do PIX (string alfanumérica). Pode ser gerado por:

- API do próprio banco (endpoint de cobrança PIX com vencimento)
- Lib geradora de EMV (ex: [pix-payload](https://github.com/orbsborges/pix-payload))
- Portal PIX do Banco Central

### Exemplo de payload EMV mínimo

```
00020126580014br.gov.bcb.pix0136{chave_pix}5204{mcc}5303986540{valor}5802BR59{nome}60{cidade}62070503***6304{crc16}
```

Campos principais (padrão BR Code do BCB):

| Tag | Descrição |
|-----|-----------|
| 00 | Payload Format Indicator (sempre `01`) |
| 26 | Merchant Account Information (GUI + chave PIX) |
| 52 | Merchant Category Code (normalmente `0000`) |
| 53 | Transaction Currency (`986` = BRL) |
| 54 | Transaction Amount (ex: `15.00`) |
| 58 | Country Code (`BR`) |
| 59 | Merchant Name (máx 25 chars) |
| 60 | Merchant City (máx 15 chars) |
| 62 | Additional Data (txid) |
| 63 | CRC16 (hash) |

**Validar payload EMV:** use [Validador PIX do BCB](https://www.bcb.gov.br/estabilidadefinanceira/pix).

## Response da API

Ao chamar `/api/boleto/data` com `emv`, o response inclui objeto `pix`:

```json
{
  "bank": "banco_c6",
  "nosso_numero": "00123-4",
  "codigo_barras": "33691...",
  "linha_digitavel": "33690...",
  "pix": {
    "emv": "00020126580014br.gov.bcb.pix...",
    "qrcode_base64": null
  }
}
```

> **Nota:** `qrcode_base64` é populado quando a gem gera o QR Code renderizado. Em alguns casos retorna `null` — o EMV pode ser convertido em QR Code pelo cliente usando qualquer lib (ex: `qrcode` do Python, `qrcode.js`).

## Gerando QR Code no Cliente

Se você preferir gerar o QR Code localmente:

```python
import qrcode
from io import BytesIO

emv = response.json()['pix']['emv']
qr = qrcode.make(emv)

buffer = BytesIO()
qr.save(buffer, format='PNG')
qrcode_bytes = buffer.getvalue()
```

## Particularidades por Banco

### Sicoob (756)

- EMV deve estar conforme layout Sicoob específico
- Conta deve ter cobrança PIX habilitada
- Recomenda-se gerar o EMV via API Cobrança Bancária V3 do Sicoob

### Banco C6 (336)

- Requer convênio com PIX habilitado no C6
- Carteira `'10'` ou `'20'` compatível com PIX
- QR Code fica impresso no lado direito do boleto

### Banco do Brasil (001)

- Layout antigo (não CIP) aceita EMV direto
- Layout novo (CIP) requer integração via API oficial de cobrança

## Troubleshooting

### QR Code não aparece no PDF

1. Confirme que o banco está na lista de suporte (tabela acima)
2. Verifique que `emv` é string válida (não nil/vazia)
3. Valide o CRC16 do payload EMV
4. Cheque se a gem foi atualizada (`bundle update brcobranca`)

### "Merchant category code inválido"

EMV mal formado. Use uma lib validadora ou gere via API do banco.

### Banco retorna erro de validação

Alguns bancos (Sicoob, BB) validam o EMV contra seu padrão específico. Consulte o manual técnico do banco.

## Referências

- [Manual de Padrões para Iniciação do PIX (BCB)](https://www.bcb.gov.br/estabilidadefinanceira/pix)
- [Brcobranca PIX (gem)](https://github.com/Maxwbh/brcobranca)
- [Troubleshooting geral](./troubleshooting.md)
- [OpenAPI spec](../openapi.yaml) (schemas `BoletoData.emv` e `BoletoResponse.pix`)

---

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) — M&S do Brasil LTDA
