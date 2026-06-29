# Arquitetura da API

> **Versão:** 1.1.0 | **Data:** 2026-01-06

Este documento descreve a arquitetura modular da Boleto CNAB API v1.1.0.

## Integração com brcobranca v12.5+

A API integra com o fork [@maxwbh/brcobranca](https://github.com/Maxwbh/brcobranca) v12.5.0:

| Service | Método brcobranca | Fallback |
|---------|------------------|----------|
| BoletoService | `boleto.to_hash`, `dados_calculados` | Mapeamento manual |
| RemessaService | `Brcobranca::Remessa.criar` | Factory legado |
| RetornoService | `Brcobranca::Retorno.parse` | Load_lines direto |

## Estrutura de Diretórios

```
lib/
├── boleto_api.rb              # Entry point principal
└── boleto_api/
    ├── version.rb             # Versão da API
    ├── config/
    │   └── constants.rb       # Constantes centralizadas
    ├── services/
    │   ├── field_mapper.rb    # Mapeamento de campos
    │   ├── boleto_service.rb  # Lógica de boletos
    │   ├── remessa_service.rb # Lógica de remessas
    │   └── retorno_service.rb # Lógica de retornos
    ├── endpoints/
    │   ├── health_endpoint.rb # GET /api/health, /api/info
    │   ├── boleto_endpoint.rb # /api/boleto/*
    │   ├── remessa_endpoint.rb# POST /api/remessa
    │   └── retorno_endpoint.rb# POST /api/retorno
    └── middleware/
        ├── error_handler.rb   # Tratamento centralizado de erros
        └── request_logger.rb  # Logging de requisições
```

## Componentes

### Config

#### Constants (`config/constants.rb`)

Centraliza todas as constantes da aplicação:

```ruby
BoletoApi::Config::Constants::SUPPORTED_BANKS  # Lista de bancos suportados
BoletoApi::Config::Constants::OUTPUT_TYPES     # Formatos de saída (pdf, jpg, png, tif)
BoletoApi::Config::Constants::CNAB_TYPES       # Tipos CNAB (cnab400, cnab240)
BoletoApi::Config::Constants::RETORNO_FIELDS   # Campos do arquivo de retorno

# Métodos auxiliares
BoletoApi::Config::Constants.bank_supported?('itau')       # => true
BoletoApi::Config::Constants.output_type_supported?('pdf') # => true
BoletoApi::Config::Constants.content_type_for('pdf')       # => 'application/pdf'
```

### Services

#### FieldMapper (`services/field_mapper.rb`)

Responsável por mapear e converter campos:

```ruby
# Mapear campos de boleto
values = { 'numero_documento' => '123', 'data_vencimento' => '2024-12-31' }
mapped = BoletoApi::Services::FieldMapper.map_boleto(values)
# => { 'documento_numero' => '123', 'data_vencimento' => #<Date: 2024-12-31> }

# Mapear campos de pagamento
BoletoApi::Services::FieldMapper.map_pagamento(values)
```

**Funcionalidades:**
- Converte `numero_documento` → `documento_numero`
- Converte strings de data para objetos `Date`
- Define `data_vencimento` padrão para pagamentos

#### BoletoService (`services/boleto_service.rb`)

Operações com boletos:

```ruby
# Criar boleto
boleto = BoletoApi::Services::BoletoService.create('banco_brasil', values)

# Validar dados
result = BoletoApi::Services::BoletoService.validate('itau', values)
# => { valid: true, errors: {} }

# Obter dados completos
result = BoletoApi::Services::BoletoService.data('sicoob', values)
# => { valid: true, nosso_numero: '...', codigo_barras: '...', ... }

# Gerar PDF
result = BoletoApi::Services::BoletoService.generate('bradesco', values, format: 'pdf')
# => { valid: true, content: <binary>, errors: {} }

# Gerar múltiplos boletos
result = BoletoApi::Services::BoletoService.generate_multi(boletos_array, format: 'pdf')
```

#### RemessaService (`services/remessa_service.rb`)

Geração de arquivos de remessa CNAB:

```ruby
values = {
  'carteira' => '123',
  'agencia' => '1234',
  'pagamentos' => [...]
}

result = BoletoApi::Services::RemessaService.generate('itau', 'cnab400', values)
# => { valid: true, content: <binary>, errors: [] }
```

#### RetornoService (`services/retorno_service.rb`)

Processamento de arquivos de retorno:

```ruby
result = BoletoApi::Services::RetornoService.parse('itau', 'cnab400', file)
# => { valid: true, pagamentos: [...], errors: [] }
```

### Middleware

#### ErrorHandler (`middleware/error_handler.rb`)

Tratamento centralizado de exceções:

| Exceção | Status HTTP | Mensagem |
|---------|-------------|----------|
| `JSON::ParserError` | 400 | JSON inválido |
| `ArgumentError` | 400 | Parâmetro inválido |
| `Brcobranca::BoletoInvalido` | 400 | Boleto inválido |
| `NameError` | 400 | Banco não encontrado |
| `NoMethodError` | 500 | Erro ao acessar campo |
| `StandardError` | 500 | Erro interno |

#### RequestLogger (`middleware/request_logger.rb`)

Logging estruturado em JSON:

```json
{"event":"request_start","method":"GET","path":"/api/boleto","timestamp":"2024-01-15T10:30:00.000-0300"}
{"event":"request_end","method":"GET","path":"/api/boleto","status":200,"duration_ms":45.23,"timestamp":"..."}
```

### Endpoints

#### HealthEndpoint

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/health` | Status da API |
| GET | `/api/info` | Informações da API (versão, bancos suportados) |

#### BoletoEndpoint

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/boleto/validate` | Valida dados do boleto |
| GET | `/api/boleto/data` | Retorna dados completos |
| GET | `/api/boleto/nosso_numero` | Gera nosso_numero |
| GET | `/api/boleto` | Gera boleto (PDF/JPG/PNG/TIF) |
| POST | `/api/boleto/multi` | Gera múltiplos boletos |

#### RemessaEndpoint

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/remessa` | Gera arquivo de remessa CNAB |

#### RetornoEndpoint

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/retorno` | Processa arquivo de retorno |

## Fluxo de Requisição

```
Cliente HTTP
     │
     ▼
┌─────────────┐
│ Grape API   │
└─────────────┘
     │
     ▼
┌─────────────────┐
│ RequestLogger   │ ← Log de início
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ ErrorHandler    │ ← Captura exceções
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ Endpoint        │ ← BoletoEndpoint, etc
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ Service         │ ← BoletoService, etc
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ FieldMapper     │ ← Mapeamento de campos
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ brcobranca gem  │ ← Lógica de negócio
└─────────────────┘
```

## Testes

```bash
# Rodar todos os testes
bundle exec rspec

# Testes unitários
bundle exec rspec spec/unit/

# Testes de integração (endpoints)
bundle exec rspec spec/boleto_spec.rb
bundle exec rspec spec/all_banks_spec.rb
```

## Exemplo de Uso

```ruby
require 'boleto_api'

# Configurar logger customizado (opcional)
BoletoApi.logger = Logger.new('boleto_api.log')

# Usar serviços diretamente
result = BoletoApi::Services::BoletoService.data('banco_brasil', {
  'valor' => 100.0,
  'cedente' => 'Empresa LTDA',
  'documento_cedente' => '12345678000199',
  'sacado' => 'Cliente',
  'sacado_documento' => '12345678901',
  'agencia' => '1234',
  'conta_corrente' => '12345',
  'convenio' => '123456',
  'nosso_numero' => '12345678'
})

puts result[:codigo_barras]
puts result[:linha_digitavel]
```

## Métricas

| Métrica | v1.0.0 (Antes) | v1.1.0 (Atual) |
|---------|----------------|----------------|
| Linhas em boleto_api.rb | 444 | 53 |
| Arquivos na lib/boleto_api/ | 1 | 12 |
| Módulos separados | 0 | 4 (config, services, endpoints, middleware) |
| Testes de integração | 0 | 3 (remessa, retorno, multi_boleto) |
| Documentação OpenAPI | ❌ | ✅ (docs/openapi.yaml) |
| Cliente Python com tipos | ❌ | ✅ (TypedDict) |

## Repositórios

- **brcobranca:** https://github.com/Maxwbh/brcobranca
- **boleto_cnab_api:** https://github.com/Maxwbh/boleto_cnab_api

---

**Mantido por:** Maxwell Oliveira (@maxwbh) - M&S do Brasil LTDA
