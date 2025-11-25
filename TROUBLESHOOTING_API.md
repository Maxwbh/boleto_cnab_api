# Troubleshooting - BRCobranca API

Este guia ajuda a resolver problemas comuns ao usar a API de boletos.

## 📊 Logs Melhorados

A partir da versão com commit `a91cbc5`, a API possui logging detalhado com emojis para facilitar identificação:

- 📥 Requisição recebida
- ✅ Operação bem-sucedida
- ⚠️  Aviso (validação falhou, mas é esperado)
- ❌ Erro

## Erro: "type is missing"

### Problema
```json
{
  "error": "type is missing"
}
```

### Causa
O endpoint `/api/boleto` (GET) requer 3 parâmetros obrigatórios:
1. `bank` - Nome do banco (ex: "sicoob", "itau", "banco_brasil")
2. `type` - Tipo de saída (deve ser: "pdf", "jpg", "png" ou "tif")
3. `data` - JSON com os dados do boleto

### Solução

#### ❌ Errado (falta o parâmetro `type`):
```python
response = requests.get(
    f"{API_URL}/api/boleto",
    params={
        "bank": "sicoob",
        # FALTA O TYPE!
        "data": json.dumps(boleto_data)
    }
)
```

#### ✅ Correto:
```python
response = requests.get(
    f"{API_URL}/api/boleto",
    params={
        "bank": "sicoob",
        "type": "pdf",  # OBRIGATÓRIO!
        "data": json.dumps(boleto_data)
    }
)
```

### Logs que você verá agora

Com o logging melhorado, quando faltar o parâmetro `type`, você verá no log da API:

```
❌ Erro inesperado: Grape::Exceptions::ValidationErrors - type is missing
```

E a resposta HTTP será:
```json
{
  "error": "type is missing"
}
```

## Outros Erros Comuns

### 1. JSON Inválido

**Log da API:**
```
❌ JSON inválido: unexpected token at '{'valor': 100}'
```

**Resposta HTTP:**
```json
{
  "error": "JSON inválido",
  "details": "unexpected token at '{'valor': 100}'"
}
```

**Solução:** Verifique se o JSON está bem formatado (use aspas duplas, não simples).

---

### 2. Boleto Inválido (campos obrigatórios faltando)

**Log da API:**
```
❌ Boleto inválido. Erros: {:nosso_numero=>["não pode ficar em branco"], :agencia=>["não é um número"]}
```

**Resposta HTTP:**
```json
{
  "error": "Dados do boleto inválidos",
  "validation_errors": {
    "nosso_numero": ["não pode ficar em branco"],
    "agencia": ["não é um número"]
  },
  "hint": "Verifique se todos os campos obrigatórios estão preenchidos corretamente"
}
```

**Solução:** Preencha todos os campos obrigatórios. Veja `CAMPOS_BOLETOS_POR_BANCO.md`.

---

### 3. Linha Digitável / Código de Barras Vazios

**Causa:** O campo `nosso_numero` não foi informado ou outros campos obrigatórios estão faltando.

**Como debugar:**
1. Use o endpoint `/api/boleto/validate` ANTES de gerar o PDF:
```python
response = requests.get(
    f"{API_URL}/api/boleto/validate",
    params={
        "bank": "sicoob",
        "data": json.dumps(boleto_data)
    }
)
```

2. Verifique a resposta:
```json
{
  "valid": false,
  "validation_errors": {
    "nosso_numero": ["não pode ficar em branco"]
  },
  "hint": "Corrija os erros de validação antes de gerar o boleto"
}
```

---

### 4. Campo `numero_documento` vs `nosso_numero`

**IMPORTANTE:** Estes são campos diferentes!

- **`nosso_numero`**: Obrigatório, faz parte do código de barras
- **`numero_documento`**: Opcional, apenas para controle interno (NF, pedido)

Se a linha digitável está vazia, provavelmente falta o `nosso_numero`, NÃO o `numero_documento`.

---

## Como Usar os Endpoints

### 1. Validar antes de gerar
```python
# PASSO 1: Validar
validate_response = requests.get(
    f"{API_URL}/api/boleto/validate",
    params={"bank": "sicoob", "data": json.dumps(boleto_data)}
)

if validate_response.status_code == 200:
    print("✅ Válido! Pode gerar o PDF")

    # PASSO 2: Gerar PDF
    pdf_response = requests.get(
        f"{API_URL}/api/boleto",
        params={
            "bank": "sicoob",
            "type": "pdf",  # NÃO ESQUECER!
            "data": json.dumps(boleto_data)
        }
    )
else:
    print("❌ Inválido:")
    print(validate_response.json())
```

### 2. Obter dados sem gerar PDF (mais rápido)
```python
data_response = requests.get(
    f"{API_URL}/api/boleto/data",
    params={"bank": "sicoob", "data": json.dumps(boleto_data)}
)

if data_response.status_code == 200:
    dados = data_response.json()
    print(f"Nosso Número: {dados['nosso_numero']}")
    print(f"Código de Barras: {dados['codigo_barras']}")
    print(f"Linha Digitável: {dados['linha_digitavel']}")
```

---

## Logs Detalhados por Endpoint

### GET /api/boleto/validate
```
📥 GET /api/boleto/validate - Validando banco: sicoob
✅ JSON parseado. Campos: valor, cedente, agencia, conta_corrente, ...
✅ Validação OK para banco sicoob
```

### GET /api/boleto/data
```
📥 GET /api/boleto/data - Obtendo dados do boleto para banco: sicoob
✅ Dados do boleto gerados com sucesso
   Nosso Número: 0001234-5
   Código de Barras: 75691234567890123456789012345678901234567890
```

### GET /api/boleto
```
📥 GET /api/boleto - Params recebidos: bank=sicoob, type=pdf
✅ JSON parseado com sucesso. Campos: valor, cedente, agencia, ...
✅ Boleto válido. Gerando PDF...
```

### POST /api/boleto/multi
```
📥 POST /api/boleto/multi - Gerando múltiplos boletos em PDF
✅ JSON parseado. Total de boletos: 3
   Processando boleto 1/3 - Banco: sicoob
   ✅ Boleto 1 válido
   Processando boleto 2/3 - Banco: banco_brasil
   ✅ Boleto 2 válido
   Processando boleto 3/3 - Banco: itau
   ✅ Boleto 3 válido
✅ Todos os 3 boletos são válidos. Gerando arquivo PDF...
```

---

## Checklist para Debug

Quando um boleto não gera corretamente:

1. ☑️ Verifique se todos os 3 parâmetros estão sendo enviados: `bank`, `type`, `data`
2. ☑️ Verifique se o JSON está válido (use `json.dumps()` em Python)
3. ☑️ Use `/api/boleto/validate` para verificar erros de validação
4. ☑️ Verifique se o campo `nosso_numero` está presente
5. ☑️ Verifique se `data_vencimento` está no formato `YYYY/MM/DD`
6. ☑️ Consulte `CAMPOS_BOLETOS_POR_BANCO.md` para campos obrigatórios do banco
7. ☑️ Veja os logs da API para identificar o erro exato

---

## Suporte

- 📖 Documentação completa: `README.md`
- 📋 Campos por banco: `CAMPOS_BOLETOS_POR_BANCO.md`
- 🐛 Reportar bugs: https://github.com/Maxwbh/boleto_cnab_api/issues

---

**Última atualização:** 2025-11-25
**Versão da API com logging melhorado:** commit `a91cbc5`
