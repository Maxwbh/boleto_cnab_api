# Documentação de Campos para Geração de Boletos - BRCobranca

Esta documentação detalha os campos necessários para geração de boletos para cada banco suportado pela gem BRCobranca.

## Campos Comuns a Todos os Bancos

Todos os bancos herdam da classe `Base` e possuem os seguintes campos:

### Campos Obrigatórios (Base)
- `agencia` - Código da agência bancária
- `conta_corrente` - Número da conta corrente
- `moeda` - Código da moeda (padrão: '9' para Real)
- `especie_documento` - Tipo do documento (padrão: 'DM' - Duplicata Mercantil)
- `especie` - Símbolo da moeda (padrão: 'R$')
- `aceite` - Indica se há aceite (padrão: 'S' - Sim)
- `nosso_numero` - Número sequencial do documento
- `sacado` - Nome do pagador
- `sacado_documento` - CPF/CNPJ do pagador

### Campos Opcionais Comuns
- `cedente` - Nome do beneficiário
- `documento_cedente` - CPF/CNPJ do beneficiário
- `valor` - Valor do boleto (padrão: 0.0)
- `data_vencimento` - Data de vencimento (padrão: data atual)
- `data_processamento` - Data de processamento (padrão: data atual)
- `data_documento` - Data de emissão do documento
- `quantidade` - Quantidade (padrão: 1)
- `local_pagamento` - Local de pagamento (cada banco tem seu padrão)
- `instrucoes1` a `instrucoes7` - Instruções adicionais
- `sacado_endereco` - Endereço do pagador
- `avalista` - Nome do avalista
- `avalista_documento` - CPF/CNPJ do avalista

### Validações Numéricas
Os campos `convenio`, `agencia`, `conta_corrente` e `nosso_numero` devem ser numéricos (podem ser strings numéricas).

---

## 1. Banco do Brasil (001)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `convenio` - Número do convênio (4 a 8 dígitos)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 8 dígitos (preenchido com zeros à esquerda)
- `carteira`: máximo 2 dígitos (preenchido com zeros à esquerda)
- `convenio`: entre 4 e 8 dígitos
- `nosso_numero`: tamanho variável conforme convênio:
  - Convênio 8 dígitos → máximo 9 dígitos
  - Convênio 7 dígitos → máximo 10 dígitos
  - Convênio 6 dígitos sem `codigo_servico` → máximo 5 dígitos
  - Convênio 6 dígitos com `codigo_servico` → máximo 17 dígitos
  - Convênio 4 dígitos → máximo 7 dígitos

### Campos Específicos
- `codigo_servico` - Booleano (padrão: false) - Indica se usa código de serviço

### Valores Padrão
- `carteira`: '18'
- `codigo_servico`: false
- `local_pagamento`: 'PAGÁVEL EM QUALQUER BANCO.'

### Exemplos de Valores Válidos
```ruby
agencia: '4042'
conta_corrente: '61900'  # será formatado para '00061900'
carteira: '18'  # ou '16', '17'
convenio: '12387989'  # 8 dígitos
convenio: '1238798'   # 7 dígitos
convenio: '123879'    # 6 dígitos
convenio: 1238        # 4 dígitos
nosso_numero: '777700168'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie: 'R$'
moeda: '9'
```

---

## 2. Bradesco (237)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 7 dígitos (preenchido com zeros à esquerda)
- `carteira`: máximo 2 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 11 dígitos (preenchido com zeros à esquerda)

### Valores Padrão
- `carteira`: '06'
- `local_pagamento`: 'Pagável preferencialmente na Rede Bradesco ou Bradesco Expresso'

### Campos Calculados Automaticamente
- `agencia_dv` - Dígito verificador da agência
- `nosso_numero_dv` - Dígito verificador do nosso número
- `conta_corrente_dv` - Dígito verificador da conta

### Exemplos de Valores Válidos
```ruby
agencia: '4042'
conta_corrente: '61900'
carteira: '06'  # ou '03', '09', '19'
nosso_numero: '777700168'
nosso_numero: '75896452'
nosso_numero: '00000000525'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
convenio: 12387989
especie_documento: 'DM'
moeda: '9'
aceite: 'S'
```

---

## 3. Itaú (341)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 5 dígitos (preenchido com zeros à esquerda)
- `convenio`: máximo 5 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 8 dígitos (preenchido com zeros à esquerda)
- `carteira`: máximo 3 dígitos
- `seu_numero`: máximo 7 dígitos (condicional)

### Validação Condicional
- `seu_numero`: validado apenas quando `usa_seu_numero?` retorna verdadeiro
  - Carteiras que usam: 198, 106, 107, 122, 142, 143, 195, 196

### Valores Padrão
- `carteira`: '175'
- `local_pagamento`: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### Exemplos de Valores Válidos
```ruby
agencia: '0810'
conta_corrente: '53678'  # será formatado para '53678'
carteira: '175'  # ou '198', '109', '168', '196', '143'
nosso_numero: '12345678'
nosso_numero: '258281'  # será formatado para '00258281'
convenio: 12387
convenio: '12345'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie_documento: 'DM'
especie: 'R$'
moeda: '9'
aceite: 'S'
```

---

## 4. Caixa Econômica Federal (104)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `emissao` - Código de emissão (exatamente 1 dígito)

### Validações de Tamanho
- `carteira`: exatamente 1 dígito
- `emissao`: exatamente 1 dígito
- `convenio`: exatamente 6 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: exatamente 15 dígitos (preenchido com zeros à esquerda)

### Campos Específicos
- `emissao` - Código de emissão do boleto

### Valores Padrão
- `carteira`: '1'
- `carteira_label`: 'RG'
- `emissao`: '4'
- `local_pagamento`: 'PREFERENCIALMENTE NAS CASAS LOTÉRICAS ATÉ O VALOR LIMITE'

### Exemplos de Valores Válidos
```ruby
agencia: '1825'
conta_corrente: '0000528'
carteira: '1'
emissao: '4'
convenio: '245274'  # será formatado para '245274'
nosso_numero: '000000000000001'  # 15 dígitos
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie_documento: 'DM'
especie: 'R$'
valor: 10.00
```

---

## 5. Santander (033)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `convenio` - Número do convênio (obrigatório)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: 9 dígitos (preenchido com zeros à esquerda)
- `convenio`: máximo 7 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 7 dígitos (preenchido com zeros à esquerda)

### Valores Padrão
- `carteira`: '102'
- `local_pagamento`: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### Campos Calculados
- `nosso_numero_dv` - Dígito verificador (algoritmo módulo 11)
- `nosso_numero_boleto` - Formato: "9000272-7"
- `agencia_conta_boleto` - Formatação agência/convênio

### Exemplos de Valores Válidos
```ruby
agencia: '0059'
conta_corrente: '013000123'
carteira: '102'
convenio: 1899775
nosso_numero: '9000026'
nosso_numero: '9000272'
nosso_numero: '566612457800'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie_documento: 'DM'
moeda: '9'
aceite: 'S'
```

---

## 6. Sicredi (748)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `posto` - Código do posto da cooperativa de crédito (máximo 2 dígitos)
- `byte_idt` - Byte de identificação do cedente (exatamente 1 caractere)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 5 dígitos
- `carteira`: máximo 1 dígito
- `nosso_numero`: máximo 5 dígitos (preenchido com zeros à esquerda)
- `posto`: máximo 2 dígitos
- `byte_idt`: exatamente 1 caractere
- `convenio`: máximo 5 dígitos (preenchido com zeros à esquerda)

### Campos Específicos
- `posto` - Código do posto da cooperativa
- `byte_idt` - Deve ser '1' se gerado pela agência ou '2-9' se gerado pelo beneficiário

### Valores Padrão
- `carteira`: '3' (Sem Registro)
- `especie_documento`: 'A'
- `banco_dv`: 'X'

### Exemplos de Valores Válidos
```ruby
agencia: '0710'
conta_corrente: '61900'
carteira: '1'  # ou '3'
byte_idt: '2'
posto: '65'
convenio: '129'  # será formatado para '00129'
nosso_numero: '8879'  # será formatado para '08879'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
```

**Formato do Nosso Número no Boleto**: `AA/BXXXXX-D` (ex: `16/208879-3`)

**Formato Agência/Conta no Boleto**: `0710.65.00129`

---

## 7. Sicoob (756)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos (preenchido com zeros à esquerda)
- `conta_corrente`: máximo 8 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 7 dígitos (preenchido com zeros à esquerda)
- `convenio`: máximo 7 dígitos (preenchido com zeros à esquerda)
- `variacao`: máximo 2 dígitos
- `quantidade`: máximo 3 dígitos (preenchido com zeros à esquerda)

### Campos Específicos
- `variacao` - Modalidade da carteira (padrão: '01')
- `quantidade` - Quantidade (padrão: '001')

### Valores Padrão
- `carteira`: '1'
- `variacao`: '01'
- `quantidade`: '001'
- `local_pagamento`: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### Campos Calculados
- `nosso_numero_dv` - Dígito verificador (módulo 11 com multiplicadores [3, 1, 9, 7])
- `nosso_numero_boleto` - Concatenação do nosso_numero com DV

### Exemplos de Valores Válidos
```ruby
agencia: '4327'
conta_corrente: '417270'
carteira: '1'
variacao: '01'  # ou '05'
convenio: '229385'  # será formatado para '0229385'
nosso_numero: '1'  # será formatado para '0000001'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
moeda: '9'
```

---

## 8. HSBC (399)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- Para carteira CNR: `data_vencimento` deve ser um objeto Date

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 7 dígitos
- `nosso_numero`: máximo 13 dígitos (preenchido com zeros à esquerda)

### Validações Específicas
- `carteira`: deve estar em ['CNR', 'CSB']
- Carteira CNR requer `data_vencimento` como objeto Date
- Carteira CSB requer que `nosso_numero` seja definido

### Campos Específicos
- `codigo_servico` - Atribuído dinamicamente ('4' para CNR)

### Valores Padrão
- `carteira`: 'CNR'
- `local_pagamento`: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### Exemplos de Valores Válidos
```ruby
agencia: '4042'
conta_corrente: '61900'
carteira: 'CNR'  # único valor usado nos testes
nosso_numero: '777700168'
nosso_numero: '12345678'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
convenio: 12387989
especie_documento: 'DM'
moeda: '9'
data_vencimento: Date.parse('2009-04-08')
```

---

## 9. Banrisul (041)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `digito_convenio` - Dígito verificador do convênio (máximo 2 dígitos)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos (preenchido com zeros à esquerda)
- `conta_corrente`: máximo 8 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 8 dígitos (preenchido com zeros à esquerda)
- `carteira`: máximo 1 dígito
- `convenio`: máximo 7 dígitos (preenchido com zeros à esquerda)
- `digito_convenio`: máximo 2 dígitos

### Campos Específicos
- `digito_convenio` - Dígito verificador do convênio (obrigatório)

### Valores Padrão
- `carteira`: '2'
- `local_pagamento`: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### Exemplos de Valores Válidos
```ruby
agencia: '1102'
conta_corrente: '1454204'  # será formatado para '01454204'
carteira: '2'
convenio: '9000150'
digito_convenio: '46'
nosso_numero: '22832563'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie: 'R$'
moeda: '9'
```

**Formato do Nosso Número no Boleto**: `XXXXXXXX-DV`

---

## 10. Banco do Nordeste (004)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `digito_conta_corrente` - Dígito verificador da conta (exatamente 1 dígito)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 7 dígitos (preenchido com zeros à esquerda)
- `digito_conta_corrente`: exatamente 1 dígito
- `carteira`: máximo 2 dígitos
- `nosso_numero`: máximo 7 dígitos (preenchido com zeros à esquerda)

### Campos Específicos
- `digito_conta_corrente` - Dígito verificador da conta corrente

### Valores Padrão
- `carteira`: '21'
- `local_pagamento`: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### Campos Calculados
- `nosso_numero_dv` - Calculado via módulo 11 com multiplicadores de 2 a 8

### Exemplos de Valores Válidos
```ruby
agencia: '0016'
conta_corrente: '0001193'
digito_conta_corrente: '2'
carteira: '21'
nosso_numero: '0000053'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie_documento: 'DM'
especie: 'R$'
moeda: '9'
aceite: 'S'
```

---

## 11. Banestes (021)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `digito_conta_corrente` - Dígito verificador da conta (exatamente 1 dígito)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos (preenchido com zeros à esquerda)
- `conta_corrente`: máximo 10 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 8 dígitos (preenchido com zeros à esquerda)
- `variacao`: máximo 1 dígito
- `carteira`: máximo 2 dígitos
- `digito_conta_corrente`: exatamente 1 dígito

### Campos Específicos
- `digito_conta_corrente` - Dígito verificador da conta
- `variacao` - Variação da conta (padrão: '2')

### Valores Padrão
- `carteira`: '11'
- `variacao`: '2'
- `local_pagamento`: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### Campos Calculados
- Dígitos verificadores via módulo 11

### Exemplos de Valores Válidos
```ruby
agencia: '274'  # será formatado para '0274'
conta_corrente: '1454204'  # será formatado para '0001454204'
digito_conta_corrente: '7'
carteira: '11'
variacao: '4'
nosso_numero: '69240101'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie: 'R$'
moeda: '9'
```

---

## 12. Banco de Brasília - BRB (070)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `nosso_numero_incremento` - Incremento do campo livre (máximo 3 dígitos)

### Validações de Tamanho
- `agencia`: exatamente 3 dígitos (preenchido com zeros à esquerda)
- `conta_corrente`: máximo 7 dígitos (preenchido com zeros à esquerda)
- `carteira`: exatamente 1 dígito
- `nosso_numero`: máximo 6 dígitos (preenchido com zeros à esquerda)
- `nosso_numero_incremento`: máximo 3 dígitos (preenchido com zeros à esquerda)

### Campos Específicos
- `nosso_numero_incremento` - Incremento opcional do campo livre

### Valores Padrão
- `carteira`: '2'
- `nosso_numero_incremento`: '000'
- `local_pagamento`: 'PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO'

### Exemplos de Valores Válidos
```ruby
agencia: '082'  # exatamente 3 dígitos
conta_corrente: '0000528'
carteira: '2'  # ou '1', mas deve ser 1 dígito
nosso_numero: '000001'
nosso_numero_incremento: '000'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie_documento: 'DM'
especie: 'R$'
moeda: '9'
```

**Atenção**: A agência deve ter exatamente 3 dígitos (diferente dos outros bancos que usam 4).

---

## 13. Citibank (745)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `portfolio` - Número da carteira (exatamente 3 dígitos)

### Validações de Tamanho
- `convenio`: exatamente 10 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: exatamente 11 dígitos (preenchido com zeros à esquerda)
- `portfolio`: exatamente 3 dígitos (preenchido com zeros à esquerda)

### Campos Específicos
- `portfolio` - Código da carteira do Citibank (obrigatório)

### Valores Padrão
- `carteira`: '3'
- `carteira_label`: '3'

### Exemplos de Valores Válidos
```ruby
agencia: '1825'
conta_corrente: '0000528'
convenio: '0123456789'  # 10 dígitos
nosso_numero: '00000000001'  # 11 dígitos
portfolio: '650'  # ou '621', '611'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie_documento: 'DM'
moeda: '9'
aceite: 'S'
```

---

## 14. AILOS (085)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 8 dígitos
- `carteira`: exatamente 2 dígitos (preenchido com zeros à esquerda)
- `convenio`: exatamente 6 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 9 dígitos (preenchido com zeros à esquerda)

### Valores Padrão
- `carteira`: '1' (será formatado para '01')
- `local_pagamento`: 'Pagar preferencialmente nas cooperativas do Sistema AILOS.'

### Campos Calculados
- `conta_corrente_dv` - Dígito verificador (módulo 11)

### Exemplos de Valores Válidos
```ruby
agencia: '0101'
conta_corrente: '1111111'
carteira: '01'
convenio: '000000'
nosso_numero: '000000001'  # será formatado para 9 dígitos
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie_documento: 'DM'
moeda: '9'
aceite: 'S'
```

---

## 15. Unicred (136)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 9 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 10 dígitos (preenchido com zeros à esquerda)
- `carteira`: máximo 2 dígitos
- `conta_corrente_dv`: máximo 1 dígito

### Campos Específicos
- `conta_corrente_dv` - Dígito verificador da conta corrente

### Valores Padrão
- `carteira`: '21'
- `local_pagamento`: 'PAGÁVEL PREFERENCIALMENTE NAS AGÊNCIAS DA UNICRED'
- `aceite`: 'N'

### Exemplos de Valores Válidos
```ruby
agencia: '4042'
conta_corrente: '61900'
carteira: '21'
nosso_numero: '00168'
documento_cedente: '12345678912'
sacado_documento: '12345678900'
especie_documento: 'DM'
moeda: '9'
especie: 'R$'
aceite: 'N'
quantidade: 1
```

---

## 16. CREDISIS (097)

### Campos Obrigatórios
- Campos comuns da classe Base (ver acima)
- `documento_cedente` - CPF/CNPJ do cedente (obrigatório e numérico)

### Validações de Tamanho
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 7 dígitos (preenchido com zeros à esquerda)
- `carteira`: exatamente 2 dígitos (preenchido com zeros à esquerda)
- `convenio`: exatamente 6 dígitos (preenchido com zeros à esquerda)
- `nosso_numero`: máximo 6 dígitos (preenchido com zeros à esquerda)

### Validações Especiais
- `documento_cedente`: não pode estar em branco e deve ser numérico (sem formatação)

### Valores Padrão
- `carteira`: '18'
- `local_pagamento`: 'QUALQUER BANCO ATÉ O VENCIMENTO'

### Exemplos de Valores Válidos
```ruby
agencia: '0001'
conta_corrente: '0000002'
carteira: '18'
convenio: 100000  # será formatado para '100000' (6 dígitos)
nosso_numero: '000095'
documento_cedente: '12345678912'  # apenas números
sacado_documento: '12345678900'
especie_documento: 'DM'
moeda: '9'
```

---

## Observações Importantes

### Formatação Automática
A maioria dos bancos aplica formatação automática com preenchimento de zeros à esquerda nos campos numéricos. Você pode passar os valores como strings ou números, e eles serão formatados automaticamente.

### Dígitos Verificadores
Muitos bancos calculam automaticamente os dígitos verificadores. Você não precisa calcular manualmente os DVs de:
- Nosso número
- Agência
- Conta corrente
- Código de barras

### Validação de CPF/CNPJ
O campo `documento_cedente` deve conter apenas números, sem formatação (pontos, traços, barras).

### Datas
As datas podem ser passadas como objetos `Date` do Ruby. Exemplo:
```ruby
data_vencimento: Date.parse('2025-12-31')
data_documento: Date.today
```

### Valores Monetários
O campo `valor` aceita números decimais. Exemplos:
```ruby
valor: 100.50
valor: 1_234.56
valor: 0.01
```

### Local de Pagamento
Cada banco tem um texto padrão diferente para o campo `local_pagamento`. Se não for especificado, será usado o padrão do banco.

---

## Como Usar

### Exemplo Básico

```ruby
require 'brcobranca'

# Exemplo para Banco do Brasil
boleto = Brcobranca::Boleto::BancoBrasil.new do |b|
  # Campos obrigatórios
  b.agencia = '4042'
  b.conta_corrente = '61900'
  b.convenio = '12387989'
  b.nosso_numero = '777700168'

  # Dados do beneficiário (cedente)
  b.cedente = 'Empresa LTDA'
  b.documento_cedente = '12345678000190'

  # Dados do pagador (sacado)
  b.sacado = 'João da Silva'
  b.sacado_documento = '12345678900'
  b.sacado_endereco = 'Rua Exemplo, 123 - Bairro - Cidade/UF'

  # Dados do boleto
  b.valor = 100.00
  b.data_vencimento = Date.parse('2025-12-31')
  b.data_documento = Date.today

  # Campos com valores padrão (opcionais)
  b.carteira = '18'
  b.moeda = '9'
  b.especie_documento = 'DM'
  b.especie = 'R$'
  b.aceite = 'S'

  # Instruções (opcional)
  b.instrucoes1 = 'Não receber após o vencimento'
  b.instrucoes2 = 'Após o vencimento cobrar multa de 2%'
end

# Validar se todos os campos obrigatórios foram preenchidos
if boleto.valid?
  # Gerar código de barras
  puts boleto.codigo_barras

  # Gerar linha digitável
  puts boleto.codigo_barras.linha_digitavel

  # Gerar PDF
  boleto.to(:pdf)
else
  puts boleto.errors.full_messages
end
```

### Exemplo para Sicredi (com campos específicos)

```ruby
boleto = Brcobranca::Boleto::Sicredi.new do |b|
  b.agencia = '0710'
  b.conta_corrente = '61900'
  b.nosso_numero = '8879'
  b.convenio = '129'

  # Campos específicos do Sicredi
  b.posto = '65'
  b.byte_idt = '2'

  b.cedente = 'Cooperativa LTDA'
  b.documento_cedente = '12345678912'
  b.sacado = 'João da Silva'
  b.sacado_documento = '12345678900'
  b.valor = 100.00
  b.data_vencimento = Date.parse('2025-12-31')
end
```

### Exemplo para Caixa (com código de emissão)

```ruby
boleto = Brcobranca::Boleto::Caixa.new do |b|
  b.agencia = '1825'
  b.conta_corrente = '0000528'
  b.convenio = '245274'
  b.nosso_numero = '000000000000001'

  # Campo específico da Caixa
  b.emissao = '4'  # 4 = emissão pelo beneficiário

  b.cedente = 'Empresa LTDA'
  b.documento_cedente = '12345678000190'
  b.sacado = 'João da Silva'
  b.sacado_documento = '12345678900'
  b.valor = 100.00
  b.data_vencimento = Date.parse('2025-12-31')
end
```

---

## Referências

- Repositório BRCobranca: https://github.com/maxwbh/brcobranca
- Código fonte: lib/brcobranca/boleto/
- Testes: spec/brcobranca/boleto/

---

**Documentação gerada a partir do código fonte do BRCobranca**
**Última atualização: 2025-11-24**
