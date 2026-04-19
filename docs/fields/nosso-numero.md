# Nosso Numero — Guia de Referencia por Banco

> O `nosso_numero` e o campo mais importante do boleto bancario. Este documento
> explica exatamente o que enviar e o que receber em cada fluxo da API.

## Resumo Rapido

```
VOCE ENVIA (valor cru)          BANCO RETORNA (formatado)
     "123"          ─────►      "01234567000000123"
                    boleto       (convenio + nn + DV)
```

| Fluxo | O que voce envia | O que voce recebe |
|-------|------------------|-------------------|
| **Gerar boleto** (`GET /api/boleto/*`) | `nosso_numero`: valor cru | `nosso_numero_boleto`: formatado com DV |
| **Remessa CNAB** (`POST /api/remessa`) | `pagamentos[].nosso_numero`: valor cru | (arquivo binario CNAB) |
| **Retorno CNAB** (`POST /api/retorno`) | (arquivo do banco) | `nosso_numero`: com zeros a esquerda |
| **Extrato OFX** (`POST /api/ofx/parse`) | (arquivo OFX) | `nosso_numero_extraido`: regex do memo |

---

## Tabela por Banco

### Entrada vs Saida

| Banco | Cod | Voce envia | API retorna (`nosso_numero`) | API retorna (`nosso_numero_boleto`) | DV |
|-------|-----|------------|------------------------------|-------------------------------------|:--:|
| **Banco do Brasil** | 001 | `"123"` | `"000000123"` | `"01234567000000123"` | 9 |
| **Sicoob** | 756 | `"7890"` | `"0007890"` | `"00078900"` | 0 |
| **Bradesco** | 237 | `"12345"` | `"00000012345"` | `"09/00000012345-8"` | 8 |
| **Itau** | 341 | `"12345678"` | `"12345678"` | `"175/12345678-4"` | 4 |
| **Caixa** | 104 | `"000000000000001"` | `"000000000000001"` | `"14000000000000001-4"` | 4 |
| **Santander** | 033 | `"1234567"` | `"1234567"` | `"1234567-9"` | 9 |
| **Banco C6** | 336 | `"12345678"` | `"0012345678"` | `"0012345678-9"` | 9 |

> **`nosso_numero`** = valor padronizado com zeros.
> **`nosso_numero_boleto`** = valor impresso no boleto (pode incluir carteira, convenio, DV).

### Composicao do `nosso_numero_boleto`

| Banco | Formato | Composicao |
|-------|---------|------------|
| **Banco do Brasil** | `CCCCCCCCNNNNNNNNN` (17 digitos) | `convenio(8)` + `nosso_numero(9)` |
| **Sicoob** | `NNNNNNND` (8 digitos) | `nosso_numero(7)` + `DV(1)` |
| **Bradesco** | `CC/NNNNNNNNNNN-D` | `carteira(2)` / `nosso_numero(11)` - `DV(1)` |
| **Itau** | `CCC/NNNNNNNN-D` | `carteira(3)` / `nosso_numero(8)` - `DV(1)` |
| **Caixa** | `CCNNNNNNNNNNNNNNN-D` | `carteira(2)` + `nosso_numero(15)` - `DV(1)` |
| **Santander** | `NNNNNNN-D` | `nosso_numero(7)` - `DV(1)` |
| **Banco C6** | `NNNNNNNNNN-D` | `nosso_numero(10)` - `DV(1)` |

---

## Campos Obrigatorios por Banco

### Campos comuns (todos os bancos)

```json
{
  "agencia": "...",              // obrigatorio
  "conta_corrente": "...",       // obrigatorio
  "nosso_numero": "...",         // obrigatorio
  "cedente": "...",              // obrigatorio
  "documento_cedente": "...",    // obrigatorio
  "sacado": "...",               // obrigatorio
  "sacado_documento": "...",     // obrigatorio
  "valor": 100.00,              // obrigatorio
  "data_vencimento": "2026/12/31" // obrigatorio
}
```

### Campos extras por banco

| Banco | Campos extras obrigatorios | Valores aceitos |
|-------|---------------------------|-----------------|
| **Banco do Brasil** | `convenio` | 4 a 8 digitos. Tamanho do nn depende do convenio |
| **Sicoob** | `convenio`, `variacao` | variacao: 2 digitos. `aceite` DEVE ser `"N"` |
| **Bradesco** | `carteira` | `"09"`, `"06"`, `"28"`, etc |
| **Itau** | `carteira` | `"109"`, `"175"`, `"180"`, `"174"`, etc |
| **Caixa** | `convenio`, `carteira` | carteira: `"1"` ou `"2"` somente |
| **Santander** | `convenio`, `carteira` | carteira: `"101"`, `"102"`, `"201"`, etc |
| **Banco C6** | `convenio`, `carteira` | carteira: `"10"` ou `"20"` somente |
| **Sicredi** | `posto`, `byte_idt` | posto: codigo da cooperativa |
| **Banrisul** | — | — |

### Campos extras opcionais por banco

| Banco | Campo extra opcional | Descricao |
|-------|---------------------|-----------|
| **Sicoob** | `numero_contrato` | Carteira 9 com contrato |
| **Itau** | `seu_numero` | Numero de controle interno |
| **Caixa** | `emissao` | Tipo de emissao |
| **Banrisul** | `digito_convenio` | DV do convenio |
| **Sicredi** | `byte_idt`, `posto` | Identificador + posto |
| **BRB** | `nosso_numero_incremento` | Incremento do nn |

---

## Tamanho do nosso_numero

| Banco | Minimo | Maximo | Observacao |
|-------|:------:|:------:|------------|
| **Banco do Brasil** | 1 | 17 | Depende do tamanho do convenio |
| **Sicoob** | 1 | 7 | Padronizado com zeros a esquerda |
| **Bradesco** | 1 | 11 | Padronizado com zeros a esquerda |
| **Itau** | 1 | 8 | Exatamente 8 digitos (com padding) |
| **Caixa** | 15 | 15 | Sempre 15 digitos |
| **Santander** | 1 | 7 | Maximo 7 digitos |
| **Banco C6** | 1 | 10 | Padronizado com zeros a esquerda |

### BB: tamanho depende do convenio

| Tamanho do convenio | Max nosso_numero |
|:-------------------:|:----------------:|
| 4 digitos | 7 digitos |
| 6 digitos | 5 ou 17 digitos |
| 7 digitos | 10 digitos |
| 8 digitos | 9 digitos |

---

## Remessa CNAB — O que enviar

No `POST /api/remessa`, cada pagamento deve ter `nosso_numero`:

```json
{
  "empresa_mae": "Empresa LTDA",
  "documento_cedente": "12345678000100",
  "agencia": "3073",
  "conta_corrente": "12345678",
  "convenio": "01234567",
  "carteira": "18",
  "pagamentos": [
    {
      "nosso_numero": "123",
      "data_vencimento": "2026/12/31",
      "valor": 100.00,
      "nome_sacado": "Joao da Silva",
      "documento_sacado": "12345678900",
      "endereco_sacado": "Rua X, 1",
      "cidade_sacado": "Sao Paulo",
      "uf_sacado": "SP",
      "cep_sacado": "01000000"
    }
  ]
}
```

> **Envie o valor CRU** — o mesmo que voce usou para gerar o boleto.
> A gem padroniza com zeros automaticamente ao gerar o arquivo CNAB.

### Mapeamento de campos do Pagamento

A API converte automaticamente nomes amigaveis para os nomes da gem:

| Voce envia | Gem recebe |
|------------|-----------|
| `sacado` | `nome_sacado` |
| `sacado_documento` | `documento_sacado` |
| `sacado_endereco` | `endereco_sacado` |
| `sacado_cidade` | `cidade_sacado` |
| `sacado_uf` | `uf_sacado` |
| `sacado_cep` | `cep_sacado` |
| `numero_documento` | `numero` |

---

## Retorno CNAB — O que receber

No `POST /api/retorno`, o banco retorna o `nosso_numero` com zeros a esquerda:

```json
[
  {
    "nosso_numero": "00000000000000123",
    "documento_numero": "NF-001",
    "codigo_ocorrencia": "06",
    "data_ocorrencia": "2026-01-15",
    "data_credito": "2026-01-16",
    "valor_titulo": 100.0,
    "valor_recebido": 100.0,
    "valor_tarifa": 2.50
  }
]
```

### Conciliacao (retorno → boleto)

Para casar o retorno com o boleto original, normalize removendo zeros:

```python
nn_boleto = "123"                       # seu cadastro
nn_retorno = "00000000000000123"        # do retorno CNAB

# Opcao 1: comparar como inteiro
match = int(nn_boleto) == int(nn_retorno)  # True

# Opcao 2: strip de zeros
match = nn_retorno.lstrip('0') == nn_boleto  # True
```

---

## Extrato OFX — O que receber

No `POST /api/ofx/parse`, o `nosso_numero_extraido` e obtido via regex do campo `memo`:

```json
{
  "memo": "COBRANCA SICOOB 0000012345",
  "nosso_numero_extraido": "0000012345"
}
```

### Conciliacao (OFX → boleto)

O valor do OFX **pode incluir DV** ou **convenio+nn**. A conciliacao requer normalizacao:

```python
nn_boleto = "7890"                   # seu cadastro (Sicoob)
nn_ofx = "0000012345"               # extraido do memo OFX

# Opcao 1: o nn_ofx pode ser nosso_numero_boleto (com DV)
# No Sicoob: nosso_numero_boleto = "00078900" (nn=0007890, DV=0)
# O OFX pode ter formato diferente dependendo do banco

# Opcao 2: normalizar e comparar parcial
nn_boleto_padded = nn_boleto.zfill(7)  # "0007890"
match = nn_boleto_padded in nn_ofx     # depende do formato do banco

# Opcao 3: comparar os ultimos N digitos significativos
match = nn_ofx.endswith(nn_boleto) or nn_ofx.rstrip('0').endswith(nn_boleto)
```

> **Recomendacao:** Ao emitir boletos, armazene tanto o `nosso_numero` cru quanto
> o `nosso_numero_boleto` retornado pela API. Isso facilita a conciliacao com OFX e CNAB.

---

## Diagrama do Fluxo Completo

```
                     VOCE                              BANCO
                      |                                  |
  1. Cria boleto      |                                  |
     nn="123"         |                                  |
                      |                                  |
  2. API retorna      |                                  |
     nn_boleto=       |                                  |
     "01234567        |                                  |
      000000123"      |                                  |
                      |                                  |
  3. Gera remessa     |  ──── arquivo CNAB ────────►     |
     nn="123"         |       (nn com zeros)             |
                      |                                  |
  4. Banco processa   |                                  |
                      |                                  |
  5. Recebe retorno   |  ◄──── arquivo CNAB ────────     |
     nn=              |       "00000000000000123"        |
     "00000000000     |                                  |
      000000123"      |                                  |
                      |                                  |
  6. Recebe OFX       |  ◄──── extrato OFX ─────────    |
     memo=            |       (texto livre com nn)       |
     "COBRANCA BB     |                                  |
      01234567        |                                  |
      000000123"      |                                  |
     nn_extraido=     |                                  |
     "01234567        |                                  |
      000000123"      |                                  |
```

---

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) — M&S do Brasil LTDA
