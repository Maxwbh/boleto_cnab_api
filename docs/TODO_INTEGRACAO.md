# TODO - Integração e Simplificação dos Projetos

> **Nota**: Este documento também deve ser copiado para `brcobranca/docs/TODO_INTEGRACAO.md`
> para manter ambos os repositórios sincronizados.

Este documento define a estratégia para simplificar e organizar as responsabilidades entre os dois projetos:

- **brcobranca**: Gem Ruby para geração de boletos e arquivos CNAB
  - Repositório: https://github.com/Maxwbh/brcobranca
- **boleto_cnab_api**: API REST que expõe a gem como microsserviço
  - Repositório: https://github.com/Maxwbh/boleto_cnab_api

---

## Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENTES                                        │
│         (Python, Node.js, PHP, Java, qualquer linguagem HTTP)               │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          boleto_cnab_api                                     │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  Responsabilidades:                                                     │ │
│  │  • Endpoints REST (Grape)                                               │ │
│  │  • Validação de entrada (JSON)                                          │ │
│  │  • Tratamento de erros HTTP                                             │ │
│  │  • Conversão de formatos (String → Date)                                │ │
│  │  • Logging e monitoramento                                              │ │
│  │  • Containerização (Docker)                                             │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             brcobranca                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  Responsabilidades:                                                     │ │
│  │  • Lógica de negócio bancária                                           │ │
│  │  • Validações específicas por banco                                     │ │
│  │  • Geração de PDF/Imagens (RGhost)                                      │ │
│  │  • Cálculos (dígito verificador, linha digitável, etc)                  │ │
│  │  • Geração de arquivos CNAB (240/400/444)                               │ │
│  │  • Parsing de arquivos de retorno                                       │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Estrutura Atual vs Proposta

### brcobranca (Gem Ruby)

```
lib/brcobranca/
├── boleto/                    # MANTER - Classes de boleto por banco
│   ├── base.rb                # Classe base com campos comuns
│   ├── banco_brasil.rb
│   ├── itau.rb
│   ├── bradesco.rb
│   ├── sicoob.rb
│   ├── caixa.rb
│   ├── santander.rb
│   ├── sicredi.rb
│   ├── banrisul.rb
│   ├── banestes.rb
│   └── template/              # Templates para renderização
│       ├── rghost.rb
│       ├── rghost2.rb
│       └── rghost_bolepix.rb
│
├── remessa/                   # MANTER - Geração de arquivos remessa
│   ├── base.rb
│   ├── pagamento.rb
│   ├── cnab240/
│   ├── cnab400/
│   └── cnab444/
│
├── retorno/                   # MANTER - Parsing de retornos
│   ├── base.rb
│   ├── cnab240/
│   └── cnab400/
│
└── util/                      # MANTER - Utilitários
    ├── calculo.rb
    ├── calculo_data.rb
    ├── currency.rb
    ├── validations.rb
    └── formatacao.rb
```

### boleto_cnab_api (API REST)

**Estrutura Atual (Monolítica):**
```
lib/
└── boleto_api.rb              # 444 linhas - Tudo em um arquivo (REFATORAR)
```

**Estrutura Proposta (Modular):**
```
lib/
├── boleto_api.rb              # Entry point - require dos módulos
│
├── config/
│   ├── constants.rb           # Constantes (bancos suportados, campos de retorno)
│   └── logging.rb             # Configuração de logging
│
├── services/
│   ├── boleto_service.rb      # Lógica de criação de boletos
│   ├── remessa_service.rb     # Lógica de geração de remessas
│   ├── retorno_service.rb     # Lógica de parsing de retornos
│   └── field_mapper.rb        # Mapeamento de campos (numero_documento → documento_numero)
│
├── endpoints/
│   ├── health_endpoint.rb     # GET /api/health
│   ├── boleto_endpoint.rb     # GET/POST /api/boleto/*
│   ├── remessa_endpoint.rb    # POST /api/remessa
│   └── retorno_endpoint.rb    # POST /api/retorno
│
└── middleware/
    ├── error_handler.rb       # Tratamento centralizado de erros
    └── request_logger.rb      # Logging de requisições (substituir helpers)
```

---

## TODO - Tarefas de Simplificação

### Fase 1: Refatoração da API (boleto_cnab_api)

- [ ] **1.1 Extrair constantes para arquivo separado**
  - Mover `RETORNO_FIELDS` para `config/constants.rb`
  - Criar lista de bancos suportados
  - Criar mapeamento de tipos de saída (pdf, jpg, png, tif)

- [ ] **1.2 Criar classe FieldMapper**
  ```ruby
  # lib/services/field_mapper.rb
  class FieldMapper
    FIELD_MAPPINGS = {
      'numero_documento' => 'documento_numero'
    }.freeze

    DATE_FIELDS = %w[data_documento data_vencimento data_processamento].freeze

    def self.map(values)
      # Mapear campos e converter datas
    end
  end
  ```

- [ ] **1.3 Criar módulo de serviços**
  - `BoletoService.create(bank, values)` → Boleto
  - `RemessaService.generate(bank, type, values)` → Binary
  - `RetornoService.parse(bank, type, file)` → Array

- [ ] **1.4 Extrair endpoints para classes separadas**
  - Cada endpoint com sua própria classe Grape
  - Montar API com `mount` no Server principal

- [ ] **1.5 Implementar middleware de erro**
  ```ruby
  # Substituir blocos rescue repetidos
  class ErrorHandler < Grape::Middleware::Base
    def call(env)
      @app.call(env)
    rescue JSON::ParserError => e
      error_response(400, 'JSON inválido', e.message)
    rescue Brcobranca::BoletoInvalido => e
      error_response(400, 'Boleto inválido', e.message)
    rescue => e
      error_response(500, 'Erro interno', e.message)
    end
  end
  ```

- [ ] **1.6 Simplificar logging**
  - Remover emojis dos logs (dificulta parsing)
  - Usar Grape middleware para log automático
  - Manter logs estruturados (JSON)

### Fase 2: Melhorias na Gem (brcobranca)

- [ ] **2.1 Adicionar método `to_hash` nos boletos**
  ```ruby
  # lib/brcobranca/boleto/base.rb
  def to_hash
    {
      nosso_numero: nosso_numero_boleto,
      codigo_barras: codigo_barras,
      linha_digitavel: linha_digitavel,
      # ... outros campos
    }
  end
  ```
  - Elimina necessidade da API montar manualmente o hash

- [ ] **2.2 Padronizar nomes de campos**
  - Decidir entre `numero_documento` ou `documento_numero`
  - Manter compatibilidade com alias

- [ ] **2.3 Adicionar validação de banco suportado**
  ```ruby
  # lib/brcobranca/boleto/base.rb
  SUPPORTED_BANKS = %w[banco_brasil itau bradesco sicoob ...].freeze

  def self.bank_supported?(bank)
    SUPPORTED_BANKS.include?(bank.to_s.underscore)
  end
  ```

- [ ] **2.4 Melhorar mensagens de erro**
  - Mensagens mais descritivas
  - Incluir campo e valor esperado

- [ ] **2.5 Documentar campos obrigatórios por banco**
  - Atualizar `docs/campos_por_banco.md`
  - Adicionar exemplos de JSON válido

### Fase 3: Cliente Python (boleto_cnab_api)

- [ ] **3.1 Publicar no PyPI**
  - Criar `setup.py` completo
  - Adicionar README para o cliente
  - Versionar junto com a API

- [ ] **3.2 Adicionar testes**
  - Testes unitários com pytest
  - Mock das chamadas HTTP

- [ ] **3.3 Melhorar tipagem**
  - Usar TypedDict para BoletoData
  - Documentar tipos esperados

### Fase 4: Infraestrutura

- [ ] **4.1 Unificar Docker**
  - Multi-stage build otimizado
  - Imagem Alpine < 200MB

- [ ] **4.2 Adicionar testes de integração**
  - Testar fluxo completo: API → Gem → PDF
  - CI/CD com GitHub Actions

- [ ] **4.3 Documentação unificada**
  - API Reference (OpenAPI/Swagger)
  - Exemplos em múltiplas linguagens

---

## Matriz de Responsabilidades

| Funcionalidade | brcobranca | boleto_cnab_api |
|----------------|:----------:|:---------------:|
| Validação de CPF/CNPJ | X | |
| Cálculo de dígitos verificadores | X | |
| Geração de código de barras | X | |
| Geração de linha digitável | X | |
| Renderização PDF/Imagem | X | |
| Geração de arquivo CNAB | X | |
| Parsing de arquivo retorno | X | |
| Conversão JSON → Objeto Ruby | | X |
| Conversão String → Date | | X |
| Mapeamento de campos | | X |
| Endpoints REST | | X |
| Tratamento de erros HTTP | | X |
| Logging de requisições | | X |
| Containerização | | X |

---

## Fluxo de Dados Simplificado

### Gerar Boleto PDF

```
1. Cliente envia JSON
   |
   v
2. API valida JSON (boleto_cnab_api)
   |
   v
3. API mapeia campos (numero_documento -> documento_numero)
   |
   v
4. API converte datas (String -> Date)
   |
   v
5. API cria Boleto (Brcobranca::Boleto::X.new)
   |
   v
6. Gem valida dados bancários (brcobranca)
   |
   v
7. Gem gera PDF (brcobranca + RGhost)
   |
   v
8. API retorna binário com headers corretos
```

### Gerar Remessa CNAB

```
1. Cliente envia JSON com pagamentos
   |
   v
2. API valida JSON (boleto_cnab_api)
   |
   v
3. API cria objetos Pagamento para cada item
   |
   v
4. API cria Remessa com pagamentos
   |
   v
5. Gem valida e gera arquivo CNAB (brcobranca)
   |
   v
6. API retorna arquivo binário
```

### Processar Retorno

```
1. Cliente envia arquivo de retorno
   |
   v
2. API recebe arquivo (boleto_cnab_api)
   |
   v
3. Gem parseia linhas do arquivo (brcobranca)
   |
   v
4. API converte objetos para JSON
   |
   v
5. Cliente recebe array de pagamentos
```

---

## Prioridades

### Alta Prioridade
1. **Refatorar boleto_api.rb em módulos** - Facilita manutenção
2. **Extrair ErrorHandler** - Remove duplicação de código
3. **Adicionar `to_hash` na gem** - Simplifica API

### Média Prioridade
4. **Padronizar nomes de campos** - Evita confusão
5. **Melhorar documentação de campos** - Facilita uso
6. **Publicar cliente Python no PyPI** - Facilita adoção

### Baixa Prioridade
7. **Otimizar imagem Docker** - Economia de recursos
8. **Adicionar Swagger** - Documentação interativa
9. **Testes de integração** - Qualidade de código

---

## Métricas de Sucesso

| Métrica | Atual | Meta |
|---------|-------|------|
| Linhas no boleto_api.rb | 444 | < 100 |
| Arquivos na lib/ | 1 | 10-15 |
| Cobertura de testes | ~60% | > 90% |
| Tamanho imagem Docker | ~512MB | < 200MB |
| Tempo de build | ~3min | < 1min |

---

## Bancos Suportados

### Boletos (18 bancos)
| Banco | Código | Classe |
|-------|--------|--------|
| Banco do Brasil | 001 | `BancoBrasil` |
| Itaú | 341 | `Itau` |
| Bradesco | 237 | `Bradesco` |
| Caixa | 104 | `Caixa` |
| Santander | 033 | `Santander` |
| Sicoob | 756 | `Sicoob` |
| Sicredi | 748 | `Sicredi` |
| Banrisul | 041 | `Banrisul` |
| Banestes | 021 | `Banestes` |
| Banco Nordeste | 004 | `BancoNordeste` |
| BRB | 070 | `BancoBrasilia` |
| Unicred | 136 | `Unicred` |
| Credisis | 097 | `Credisis` |
| Safra | 422 | `Safra` |
| Citibank | 745 | `Citibank` |
| HSBC | 399 | `Hsbc` |
| Ailos | 085 | `Ailos` |

### Remessa CNAB400
Banco do Brasil, Banrisul, Bradesco, Itaú, Citibank, Santander, Sicoob, Banco Nordeste, BRB, Unicred, Credisis

### Remessa CNAB240
Caixa, Banco do Brasil, Santander, Sicoob, Sicredi, Unicred, Ailos

### Retorno CNAB400
Banco do Brasil, Bradesco, Banrisul, Itaú, Santander, Banco Nordeste, BRB, Unicred, Credisis

### Retorno CNAB240
Santander, Sicredi, Sicoob, Caixa, Ailos

---

## Conclusão

A separação clara de responsabilidades entre os projetos já existe conceitualmente. O trabalho principal é:

1. **brcobranca**: Manter como está, adicionar pequenas melhorias (`to_hash`, mensagens de erro)
2. **boleto_cnab_api**: Refatorar de monolítico para modular, melhorar testabilidade

Seguindo este TODO, os projetos ficarão mais simples, manuteníveis e extensíveis.

---

## Links Úteis

- [brcobranca - GitHub](https://github.com/Maxwbh/brcobranca)
- [boleto_cnab_api - GitHub](https://github.com/Maxwbh/boleto_cnab_api)
- [brcobranca - RubyGems](https://rubygems.org/gems/brcobranca)
- [Documentação de Campos por Banco](../docs/fields/README.md)
