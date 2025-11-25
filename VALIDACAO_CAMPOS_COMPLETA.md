# Validação Completa de Campos - BRCobranca API

## ✅ Status dos Commits

Todos os commits estão corretamente atribuídos a **Maxwell da Silva Oliveira <maxwbh@gmail.com>**

## 📋 Campos Disponíveis na Gem BRCobranca

### Campos da Classe Base (Todos os Bancos Herdam)

#### ✅ Campos Obrigatórios (Base)
```ruby
aceite                  # S ou N (aceite após vencimento)
agencia                 # Número da agência sem DV
carteira                # Tipo de carteira/portfólio
cedente                 # Nome do beneficiário
conta_corrente          # Número da conta sem DV
convenio                # Número do convênio com o banco
data_documento          # Data de emissão do documento
data_vencimento         # Data de vencimento
documento_cedente       # CPF/CNPJ do beneficiário
especie                 # Símbolo da moeda (R$)
especie_documento       # Tipo de documento (DM, NP, etc)
local_pagamento         # Informação do local de pagamento
moeda                   # Código da moeda (9 = Real)
quantidade              # Quantidade de títulos (padrão: 1)
sacado                  # Nome do pagador
sacado_documento        # CPF/CNPJ do pagador
valor                   # Valor do boleto
```

#### 📝 Campos Opcionais (Base)
```ruby
avalista                # Nome do avalista
avalista_documento      # CPF/CNPJ do avalista
carteira_label          # Label da variação da carteira
cedente_endereco        # Endereço do beneficiário
codigo_servico          # Identificador de tipo de serviço
data_processamento      # Data de processamento
demonstrativo           # Informações para o pagador
descontos_e_abatimentos # Descontos e abatimentos
documento_numero        # Número do documento (NF, pedido)
emv                     # EMV para pagamento via QR code PIX
instrucao1              # Instrução 1 para caixa
instrucao2              # Instrução 2 para caixa
instrucao3              # Instrução 3 para caixa
instrucao4              # Instrução 4 para caixa
instrucao5              # Instrução 5 para caixa
instrucao6              # Instrução 6 para caixa
instrucao7              # Instrução 7 para caixa
instrucoes              # Instruções gerais para caixa
nosso_numero            # Número sequencial de identificação
sacado_endereco         # Endereço do pagador
variacao                # Label da carteira para impressão
```

### 🔍 Análise por Banco

#### Campos Específicos por Banco (além dos campos base)

**Banco do Brasil (001):**
- Aceita TODOS os campos da base
- `codigo_servico` - Booleano (padrão: false)
- Não causa erro com campos extras

**Sicoob (756):**
- Aceita TODOS os campos da base
- `variacao` - Modalidade da carteira (padrão: '01')
- **IMPORTANTE:** Segundo BANCO_756_API_FIX.md do fork maxwbh/brcobranca:
  - ❌ NÃO remover `especie_documento`
  - ❌ NÃO remover `aceite` (deve ser 'N' para Sicoob)
  - ✅ Pode remover `documento_numero` se não usado (opcional)

**Bradesco (237):**
- Aceita todos os campos da base
- Calcula automaticamente DVs

**Itaú (341):**
- Aceita todos os campos da base
- `seu_numero` - Para certas carteiras

**Caixa (104):**
- `emissao` - Código de emissão (obrigatório)

**Santander (033):**
- Aceita todos os campos da base

**Sicredi (748):**
- `posto` - Código do posto
- `byte_idt` - Byte de identificação

### 🎯 Estratégia: Enviar Máximo de Informações

#### ✅ ENVIAR SEMPRE (quando disponível):
```ruby
# Dados do beneficiário
cedente
documento_cedente
cedente_endereco        # Novo: adicionar se disponível

# Dados do pagador
sacado
sacado_documento
sacado_endereco         # Importante para compliance

# Dados do avalista (se houver)
avalista
avalista_documento

# Dados do boleto
valor
data_vencimento
data_documento
data_processamento
nosso_numero
documento_numero        # Sempre enviar para rastreabilidade

# Instruções
instrucao1
instrucao2
instrucao3
instrucao4
instrucao5
instrucao6
instrucao7
demonstrativo
descontos_e_abatimentos

# Configurações
aceite
especie
especie_documento
moeda
quantidade
local_pagamento
carteira
convenio
agencia
conta_corrente

# PIX (se suportado)
emv
```

#### ❌ REMOVER APENAS SE:
1. Causa erro de validação específico do banco
2. Campo não existe para aquele banco específico
3. Documentado explicitamente que não deve ser enviado

### 📊 Campos Que Causam Erro (por banco)

#### Sicoob (756) - Segundo análise do fork:
```
⚠️ ATENÇÃO: Informações conflitantes!

Análise anterior (do log do cliente):
- Campos removidos: documento_numero, especie_documento, aceite

Análise BANCO_756_API_FIX.md (fork maxwbh/brcobranca):
- documento_numero: OPCIONAL (pode enviar ou não)
- especie_documento: NÃO REMOVER! (obrigatório)
- aceite: NÃO REMOVER! (deve ser 'N' para Sicoob)

✅ CONCLUSÃO: Enviar TODOS os campos, inclusive:
- especie_documento: 'DM'
- aceite: 'N' (específico para Sicoob)
- documento_numero: enviar se disponível
```

#### Banco do Brasil (001):
```
✅ Aceita todos os campos da base
✅ Nenhum campo causa erro
```

#### Demais Bancos:
```
✅ Em geral, aceita todos os campos da base
✅ Campos extras são ignorados se não aplicáveis
```

### 🔧 Recomendações para API

#### 1. Não Filtrar Campos por Banco
```python
# ❌ ERRADO - não fazer filtro específico:
if bank == '756':  # Sicoob
    campos_removidos = ['documento_numero', 'especie_documento', 'aceite']

# ✅ CORRETO - enviar tudo:
# Enviar todos os campos que o cliente forneceu
# Deixar a gem BRCobranca validar
```

#### 2. Apenas Garantir Valores Padrão Corretos
```python
# ✅ CORRETO - ajustar valores específicos:
if bank == '756':  # Sicoob
    if 'aceite' not in boleto_data:
        boleto_data['aceite'] = 'N'  # Padrão Sicoob
    if 'especie_documento' not in boleto_data:
        boleto_data['especie_documento'] = 'DM'
```

#### 3. Enviar Máximo de Campos Possíveis
```python
# Lista completa de campos a enviar (quando disponíveis):
campos_completos = [
    # Obrigatórios
    'aceite', 'agencia', 'carteira', 'cedente', 'conta_corrente',
    'convenio', 'data_documento', 'data_vencimento', 'documento_cedente',
    'especie', 'especie_documento', 'local_pagamento', 'moeda',
    'quantidade', 'sacado', 'sacado_documento', 'valor', 'nosso_numero',

    # Opcionais - enviar quando disponível
    'avalista', 'avalista_documento', 'carteira_label',
    'cedente_endereco', 'codigo_servico', 'data_processamento',
    'demonstrativo', 'descontos_e_abatimentos', 'documento_numero',
    'emv', 'instrucao1', 'instrucao2', 'instrucao3', 'instrucao4',
    'instrucao5', 'instrucao6', 'instrucao7', 'instrucoes',
    'sacado_endereco', 'variacao',

    # Específicos por banco
    'emissao',  # Caixa
    'posto', 'byte_idt',  # Sicredi
    'seu_numero',  # Itaú
    'digito_convenio',  # Banrisul
    'digito_conta_corrente',  # Banco do Nordeste, Banestes
    'nosso_numero_incremento',  # BRB
    'portfolio',  # Citibank
]
```

## 📝 Próximos Passos

1. ✅ Analisar código atual que está filtrando campos
2. ✅ Remover filtros desnecessários
3. ✅ Garantir que enviamos máximo de informações
4. ✅ Documentar campos por banco completamente
5. ✅ Testar com Sicoob e BB
6. ✅ Validar que não há erros

---

**Data da Validação:** 2025-11-25
**Validado por:** Maxwell da Silva Oliveira
