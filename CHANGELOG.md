# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.2.0] - 2026-04-08

### Adicionado

#### Endpoint OFX (Extrato Bancário)
- ✅ `POST /api/ofx/parse` - Parsing de arquivos OFX com retorno JSON estruturado
- ✅ Suporte a OFX v1 (SGML) e v2 (XML)
- ✅ Conversão automática de encoding Latin-1 para UTF-8
- ✅ Filtro `somente_creditos=true` para retornar apenas créditos
- ✅ Extração automática de `nosso_numero` do campo memo por banco

#### Módulo NossoNumeroExtractor
- ✅ Extração por regex para Sicoob (756), Itaú (341), BB (001), Bradesco (237), Caixa (104)
- ✅ Fallback genérico para bancos não mapeados

#### Testes
- ✅ 20 testes unitários para NossoNumeroExtractor
- ✅ 14 testes unitários para OFXParserService
- ✅ 7 testes de integração para endpoint OFX
- ✅ Fixtures OFX para Sicoob e Itaú

### Modificado
- 📦 Gemfile: adicionada gem `ofx` para parsing de extratos bancários
- 📦 Gemfile: adicionadas gems `rspec` e `rack-test` no grupo de teste
- 🔧 ErrorHandler: tratamento de `Grape::Exceptions::ValidationErrors` como HTTP 400

---

## [1.1.0] - 2026-01-06

### Adicionado

#### Arquitetura Modular (Fase 1)
- ✅ Refatoração completa: de 444 linhas em 1 arquivo para 12 arquivos modulares
- ✅ `lib/boleto_api/config/constants.rb` - Constantes centralizadas
- ✅ `lib/boleto_api/services/` - Camada de serviços (BoletoService, RemessaService, RetornoService)
- ✅ `lib/boleto_api/endpoints/` - Endpoints separados por domínio
- ✅ `lib/boleto_api/middleware/` - Error handler e request logger

#### Cliente Python (Fase 3)
- ✅ `pyproject.toml` - Configuração moderna PEP 517/518
- ✅ `types.py` - TypedDict para tipagem estática (BoletoDataDict, BoletoResponseDict, etc.)
- ✅ Suite de testes pytest completa (test_client.py, test_models.py, test_exceptions.py, test_types.py)
- ✅ Compatibilidade com Python 3.8+ via typing_extensions

#### Infraestrutura (Fase 4)
- ✅ Testes de integração: `spec/integration/` (remessa, retorno, multi_boleto)
- ✅ Documentação OpenAPI 3.0: `docs/openapi.yaml`
- ✅ Interface Swagger UI: `docs/swagger.html`
- ✅ Docker multi-stage build otimizado (~150MB)

#### Integração brcobranca v12.5+ (Fase 5)
- ✅ BoletoService usa `boleto.to_hash` e `dados_calculados`
- ✅ RemessaService usa `Brcobranca::Remessa.criar` factory method
- ✅ RetornoService usa `Brcobranca::Retorno.parse` com detecção automática
- ✅ Fallback mantido para versões anteriores da gem

### Modificado
- 📦 Gemfile atualizado para usar fork @maxwbh do brcobranca
- 📝 TODO_INTEGRACAO.md - Todas as 5 fases concluídas
- 🔧 Services refatorados para usar novos métodos da gem

### Repositórios
- brcobranca: https://github.com/Maxwbh/brcobranca (v12.5.0)
- boleto_cnab_api: https://github.com/Maxwbh/boleto_cnab_api (v1.1.0)

---

## [1.0.0] - 2025-11-27

### Adicionado
- 🎉 Versão inicial estável
- ✅ Suporte completo para 6+ bancos brasileiros
- ✅ API REST com Grape framework
- ✅ Endpoints para validação, geração de dados e PDF
- ✅ Mapeamento automático `numero_documento` ↔ `documento_numero`
- ✅ Logs estruturados com timestamps e tempo de processamento
- ✅ Tratamento seguro de métodos que podem não existir em todos os bancos
- ✅ Testes automatizados com RSpec para múltiplos bancos
- ✅ Docker e Docker Compose para desenvolvimento
- ✅ Configuração otimizada para Render Free Tier
- ✅ Documentação completa de campos por banco
- ✅ Guia de deploy detalhado
- ✅ Health check endpoint

### Bancos Suportados
- Banco do Brasil (001)
- Sicoob (756)
- Bradesco (237)
- Itaú (341)
- Caixa Econômica Federal (104)
- Santander (033)
- Sicredi (748)
- Banrisul (041)
- Banestes (021)
- BRB (070)

### Endpoints
- `GET /api/health` - Health check
- `GET /api/boleto/validate` - Validar dados do boleto
- `GET /api/boleto/data` - Obter dados completos sem gerar PDF
- `GET /api/boleto/nosso_numero` - Gerar nosso número
- `GET /api/boleto` - Gerar boleto (PDF/JPG/PNG/TIF)
- `POST /api/boleto/multi` - Gerar múltiplos boletos
- `POST /api/remessa` - Gerar arquivo de remessa CNAB
- `POST /api/retorno` - Processar arquivo de retorno CNAB

### Segurança
- ✅ Validação de tipos de parâmetros
- ✅ Tratamento robusto de erros
- ✅ Logs sem informações sensíveis
- ✅ Execução como usuário não-root no Docker

### Performance
- ✅ Otimizações para 512MB RAM (Render Free Tier)
- ✅ Puma com 1 worker e até 5 threads
- ✅ MALLOC_ARENA_MAX=2 para reduzir uso de memória
- ✅ Build Docker otimizado

### Documentação
- ✅ README completo e profissional
- ✅ Guia de campos por banco
- ✅ Exemplos práticos Python/Ruby
- ✅ Troubleshooting detalhado
- ✅ Deploy guide para Render
- ✅ Documentação de API inline

### Testes
- ✅ Suite completa com RSpec
- ✅ Testes de integração para todos os bancos
- ✅ Fixtures com dados válidos
- ✅ Cobertura de casos de erro
- ✅ Testes de mapeamento de campos

---

## [Unreleased]

### Em Desenvolvimento
- 🔄 Publicação do cliente Python no PyPI
- 🔄 GitHub Actions para CI/CD
- 🔄 Badges de status e qualidade
- 🔄 Suporte a PIX (QR Code)

---

## Tipos de Mudanças

- `Adicionado` - Novas funcionalidades
- `Modificado` - Mudanças em funcionalidades existentes
- `Obsoleto` - Funcionalidades que serão removidas
- `Removido` - Funcionalidades removidas
- `Corrigido` - Correção de bugs
- `Segurança` - Correções de vulnerabilidades

---

**Formato:** [MAJOR.MINOR.PATCH]
- **MAJOR** - Mudanças incompatíveis na API
- **MINOR** - Novas funcionalidades compatíveis
- **PATCH** - Correções de bugs compatíveis
