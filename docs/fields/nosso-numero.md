# Nosso Numero — Guia de Referencia por Banco

> O `nosso_numero` e o campo mais importante do boleto bancario. Este documento
> explica exatamente o que enviar e o que receber em cada fluxo da API.

## Resumo Rapido

```
VOCE ENVIA (valor cru)          API RETORNA (3 campos)
     "123"          ─────►      nosso_numero:           "000000123"
                    boleto       nosso_numero_formatado:  "01234567000000123"
                                 nosso_numero_dv:         "9"
```

| Fluxo | O que voce envia | O que voce recebe |
|-------|------------------|-------------------|
| **Gerar boleto** (`GET /api/boleto/*`) | `nosso_numero`: valor cru | 3 campos: `nosso_numero` + `nosso_numero_formatado` + `nosso_numero_dv` |
| **Remessa CNAB** (`POST /api/remessa`) | `pagamentos[].nosso_numero`: valor cru | (arquivo binario CNAB) |
| **Retorno CNAB** (`POST /api/retorno`) | (arquivo do banco) | `nosso_numero`: com zeros a esquerda |
| **Extrato OFX** (`POST /api/ofx/parse`) | (arquivo OFX) | `nosso_numero_extraido`: regex do memo |

---

## Campos Retornados pela API

A API retorna **3 campos distintos** para nosso_numero em `GET /api/boleto/data` e `GET /api/boleto/nosso_numero`:

| Campo | Descricao | Exemplo (BB) |
|-------|-----------|:-------------|
| **`nosso_numero`** | Valor padronizado com zeros (SEM convenio, SEM DV) | `"000000123"` |
| **`nosso_numero_formatado`** | Valor IMPRESSO no boleto (com carteira/convenio/DV) | `"01234567000000123"` |
| **`nosso_numero_dv`** | Digito verificador isolado | `"9"` |

> Alias: `nosso_numero_boleto` = mesmo valor de `nosso_numero_formatado` (compatibilidade)

---

## Tabela por Banco

### Entrada vs Saida

| Banco | Cod | Voce envia | `nosso_numero` | `nosso_numero_formatado` | `nosso_numero_dv` |
|-------|-----|------------|----------------|--------------------------|:-----------------:|
| **Banco do Brasil** | 001 | `"123"` | `"000000123"` | `"01234567000000123"` | `9` |
| **Sicoob** | 756 | `"7890"` | `"0007890"` | `"00078900"` | `0` |
| **Bradesco** | 237 | `"12345"` | `"00000012345"` | `"09/00000012345-8"` | `8` |
| **Itau** | 341 | `"12345678"` | `"12345678"` | `"175/12345678-4"` | `4` |
| **Caixa** | 104 | `"000000000000001"` | `"000000000000001"` | `"14000000000000001-4"` | `4` |
| **Santander** | 033 | `"1234567"` | `"1234567"` | `"1234567-9"` | `9` |
| **Banco C6** | 336 | `"12345678"` | `"0012345678"` | `"0012345678-9"` | `9` |

> **`nosso_numero`** = valor padronizado (SEM formatacao de impressao).
> **`nosso_numero_formatado`** = valor impresso no boleto (com carteira/convenio/DV).

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

No `POST /api/ofx/parse`, o `nosso_numero_extraido` e obtido via regex do campo `memo`.

> **Importante:** O formato do campo `<MEMO>` no OFX nao e padronizado.
> Cada banco escreve o texto de forma diferente. A API usa regex especifica
> por banco para extrair a sequencia numerica mais provavel.

### Padroes conhecidos de MEMO por banco

| Banco | Exemplo de MEMO no OFX | Regex da API | nosso_numero_extraido |
|-------|------------------------|-------------|----------------------|
| **Sicoob** (756) | `"COBRANCA SICOOB 0000012345"` | `\d{7,12}` | `"0000012345"` |
| **Sicoob** (756) | `"COB BOLETO SICOOB 00078900"` | `\d{7,12}` | `"00078900"` |
| **Itau** (341) | `"RECEBIMENTO BOLETO 12345678"` | `\d{8}` | `"12345678"` |
| **Itau** (341) | `"PAG COBRANCA 87654321"` | `\d{8}` | `"87654321"` |
| **BB** (001) | `"BB COB 01234567000000123"` | `\d{10,17}` | `"01234567000000123"` |
| **BB** (001) | `"COBRANCA BB 1234567890"` | `\d{10,17}` | `"1234567890"` |
| **Bradesco** (237) | `"BRADESCO COB 12345678901"` | `\d{11}` | `"12345678901"` |
| **Caixa** (104) | `"CAIXA 12345678901234"` | `\d{14,17}` | `"12345678901234"` |
| **Caixa** (104) | `"CEF COB 14000000000000001"` | `\d{14,17}` | `"14000000000000001"` |
| **Santander** (033) | `"SANTANDER COB 1234567"` | `\d{7,17}` (generico) | `"1234567"` |
| **C6** (336) | `"COB C6 0012345678"` | `\d{7,17}` (generico) | `"0012345678"` |

> **Nota:** Os exemplos acima sao padroes TIPICOS. O texto exato do MEMO
> varia conforme a cooperativa (Sicoob), agencia, e tipo de lancamento.
> A API extrai a PRIMEIRA sequencia numerica que bate com o padrao do banco.

### O que o `nosso_numero_extraido` pode conter

| Banco | O que tipicamente aparece | Corresponde a |
|-------|--------------------------|---------------|
| **BB** | convenio + nosso_numero (17 digitos) | `nosso_numero_formatado` da API |
| **Sicoob** | nosso_numero + DV (8 digitos) | `nosso_numero_formatado` da API |
| **Itau** | nosso_numero sem carteira (8 digitos) | `nosso_numero` da API |
| **Bradesco** | nosso_numero sem carteira (11 digitos) | `nosso_numero` da API |
| **Caixa** | carteira + nosso_numero (15-17 digitos) | proximo ao `nosso_numero_formatado` (sem DV) |
| **Santander** | nosso_numero sem DV (7 digitos) | `nosso_numero` da API |
| **C6** | nosso_numero com zeros (10 digitos) | `nosso_numero` da API |

### Conciliacao (OFX → boleto)

Para conciliar, armazene AMBOS os campos ao gerar o boleto:

```python
# Ao gerar o boleto, guarde:
response = requests.get(f"{API}/api/boleto/data", params={...})
data = response.json()

nn_cru = data['nosso_numero']           # "000000123"
nn_fmt = data['nosso_numero_formatado'] # "01234567000000123"
nn_dv  = data['nosso_numero_dv']        # "9"

# Salve todos no seu banco de dados!
```

Para casar com OFX:

```python
nn_ofx = transacao['nosso_numero_extraido']  # "01234567000000123"

# Estrategia 1: comparar com nosso_numero_formatado (mais confiavel)
match = nn_ofx == nn_fmt  # ou strip DV: nn_ofx == nn_fmt.rstrip('-0123456789')

# Estrategia 2: comparar como inteiro (remove zeros)
match = int(nn_ofx) == int(nn_cru) or int(nn_ofx) == int(nn_fmt.replace('/', '').replace('-', ''))

# Estrategia 3: substring (nn cru contido no extraido)
match = nn_cru.lstrip('0') in nn_ofx
```

> **Recomendacao:** Armazene `nosso_numero`, `nosso_numero_formatado` e `nosso_numero_dv`
> ao emitir boletos. Isso facilita a conciliacao com OFX e CNAB.

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
