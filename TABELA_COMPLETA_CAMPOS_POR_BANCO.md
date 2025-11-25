# Tabela Completa de Campos por Banco - BRCobranca

## 📋 Legenda

- ✅ = Campo aceito e recomendado enviar
- ⚠️ = Campo aceito mas com restrições
- ❌ = Campo NÃO deve ser enviado (causa erro)
- 🔒 = Campo OBRIGATÓRIO
- 📝 = Campo OPCIONAL mas RECOMENDADO
- ⏭️ = Campo OPCIONAL (pode omitir)

---

## 🏦 Banco do Brasil (001)

### Campos Obrigatórios 🔒
| Campo | Tipo | Validação | Padrão | Notas |
|-------|------|-----------|--------|-------|
| `agencia` | String | máx 4 dígitos | - | Preenchido com zeros à esquerda |
| `conta_corrente` | String | máx 8 dígitos | - | Preenchido com zeros à esquerda |
| `carteira` | String | máx 2 dígitos | '18' | '16', '17', '18' |
| `convenio` | String | 4 a 8 dígitos | - | **OBRIGATÓRIO** |
| `nosso_numero` | String | variável* | - | Tamanho depende do convênio |
| `cedente` | String | - | - | Nome do beneficiário |
| `documento_cedente` | String | - | - | CPF/CNPJ sem formatação |
| `sacado` | String | - | - | Nome do pagador |
| `sacado_documento` | String | - | - | CPF/CNPJ sem formatação |
| `valor` | Decimal | - | 0.0 | Valor do boleto |
| `data_vencimento` | Date | - | hoje | Formato: Date ou 'YYYY/MM/DD' |

*Tamanho do `nosso_numero` depende do convênio:
- Convênio 4 dígitos → nosso_numero máx 7 dígitos
- Convênio 6 dígitos (sem codigo_servico) → nosso_numero máx 5 dígitos
- Convênio 6 dígitos (com codigo_servico) → nosso_numero máx 17 dígitos
- Convênio 7 dígitos → nosso_numero máx 10 dígitos
- Convênio 8 dígitos → nosso_numero máx 9 dígitos

### Campos Opcionais Recomendados 📝
| Campo | Status | Notas |
|-------|--------|-------|
| `documento_numero` | ✅ | Número da NF/pedido - **SEM LIMITE DE TAMANHO** |
| `sacado_endereco` | ✅ | Endereço do pagador |
| `data_documento` | ✅ | Data de emissão |
| `data_processamento` | ✅ | Data de processamento |
| `instrucao1` a `instrucao7` | ✅ | Instruções para o caixa |
| `avalista` | ✅ | Nome do avalista (se houver) |
| `avalista_documento` | ✅ | CPF/CNPJ do avalista |
| `cedente_endereco` | ✅ | Endereço do beneficiário |
| `demonstrativo` | ✅ | Informações para o pagador |
| `descontos_e_abatimentos` | ✅ | Descontos |

### Campos Opcionais Podem Omitir ⏭️
| Campo | Status | Padrão | Notas |
|-------|--------|--------|-------|
| `codigo_servico` | ✅ | false | Booleano |
| `aceite` | ✅ | 'S' | 'S' ou 'N' |
| `especie_documento` | ✅ | 'DM' | Tipo do documento |
| `especie` | ✅ | 'R$' | Símbolo da moeda |
| `moeda` | ✅ | '9' | Código da moeda |
| `quantidade` | ✅ | 1 | Quantidade |
| `local_pagamento` | ✅ | 'PAGÁVEL EM QUALQUER BANCO.' | Local de pagamento |

### Campos Calculados Automaticamente
- `banco_dv` - Dígito verificador do banco
- `agencia_dv` - Dígito verificador da agência
- `conta_corrente_dv` - Dígito verificador da conta
- `nosso_numero_dv` - Dígito verificador do nosso número
- `codigo_barras` - Código de barras completo
- `linha_digitavel` - Linha digitável

---

## 🏦 Sicoob (756)

### ⚠️ IMPORTANTE - Configurações Específicas do Sicoob
```ruby
# Valores padrão CORRETOS para Sicoob:
aceite: 'N'              # SICOOB usa 'N' (diferente de outros bancos!)
especie_documento: 'DM'  # Duplicata Mercantil
carteira: '1'            # Carteira padrão
variacao: '01'           # Modalidade da carteira
```

### Campos Obrigatórios 🔒
| Campo | Tipo | Validação | Padrão | Notas |
|-------|------|-----------|--------|-------|
| `agencia` | String | máx 4 dígitos | - | Preenchido com zeros à esquerda |
| `conta_corrente` | String | máx 8 dígitos | - | Preenchido com zeros à esquerda |
| `carteira` | String | 1 dígito | '1' | Geralmente '1' |
| `variacao` | String | máx 2 dígitos | '01' | Modalidade da carteira |
| `convenio` | String | máx 7 dígitos | - | **OBRIGATÓRIO** |
| `nosso_numero` | String | máx 7 dígitos | - | Preenchido com zeros |
| `cedente` | String | - | - | Nome do beneficiário |
| `documento_cedente` | String | - | - | CPF/CNPJ sem formatação |
| `sacado` | String | - | - | Nome do pagador |
| `sacado_documento` | String | - | - | CPF/CNPJ sem formatação |
| `valor` | Decimal | - | 0.0 | Valor do boleto |
| `data_vencimento` | Date | - | hoje | Formato: Date ou 'YYYY/MM/DD' |

### Campos Obrigatórios NÃO REMOVER! ⚠️
| Campo | Status | Valor Padrão | **MOTIVO** |
|-------|--------|--------------|------------|
| `aceite` | 🔒 **OBRIGATÓRIO** | `'N'` | **Sicoob requer 'N'** (não 'S'!) |
| `especie_documento` | 🔒 **OBRIGATÓRIO** | `'DM'` | **Necessário para geração** |

### Campos Opcionais Recomendados 📝
| Campo | Status | Notas |
|-------|--------|-------|
| `documento_numero` | ✅ | **ACEITO PELO SICOOB** - Número da NF/contrato |
| `sacado_endereco` | ✅ | Endereço do pagador |
| `data_documento` | ✅ | Data de emissão |
| `data_processamento` | ✅ | Data de processamento |
| `instrucao1` a `instrucao7` | ✅ | Instruções para o caixa |
| `avalista` | ✅ | Nome do avalista (se houver) |
| `avalista_documento` | ✅ | CPF/CNPJ do avalista |
| `cedente_endereco` | ✅ | Endereço do beneficiário |
| `demonstrativo` | ✅ | Informações para o pagador |
| `descontos_e_abatimentos` | ✅ | Descontos |

### Campos Opcionais Podem Omitir ⏭️
| Campo | Status | Padrão | Notas |
|-------|--------|--------|-------|
| `especie` | ✅ | 'R$' | Símbolo da moeda |
| `moeda` | ✅ | '9' | Código da moeda |
| `quantidade` | ✅ | '001' | Quantidade (3 dígitos) |
| `local_pagamento` | ✅ | 'QUALQUER BANCO ATÉ O VENCIMENTO' | Local |

### Campos Calculados Automaticamente
- `nosso_numero_dv` - Dígito verificador (módulo 11 com multiplicadores [3,1,9,7])
- `nosso_numero_boleto` - Concatenação do nosso_numero com DV
- `agencia_conta_boleto` - Formato: agencia / convenio
- `codigo_barras` - Código de barras completo
- `codigo_barras_segunda_parte` - Segunda parte do código
- `linha_digitavel` - Linha digitável

---

## 🔴 ERRO COMUM - Campo `documento_numero`

### ❌ Log do Cliente Mostrando Remoção Incorreta:
```
INFO 2025-11-24 22:56:42,974 boleto_service Campos filtrados para banco 756:
removidos=['documento_numero', 'especie_documento', 'aceite']
```

### ✅ Correção Necessária no Sistema do Cliente:

```python
# ❌ CÓDIGO ERRADO (NÃO FAZER):
if banco == '756':  # Sicoob
    # NUNCA remover estes campos!
    campos_removidos = ['documento_numero', 'especie_documento', 'aceite']
    for campo in campos_removidos:
        boleto_data.pop(campo, None)

# ✅ CÓDIGO CORRETO:
if banco == '756':  # Sicoob
    # Apenas garantir valores padrão corretos
    if 'aceite' not in boleto_data:
        boleto_data['aceite'] = 'N'  # Sicoob usa 'N'!

    if 'especie_documento' not in boleto_data:
        boleto_data['especie_documento'] = 'DM'

    # documento_numero é OPCIONAL - pode enviar!
    # Se tiver, enviar. Se não tiver, não tem problema.
```

---

## 📊 Resumo de Campos por Categoria

### Campos da Classe Base (Todos os Bancos)

#### Dados do Beneficiário
```ruby
cedente               # Nome
documento_cedente     # CPF/CNPJ
cedente_endereco      # Endereço (opcional)
```

#### Dados do Pagador
```ruby
sacado                # Nome
sacado_documento      # CPF/CNPJ
sacado_endereco       # Endereço (opcional mas recomendado)
```

#### Dados do Avalista
```ruby
avalista              # Nome (opcional)
avalista_documento    # CPF/CNPJ (opcional)
```

#### Dados Bancários
```ruby
agencia               # Agência
conta_corrente        # Conta
carteira              # Carteira
convenio              # Convênio (obrigatório)
variacao              # Variação (Sicoob)
codigo_servico        # Serviço (BB)
```

#### Dados do Boleto
```ruby
nosso_numero          # Identificação (obrigatório)
documento_numero      # NF/Pedido (opcional mas RECOMENDADO)
valor                 # Valor
data_vencimento       # Vencimento
data_documento        # Emissão
data_processamento    # Processamento
```

#### Configurações
```ruby
aceite                # 'S' ou 'N' (Sicoob usa 'N')
especie               # 'R$'
especie_documento     # 'DM', 'NP', etc
moeda                 # '9' = Real
quantidade            # Quantidade de títulos
local_pagamento       # Local de pagamento
```

#### Instruções e Informações
```ruby
instrucao1 a instrucao7    # Instruções para o caixa
demonstrativo              # Informações para o pagador
descontos_e_abatimentos   # Descontos e abatimentos
instrucoes                 # Instruções gerais
```

#### Tecnologia
```ruby
emv                   # PIX QR Code (opcional, se suportado)
```

---

## 🎯 Recomendações Finais

### ✅ O Que FAZER:
1. **Enviar TODOS os campos disponíveis**
2. **Usar valores padrão corretos por banco**
3. **Deixar a gem BRCobranca validar**
4. **Não filtrar campos por banco**

### ❌ O Que NÃO FAZER:
1. **NÃO remover campos por banco**
2. **NÃO assumir que campos opcionais causam erro**
3. **NÃO remover `especie_documento`** para nenhum banco
4. **NÃO remover `aceite`** para nenhum banco
5. **NÃO remover `documento_numero`** (é sempre opcional)

### 📝 Padrão Específico por Banco:
```python
# Configurar valores padrão específicos:
defaults_por_banco = {
    '001': {  # Banco do Brasil
        'aceite': 'S',
        'carteira': '18',
        'local_pagamento': 'PAGÁVEL EM QUALQUER BANCO.',
    },
    '756': {  # Sicoob
        'aceite': 'N',  # IMPORTANTE: Sicoob usa 'N'!
        'carteira': '1',
        'variacao': '01',
        'quantidade': '001',
        'local_pagamento': 'QUALQUER BANCO ATÉ O VENCIMENTO',
    }
}

# Aplicar padrões (NÃO remover campos!):
for campo, valor in defaults_por_banco.get(codigo_banco, {}).items():
    if campo not in boleto_data:
        boleto_data[campo] = valor
```

---

## 📚 Referências

- [BRCobranca - Brcobranca::Boleto::Base](https://www.rubydoc.info/gems/brcobranca/Brcobranca/Boleto/Base)
- [BRCobranca - Sicoob Class](https://www.rubydoc.info/github/kivanio/brcobranca/Brcobranca/Boleto/Sicoob)
- [BRCobranca - BancoBrasil Class](https://www.rubydoc.info/gems/brcobranca/Brcobranca/Boleto/BancoBrasil)
- [Fork maxwbh/brcobranca](https://github.com/maxwbh/brcobranca)
- [BANCO_756_API_FIX.md](https://github.com/maxwbh/brcobranca/blob/master/BANCO_756_API_FIX.md)

---

**Documentação Criada:** 2025-11-25
**Mantido por:** Maxwell da Silva Oliveira (@maxwbh)
**Empresa:** M&S do Brasil Ltda
