# Guia de Campos para Boletos - BRCobranca

> 📚 Documentação completa dos campos aceitos por cada banco

## 📋 Índice

- [Campos Comuns](#campos-comuns)
- [Banco do Brasil (001)](#banco-do-brasil-001)
- [Sicoob (756)](#sicoob-756)
- [Diferenças Importantes](#diferenças-importantes)

## 🎯 Legenda

- 🔒 = Campo **OBRIGATÓRIO**
- 📝 = Campo **RECOMENDADO** (opcional mas importante)
- ⏭️ = Campo **OPCIONAL** (pode omitir)
- ⚠️ = Campo com **RESTRIÇÕES** ou validações especiais
- ❌ = Campo que **NÃO** deve ser enviado

---

## Campos Comuns

Todos os bancos herdam da classe `Brcobranca::Boleto::Base` e compartilham campos básicos.

### Obrigatórios 🔒

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `agencia` | String | Código da agência bancária |
| `conta_corrente` | String | Número da conta corrente |
| `nosso_numero` | String | Número sequencial do boleto **no banco** |
| `cedente` | String | Nome do beneficiário (emissor) |
| `documento_cedente` | String | CPF/CNPJ do beneficiário |
| `sacado` | String | Nome do pagador |
| `sacado_documento` | String | CPF/CNPJ do pagador |
| `valor` | Decimal | Valor do boleto |
| `data_vencimento` | Date/String | Data de vencimento |

### Recomendados 📝

| Campo | Descrição | Benefício |
|-------|-----------|-----------|
| `documento_numero` | Número da NF/pedido/contrato | Rastreabilidade e controle interno |
| `sacado_endereco` | Endereço completo do pagador | Compliance e localização |
| `data_documento` | Data de emissão | Controle temporal |
| `instrucao1` a `instrucao7` | Instruções para o caixa/pagador | Comunicação clara |
| `local_pagamento` | Local de pagamento | Informação ao pagador |
| `cedente_endereco` | Endereço do beneficiário | Contato e compliance |

### Opcionais ⏭️

| Campo | Valor Padrão | Notas |
|-------|--------------|-------|
| `moeda` | `'9'` | Código da moeda (9 = Real) |
| `especie` | `'R$'` | Símbolo da moeda |
| `aceite` | `'S'` | 'S' = aceite, 'N' = sem aceite |
| `especie_documento` | `'DM'` | DM, DS, NP, RC, etc. |
| `data_processamento` | hoje | Data de processamento |
| `quantidade` | `1` | Quantidade |
| `avalista` | - | Nome do avalista |
| `avalista_documento` | - | CPF/CNPJ do avalista |

---

## Banco do Brasil (001)

### Campos Específicos 🔒

| Campo | Tipo | Validação | Notas |
|-------|------|-----------|-------|
| `convenio` | String | 4 a 8 dígitos | **OBRIGATÓRIO** |
| `carteira` | String | 2 dígitos | Padrão: `'18'` |

### Tamanho do `nosso_numero` ⚠️

O tamanho máximo depende do convênio:

- Convênio 4 dígitos → nosso_numero máx **7 dígitos**
- Convênio 6 dígitos (sem codigo_servico) → nosso_numero máx **5 dígitos**
- Convênio 6 dígitos (com codigo_servico) → nosso_numero máx **17 dígitos**
- Convênio 7 dígitos → nosso_numero máx **10 dígitos**
- Convênio 8 dígitos → nosso_numero máx **9 dígitos**

### Campos Aceitos ✅

O Banco do Brasil **aceita TODOS** os campos da classe Base sem restrições especiais.

- ✅ `documento_numero` - **SEM LIMITE DE TAMANHO**
- ✅ `aceite` - Aceita 'S' ou 'N'
- ✅ `especie_documento` - Aceita qualquer valor válido

### Exemplo Completo

```json
{
  "agencia": "3073",
  "conta_corrente": "12345678",
  "convenio": "01234567",
  "carteira": "18",
  "nosso_numero": "7",
  "documento_numero": "CTR-2023-0012-017/017",
  "cedente": "Imobiliária Exemplo LTDA",
  "documento_cedente": "12345678000100",
  "sacado": "João da Silva",
  "sacado_documento": "12345678900",
  "sacado_endereco": "Rua Exemplo, 100, Centro, Cidade, UF, CEP 12345000",
  "valor": 1500.00,
  "data_vencimento": "2025/12/31",
  "data_documento": "2025/11/26",
  "aceite": "N",
  "especie_documento": "DM",
  "local_pagamento": "Pagavel em qualquer banco ate o vencimento",
  "instrucao1": "Não receber após o vencimento",
  "instrucao2": "Após vencimento cobrar multa de 2%",
  "cedente_endereco": "Av. Principal, 200"
}
```

---

## Sicoob (756)

### Campos Específicos 🔒

| Campo | Tipo | Validação | Valor |
|-------|------|-----------|-------|
| `convenio` | String | numérico | Código do convênio/beneficiário |
| `carteira` | String | 2 dígitos | Padrão: `'1'` |
| `variacao` | String | 2 dígitos | **OBRIGATÓRIO** - Ex: `'01'` |
| `modalidade` | String | 2 dígitos | Padrão: `'01'` |

### ⚠️ ATENÇÃO: Campos com Restrições

| Campo | Valor Correto | ❌ Valor Errado | Motivo |
|-------|---------------|-----------------|--------|
| `aceite` | `'N'` | `'S'` | Sicoob **EXIGE** `'N'` |
| `especie_documento` | `'DM'` | omitir | **OBRIGATÓRIO** enviar |

### Campos Aceitos ✅

- ✅ `documento_numero` - Aceito e recomendado
- ✅ Todos os campos de endereço
- ✅ Instruções (instrucao1 a instrucao7)
- ✅ Campos de avalista

### ❌ Erro Comum

**NÃO** remova os campos `aceite` e `especie_documento` para Sicoob!

```python
# ❌ ERRADO - Filtrando campos
campos_removidos = ['documento_numero', 'especie_documento', 'aceite']

# ✅ CORRETO - Enviando com valores corretos
boleto_sicoob = {
    "aceite": "N",  # DEVE ser 'N' para Sicoob
    "especie_documento": "DM",  # DEVE enviar
    "documento_numero": "NF-2023-001",  # PODE e DEVE enviar
    # ... outros campos
}
```

### Exemplo Completo

```json
{
  "agencia": "4327",
  "conta_corrente": "417270",
  "convenio": "229385",
  "carteira": "1",
  "variacao": "01",
  "modalidade": "01",
  "nosso_numero": "1234567",
  "documento_numero": "NF-2025-001234",
  "aceite": "N",
  "especie_documento": "DM",
  "cedente": "Cooperativa Exemplo",
  "documento_cedente": "12345678000100",
  "sacado": "Maria dos Santos",
  "sacado_documento": "98765432100",
  "sacado_endereco": "Rua da Cooperativa, 50, Bairro, Cidade, UF, CEP 54321000",
  "valor": 2500.00,
  "data_vencimento": "2025/12/31",
  "data_documento": "2025/11/26",
  "local_pagamento": "Pagavel em qualquer banco ate o vencimento",
  "instrucao1": "Não receber após 30 dias",
  "cedente_endereco": "Av. Cooperativa, 100"
}
```

---

## Diferenças Importantes

### `nosso_numero` vs `documento_numero`

| Campo | Propósito | Obrigatoriedade | Aparece em |
|-------|-----------|-----------------|------------|
| `nosso_numero` | Identificação **BANCÁRIA** do boleto | 🔒 **OBRIGATÓRIO** | Código de barras, linha digitável |
| `documento_numero` | Identificação **INTERNA** (NF, pedido) | 📝 **RECOMENDADO** | Apenas no PDF impresso |

**Importante:**
- `documento_numero` **NÃO** afeta o código de barras ou linha digitável
- `documento_numero` é usado apenas para rastreamento e controle interno
- `nosso_numero` **DEVE** ser sequencial e único por convênio

### `numero_documento` vs `documento_numero`

⚠️ **Atenção ao nome do campo!**

- **Na API/Cliente:** Use `numero_documento` (compatibilidade)
- **Na gem BRCobranca:** Internamente é `documento_numero`
- **Solução:** A API faz mapeamento automático

```ruby
# A API converte automaticamente:
"numero_documento" → "documento_numero" (nome correto na gem)
```

### Estratégia Recomendada 💡

**Envie o MÁXIMO de campos possíveis!**

1. ✅ Envie `documento_numero` sempre que disponível
2. ✅ Envie endereços completos (cedente e sacado)
3. ✅ Envie instruções claras
4. ✅ Envie datas (documento e processamento)
5. ❌ **NÃO** filtre campos por banco - deixe a gem validar

**Benefícios:**
- Melhor rastreabilidade
- Compliance com regulamentações
- Comunicação clara com pagador
- Facilita conciliação bancária
- Melhor experiência do usuário

---

## 📚 Documentação Adicional

- [Exemplos Práticos](./examples.md) - Exemplos de código Python/Ruby
- [Troubleshooting](../api/troubleshooting.md) - Solução de problemas
- [Detalhes Técnicos](../development/brcobranca-fork.md) - Informações sobre BRCobranca

---

**Última atualização:** 2025-11-26
**Gem:** [maxwbh/brcobranca](https://github.com/Maxwbh/brcobranca)
