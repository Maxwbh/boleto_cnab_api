# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.3.0] - 2026-04-10

### Adicionado

#### Banco C6 (336) — NOVO
- ✅ `banco_c6` adicionado em `SUPPORTED_BANKS` e `CNAB400_BANKS`
- ✅ Suporte completo a geração de boletos C6 (código 336)
- ✅ Remessa e retorno CNAB 400 para Banco C6
- ✅ PIX híbrido suportado (campo `emv`)
- ✅ Fixture `banco_c6_valido` em `spec/fixtures/sample_data.json`
- ✅ Testes no `all_banks_spec.rb` incluindo PDF generation

#### PIX Híbrido documentado
- 📄 `docs/api/pix.md` — Guia completo de PIX híbrido
- 📄 Bancos com PIX: Banco do Brasil, Bradesco, Itaú, Sicoob, Caixa, Banco C6, Santander, Sicredi
- 📄 Campos `emv` e `pix_label` adicionados no schema OpenAPI `BoletoData`
- 📄 Objeto `pix` no schema `BoletoResponse`

#### Documentação brcobranca-fork.md reescrita
- 📄 Tabela completa de 18 bancos com colunas Boleto, CNAB 400, CNAB 240, PIX
- 📄 Histórico de versões do fork (v12.0 → v12.6.1)
- 📄 Métodos modernos da gem: `to_hash`, `dados_calculados`, `dados_entrada`, `dados_pix`, `valido?`, `to_hash_seguro`
- 📄 Factory methods: `Brcobranca::Remessa.criar`, `Brcobranca::Retorno.parse`
- 📄 Seção detalhada por banco com particularidades

### Modificado
- 📦 **brcobranca atualizado**: 12.6.0 → 12.6.1 (traz suporte nativo a Banco C6)
- 📖 OpenAPI v1.2.0 → v1.3.0, schema `BankCode` inclui `banco_c6`
- 📖 README.md, ARCHITECTURE.md, python-client/README.md atualizados para v1.3.0
- 📖 `docs/fields/all-banks.md` inclui seção detalhada do Banco C6

### Versão da Gem

Este release atualiza brcobranca de 12.6.0 → 12.6.1, trazendo:
- Banco C6 (336) com CNAB 400 completo
- PIX expandido (6 bancos: Bradesco, Itaú, Banco C6, Sicoob, Caixa, Banco Brasil)
- Sicoob: suporte a Carteira 9 e Layout 810
- PrawnBolepix (alternativa ao Ghostscript para PIX)

---

## [1.2.0] - 2026-04-09

### Adicionado

#### Endpoint OFX (Extrato Bancário)
- `POST /api/ofx/parse` - Parsing de arquivos OFX com retorno JSON estruturado
- Suporte a OFX v1 (SGML) e v2 (XML)
- Conversão automática de encoding Latin-1 para UTF-8
- Filtro `somente_creditos=true` para retornar apenas créditos
- Extração automática de `nosso_numero` do campo memo por banco

#### Módulo NossoNumeroExtractor
- Extração por regex para Sicoob (756), Itaú (341), BB (001), Bradesco (237), Caixa (104)
- Fallback genérico para bancos não mapeados

#### Testes
- 20 testes unitários para NossoNumeroExtractor
- 14 testes unitários para OFXParserService
- 7 testes de integração para endpoint OFX
- Fixtures OFX para Sicoob e Itaú
- **Total: 158 testes Ruby + 44 testes Python (202 passando)**

#### Documentação
- `docs/README.md` - Índice central da documentação
- `docs/api/ofx-parsing.md` - Guia detalhado do endpoint OFX
- `docs/openapi.yaml` atualizado com schemas `OfxResponse`, `OfxTransacao`, `OfxError`
- Troubleshooting reescrito com seções por endpoint incluindo OFX

### Modificado
- Gemfile: adicionada gem `ofx` para parsing de extratos bancários
- Gemfile: adicionadas gems `rspec` e `rack-test` no grupo de teste
- ErrorHandler: trata `Grape::Exceptions::ValidationErrors` e `Brcobranca::NaoImplementado` como HTTP 400
- BoletoService.create: filtra campos não suportados por banco (evita NoMethodError em Bradesco por `digito_conta`)
- BoletoService.data: normaliza contrato público (`documento_numero` → `numero_documento` alias)
- BoletoService.nosso_numero: mantém compatibilidade com `nosso_numero` como chave formatada
- BoletoService.generate_multi: valida array vazio
- RemessaService: factory method usa `**kwargs` corretamente (Ruby 3.0+)
- RemessaService: converte hashes em objetos `Brcobranca::Remessa::Pagamento`
- FieldMapper: novo mapeamento `PAGAMENTO_FIELD_MAPPINGS` (sacado → nome_sacado, etc)
- Endpoints POST retornam explicitamente status 200 para binários (boleto, remessa, retorno, multi)
- Dockerfile: `BUNDLE_WITHOUT=development:test` no runtime stage
- Dockerfile: label de versão atualizado para 1.2.0
- docker-compose: serviço test instala dev deps antes de rodar rspec
- CI workflow: tag Docker em lowercase, dependências pytest instaladas via pip install -e

### Corrigido
- Remessa: `tipo:` → `formato:` (chave correta para `Brcobranca::Remessa.criar`)
- Remessa: passagem posicional → keyword arguments em Ruby 3.0+
- Remessa: formato correto `cnab400`/`cnab240` (não apenas `400`/`240`)
- Client Python: `RetryError` convertido para `BoletoAPIError`
- Fixtures: `caixa_valido` carteira `"SR"` → `"1"`, `santander_valido` ajustado para convenio válido
- `spec_helper.rb`: forçar encoding UTF-8 para arquivos com acentos
- `all_banks_spec.rb`: correção de scoping (`let` dentro de `context.each`)

### Removido
- `docs/DEPLOY.md` (duplicado do `DEPLOY.md` na raiz)
- `docs/TODO_INTEGRACAO.md` (roadmap concluído, histórico disponível em commits)
- `docs/swagger.html` (deve ser gerado sob demanda do `openapi.yaml`)

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
