# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

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
- 🔄 Cliente Python oficial instalável via pip
- 🔄 Versionamento semântico automatizado
- 🔄 GitHub Actions para CI/CD
- 🔄 Badges de status e qualidade

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
