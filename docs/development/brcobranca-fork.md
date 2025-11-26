# BRCobranca - Informações Técnicas

> Detalhes sobre a gem BRCobranca utilizada neste projeto

## 📦 Gem Utilizada

Este projeto utiliza a gem **[maxwbh/brcobranca](https://github.com/Maxwbh/brcobranca)** para geração de boletos bancários.

## 🔍 Campo `documento_numero`

### Nome Correto na Gem

⚠️ **IMPORTANTE:** O nome correto do campo na gem é `documento_numero` (não `numero_documento`).

```ruby
# ✅ CORRETO - Nome interno na gem
attr_accessor :documento_numero

# ❌ ERRO COMUM - Cliente pode enviar assim
{ "numero_documento": "NF-2025-001" }
```

### Solução Implementada

A API faz **mapeamento automático** para compatibilidade:

```ruby
# lib/boleto_api.rb (linhas 39-47)
if values.key?('numero_documento') && !values.key?('documento_numero')
  BoletoApi.logger.info "🔄 Convertendo 'numero_documento' para 'documento_numero'"
  values['documento_numero'] = values.delete('numero_documento')
elsif values.key?('numero_documento') && values.key?('documento_numero')
  BoletoApi.logger.info "⚠️  Ambos campos enviados. Usando 'documento_numero'"
  values.delete('numero_documento')
end
```

**Benefício:** Clientes podem enviar `numero_documento` e a API converte automaticamente!

## 📋 Campos Disponíveis

### Classe Base

Todos os boletos herdam de `Brcobranca::Boleto::Base` que define:

**Campos Obrigatórios:**
- `agencia` - Agência bancária
- `conta_corrente` - Conta corrente
- `nosso_numero` - Número sequencial do boleto **no banco**
- `cedente` - Nome do beneficiário
- `documento_cedente` - CPF/CNPJ do beneficiário
- `sacado` - Nome do pagador
- `sacado_documento` - CPF/CNPJ do pagador
- `valor` - Valor do boleto
- `data_vencimento` - Data de vencimento

**Campos Opcionais Importantes:**
- `documento_numero` - Número da NF/pedido (controle interno)
- `sacado_endereco` - Endereço do pagador
- `data_documento` - Data de emissão
- `instrucao1` a `instrucao7` - Instruções
- `local_pagamento` - Local de pagamento
- `cedente_endereco` - Endereço do beneficiário
- `avalista` - Nome do avalista
- `avalista_documento` - CPF/CNPJ do avalista

**Campos com Valores Padrão:**
- `moeda` - Padrão: `'9'` (Real)
- `especie` - Padrão: `'R$'`
- `aceite` - Padrão: `'S'` (Sim)
- `especie_documento` - Padrão: `'DM'` (Duplicata Mercantil)
- `quantidade` - Padrão: `1`

## 🏦 Campos Específicos por Banco

### Banco do Brasil (001)

```ruby
class BancoBrasil < Base
  attr_accessor :convenio      # OBRIGATÓRIO (4 a 8 dígitos)
  attr_accessor :carteira      # Padrão: '18'
  attr_accessor :codigo_servico
end
```

**Tamanho do `nosso_numero` varia conforme convênio:**
- Convênio 4 dígitos → nosso_numero máx 7 dígitos
- Convênio 6 dígitos → nosso_numero máx 5 ou 17 dígitos
- Convênio 7 dígitos → nosso_numero máx 10 dígitos
- Convênio 8 dígitos → nosso_numero máx 9 dígitos

### Sicoob (756)

```ruby
class Sicoob < Base
  attr_accessor :convenio     # OBRIGATÓRIO
  attr_accessor :carteira     # Padrão: '1'
  attr_accessor :variacao     # OBRIGATÓRIO (ex: '01')
  attr_accessor :modalidade   # Padrão: '01'
end
```

**Restrições importantes:**
- `aceite` **DEVE** ser `'N'` (não `'S'`)
- `especie_documento` **DEVE** ser enviado (padrão: `'DM'`)

## 🔧 Validações

### Campos Numéricos

Devem ser strings numéricas ou números:
- `convenio`
- `agencia`
- `conta_corrente`
- `nosso_numero`

### Campos de Data

Aceita objetos `Date` ou strings no formato:
- `'YYYY/MM/DD'` (ex: `'2025/12/31'`)
- `'DD/MM/YYYY'` (ex: `'31/12/2025'`)

A API converte automaticamente:

```ruby
# lib/boleto_api.rb (linhas 49-52)
date_fields = %w[data_documento data_vencimento data_processamento]
date_fields.each do |date_field|
  values[date_field] = Date.parse(values[date_field]) if values[date_field]
end
```

## 📊 Métodos Importantes

### Geração de Dados

```ruby
boleto = Brcobranca::Boleto::BancoBrasil.new(dados)

# Validação
boleto.valid?                   # true/false
boleto.errors.messages          # Hash com erros

# Dados calculados
boleto.nosso_numero_boleto      # Nosso número formatado
boleto.nosso_numero_dv          # Dígito verificador
boleto.codigo_barras            # Código de barras completo
boleto.linha_digitavel          # Linha digitável
boleto.agencia_conta_boleto     # Agência/conta formatada
```

### Geração de Arquivos

```ruby
# PDF
boleto.to_pdf

# Imagem
boleto.to_jpg
boleto.to_png
boleto.to_tif

# Lote de boletos
Brcobranca::Boleto::Base.lote(boletos, formato: :pdf)
```

## 🚨 Erros Comuns

### 1. NoMethodError: undefined method `numero_documento=`

**Causa:** Tentar setar `numero_documento` diretamente na gem.

**Solução:** Usar `documento_numero` ou deixar a API converter automaticamente.

### 2. Sicoob com aceite='S'

**Causa:** Sicoob exige `aceite='N'`, não `'S'`.

**Solução:** Sempre enviar `aceite='N'` para Sicoob.

### 3. Campos removidos para Sicoob

**Causa:** Remover `especie_documento` ou `aceite` pensando que são opcionais.

**Solução:** Enviar todos os campos, deixar a gem validar. Não filtrar por banco.

## 📚 Referências

- **Repositório:** [github.com/Maxwbh/brcobranca](https://github.com/Maxwbh/brcobranca)
- **Documentação de Campos:** [docs/fields/README.md](../fields/README.md)
- **Exemplos Práticos:** [docs/fields/examples.md](../fields/examples.md)

## 🔄 Fluxo de Processamento

```
Cliente
  ↓ envia "numero_documento"
API (lib/boleto_api.rb)
  ↓ converte para "documento_numero"
Gem BRCobranca
  ↓ valida e gera
Boleto (PDF/dados)
```

## ✅ Validações na API

A API implementa as seguintes validações antes de chamar a gem:

1. **JSON válido** - Parse de JSON
2. **Mapeamento de campos** - `numero_documento` → `documento_numero`
3. **Conversão de datas** - String → Date
4. **Chamada da gem** - Cria objeto boleto
5. **Validação da gem** - `boleto.valid?`
6. **Geração** - PDF ou dados

---

**Última atualização:** 2025-11-26
**Gem:** maxwbh/brcobranca
