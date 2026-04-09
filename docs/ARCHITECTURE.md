# Arquitetura da API

> **Versão:** 1.2.0

Este documento descreve a arquitetura modular da Boleto CNAB API.

## Visão Geral

A API é construída sobre o framework [Grape](https://github.com/ruby-grape/grape) e organizada em quatro camadas principais:

```
┌─────────────────────────────────────────┐
│              Endpoints                  │  ← Rotas HTTP (Grape)
├─────────────────────────────────────────┤
│              Services                   │  ← Lógica de negócio
├─────────────────────────────────────────┤
│              Middleware                 │  ← Logging, tratamento de erros
├─────────────────────────────────────────┤
│              Config                     │  ← Constantes centralizadas
└─────────────────────────────────────────┘
                    │
                    ▼
         ┌──────────────────┐
         │ Gems externas    │
         │ brcobranca, ofx  │
         └──────────────────┘
```

## Integração com brcobranca v12.5+

Usa o fork [@maxwbh/brcobranca](https://github.com/Maxwbh/brcobranca):

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
    ├── version.rb             # Versão da API (1.2.0)
    ├── config/
    │   └── constants.rb       # Constantes centralizadas
    ├── services/
    │   ├── field_mapper.rb            # Mapeamento de campos
    │   ├── boleto_service.rb          # Lógica de boletos
    │   ├── remessa_service.rb         # Lógica de remessas CNAB
    │   ├── retorno_service.rb         # Lógica de retornos CNAB
    │   ├── ofx_parser_service.rb      # Parsing de arquivos OFX (v1.2.0)
    │   └── nosso_numero_extractor.rb  # Extração por banco (v1.2.0)
    ├── endpoints/
    │   ├── health_endpoint.rb  # GET /api/health, /api/info
    │   ├── boleto_endpoint.rb  # /api/boleto/*
    │   ├── remessa_endpoint.rb # POST /api/remessa
    │   ├── retorno_endpoint.rb # POST /api/retorno
    │   └── ofx_endpoint.rb     # POST /api/ofx/parse (v1.2.0)
    └── middleware/
        ├── error_handler.rb    # Tratamento centralizado de erros
        └── request_logger.rb   # Logging de requisições
```

## Componentes

### Config

#### Constants (`config/constants.rb`)

Centraliza todas as constantes da aplicação:

```ruby
BoletoApi::Config::Constants::SUPPORTED_BANKS  # 18 bancos
BoletoApi::Config::Constants::OUTPUT_TYPES     # pdf, jpg, png, tif
BoletoApi::Config::Constants::CNAB_TYPES       # cnab400, cnab240
BoletoApi::Config::Constants::RETORNO_FIELDS   # Campos do CNAB de retorno

# Métodos auxiliares
BoletoApi::Config::Constants.bank_supported?('itau')       # => true
BoletoApi::Config::Constants.output_type_supported?('pdf') # => true
BoletoApi::Config::Constants.content_type_for('pdf')       # => 'application/pdf'
```

### Services

#### FieldMapper

Responsável por mapear e converter campos:

- Converte `numero_documento` → `documento_numero`
- Converte strings de data para objetos `Date`
- Define `data_vencimento` padrão para pagamentos

#### BoletoService

Operações com boletos:

```ruby
BoletoApi::Services::BoletoService.create('banco_brasil', values)
BoletoApi::Services::BoletoService.validate('itau', values)
BoletoApi::Services::BoletoService.data('sicoob', values)
BoletoApi::Services::BoletoService.generate('bradesco', values, format: 'pdf')
BoletoApi::Services::BoletoService.generate_multi(boletos_array, format: 'pdf')
```

#### RemessaService

Geração de arquivos de remessa CNAB via `Brcobranca::Remessa.criar`:

```ruby
result = BoletoApi::Services::RemessaService.generate('banco_brasil', 'cnab240', values)
# => { valid: true, content: <bytes>, errors: [] }
```

Internamente usa keyword arguments (`banco:`, `formato:`, `pagamentos:`) e converte hashes em objetos `Brcobranca::Remessa::Pagamento`.

#### RetornoService

Processamento de arquivos de retorno:

```ruby
result = BoletoApi::Services::RetornoService.parse('itau', 'cnab400', file)
# => { valid: true, pagamentos: [...], errors: [] }
```

#### OFXParserService (v1.2.0)

Parsing de extratos bancários OFX usando a gem `ofx`:

```ruby
result = BoletoApi::Services::OFXParserService.parse(file, somente_creditos: false)
# => { banco: {...}, conta: {...}, transacoes: [...], resumo: {...} }
```

**Recursos:**
- Suporte a OFX v1 (SGML) e v2 (XML)
- Conversão automática de encoding Latin-1 → UTF-8
- Filtro opcional `somente_creditos`
- Extração automática de `nosso_numero` do campo memo

#### NossoNumeroExtractor (v1.2.0)

Extração de `nosso_numero` do campo memo OFX por banco:

```ruby
BoletoApi::Services::NossoNumeroExtractor.extrair('COBRANCA SICOOB 0000012345', 'SICOOB')
# => "0000012345"
```

| Banco | Identificador | Regex |
|-------|---------------|-------|
| Sicoob | 756 | `\d{7,12}` |
| Itaú | 341 | `\d{8}` |
| Banco do Brasil | 001 | `\d{10,17}` |
| Bradesco | 237 | `\d{11}` |
| Caixa | 104 | `\d{14,17}` |
| Genérico | (outros) | `\d{7,17}` |

### Middleware

#### ErrorHandler

Tratamento centralizado de exceções:

| Exceção | Status HTTP | Mensagem |
|---------|-------------|----------|
| `JSON::ParserError` | 400 | JSON inválido |
| `Grape::Exceptions::ValidationErrors` | 400 | Parâmetro inválido |
| `ArgumentError` | 400 | Parâmetro inválido |
| `Brcobranca::BoletoInvalido` | 400 | Boleto inválido |
| `Brcobranca::RemessaInvalida` | 400 | Remessa inválida |
| `NameError` | 400 | Banco não encontrado |
| `NoMethodError` | 500 | Erro ao acessar campo |
| `StandardError` | 500 | Erro interno |

#### RequestLogger

Logging estruturado em JSON:

```json
{"event":"request_start","method":"GET","path":"/api/boleto","timestamp":"..."}
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

#### OFXEndpoint (v1.2.0)

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/ofx/parse` | Parseia arquivo OFX e retorna JSON |

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
│ Endpoint        │ ← BoletoEndpoint, OFXEndpoint, etc
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ Service         │ ← BoletoService, OFXParserService, etc
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ FieldMapper     │ ← Mapeamento de campos (quando aplicável)
└─────────────────┘
     │
     ▼
┌─────────────────┐
│ brcobranca/ofx  │ ← Lógica de negócio
└─────────────────┘
```

## Fluxo Específico: Parsing OFX

```
POST /api/ofx/parse (multipart)
  │
  ▼ file
OFXEndpoint
  │
  ▼
OFXParserService.parse
  │
  ├─ read_and_normalize_encoding (Latin-1 → UTF-8)
  │
  ├─ parse_ofx (via gem ofx)
  │
  ├─ extract_org / extract_fid (banco)
  │
  ├─ build_transacoes
  │    │
  │    └─ NossoNumeroExtractor.extrair (por banco)
  │
  └─ build_response
       │
       ▼
     JSON (201 Created)
```

## Testes

```bash
# Todos os testes
bundle exec rspec

# Testes unitários
bundle exec rspec spec/unit/

# Testes de integração
bundle exec rspec spec/integration/

# Testes específicos
bundle exec rspec spec/unit/services/ofx_parser_service_spec.rb
bundle exec rspec spec/integration/ofx_endpoint_spec.rb
```

**Cobertura atual (v1.2.0):**

| Módulo | Testes |
|--------|--------|
| NossoNumeroExtractor | 20 |
| OFXParserService | 14 |
| OFX Endpoint | 7 |
| BoletoService | 16 |
| Constants | 17 |
| FieldMapper | 11 |
| RemessaService | 5 |
| RetornoService | 2 |
| Total | ~92 |

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

| Métrica | v1.0.0 | v1.1.0 | v1.2.0 |
|---------|--------|--------|--------|
| Linhas em boleto_api.rb | 444 | 53 | 55 |
| Arquivos na lib/boleto_api/ | 1 | 12 | 14 |
| Serviços | 0 | 4 | 6 |
| Endpoints | 1 | 4 | 5 |
| Testes totais | ~30 | ~60 | ~92 |

## Repositórios

- **brcobranca:** https://github.com/Maxwbh/brcobranca
- **boleto_cnab_api:** https://github.com/Maxwbh/boleto_cnab_api

---

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) - M&S do Brasil LTDA
