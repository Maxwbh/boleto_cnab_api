# Contribuindo para Boleto CNAB API

Obrigado por considerar contribuir com o Boleto CNAB API! Este documento fornece diretrizes para contribuir com o projeto.

## 📋 Índice

- [Código de Conduta](#código-de-conduta)
- [Como Contribuir](#como-contribuir)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Processo de Desenvolvimento](#processo-de-desenvolvimento)
- [Padrões de Código](#padrões-de-código)
- [Commits e Versionamento](#commits-e-versionamento)
- [Testes](#testes)
- [Documentação](#documentação)
- [Pull Requests](#pull-requests)

## 🤝 Código de Conduta

Este projeto adere a um código de conduta. Ao participar, espera-se que você mantenha este código:

- Use linguagem acolhedora e inclusiva
- Seja respeitoso com diferentes pontos de vista
- Aceite críticas construtivas com elegância
- Foque no que é melhor para a comunidade
- Mostre empatia com outros membros da comunidade

## 🎯 Como Contribuir

Existem várias maneiras de contribuir:

### 1. Reportar Bugs

Encontrou um bug? Por favor:

1. Verifique se já não existe uma [issue aberta](https://github.com/Maxwbh/boleto_cnab_api/issues)
2. Se não existir, [crie uma nova issue](https://github.com/Maxwbh/boleto_cnab_api/issues/new)
3. Inclua:
   - Descrição clara do problema
   - Passos para reproduzir
   - Comportamento esperado vs observado
   - Versão da API (`VERSION`)
   - Logs de erro (se aplicável)
   - Banco afetado (BB, Sicoob, etc.)

**Exemplo de boa issue:**
```
Título: NoMethodError ao gerar boleto Bradesco

Descrição:
Ao tentar gerar boleto do Bradesco, recebo NoMethodError.

Passos para reproduzir:
1. POST /api/boleto
2. bank=bradesco
3. Dados: {...}

Erro:
NoMethodError: undefined method 'xyz'

Versão: 1.0.0
Ruby: 3.1.2
Docker: Sim
```

### 2. Sugerir Melhorias

Tem uma ideia? Ótimo! Por favor:

1. Verifique se não existe uma sugestão similar
2. Crie uma issue com o label "enhancement"
3. Descreva:
   - O que você quer ver implementado
   - Por que isso seria útil
   - Exemplos de uso (se possível)

### 3. Adicionar Suporte para Novo Banco

Quer adicionar suporte para um novo banco? Siga:

1. Verifique a [documentação do BRCobranca](https://github.com/Maxwbh/brcobranca)
2. Crie fixtures de teste em `spec/fixtures/sample_data.json`
3. Adicione testes em `spec/all_banks_spec.rb`
4. Documente campos obrigatórios em `docs/fields/all-banks.md`
5. Adicione exemplo em `examples/python/`

### 4. Melhorar Documentação

Documentação clara é essencial! Você pode:

- Corrigir erros de ortografia/gramática
- Adicionar exemplos
- Clarificar instruções confusas
- Traduzir documentação
- Adicionar diagramas/imagens

### 5. Contribuir com Código

Quer resolver um bug ou implementar um recurso?

1. Veja a seção [Processo de Desenvolvimento](#processo-de-desenvolvimento)
2. Faça fork do repositório
3. Crie uma branch para sua feature
4. Desenvolva seguindo os [Padrões de Código](#padrões-de-código)
5. Adicione testes
6. Atualize documentação
7. Submeta um Pull Request

## 🛠️ Configuração do Ambiente

### Pré-requisitos

- Ruby 3.1+ (via rbenv ou rvm)
- Docker & Docker Compose (opcional, mas recomendado)
- Python 3.7+ (para testar cliente Python)
- Git

### Setup Local

```bash
# 1. Fork e clone o repositório
git clone https://github.com/SEU-USUARIO/boleto_cnab_api.git
cd boleto_cnab_api

# 2. Instalar dependências Ruby
bundle install

# 3. Instalar cliente Python (para testes)
cd python-client
pip install -e ".[dev]"
cd ..

# 4. Rodar testes
bundle exec rspec

# 5. Iniciar API localmente
bundle exec rackup -p 9292
```

### Com Docker

```bash
# Build da imagem
docker-compose build

# Iniciar serviços
docker-compose up

# Rodar testes no container
docker-compose run boleto_api bundle exec rspec
```

## 🔄 Processo de Desenvolvimento

### 1. Criar Branch

```bash
# Atualizar master
git checkout master
git pull origin master

# Criar branch descritiva
git checkout -b feature/adicionar-banco-banrisul
# ou
git checkout -b fix/corrigir-sicoob-linha-digitavel
# ou
git checkout -b docs/melhorar-readme
```

**Convenção de nomes:**
- `feature/` - Nova funcionalidade
- `fix/` - Correção de bug
- `docs/` - Mudanças em documentação
- `test/` - Adicionar/melhorar testes
- `refactor/` - Refatoração de código

### 2. Desenvolver

Faça suas mudanças seguindo os padrões do projeto.

### 3. Testar

```bash
# Rodar todos os testes
bundle exec rspec

# Rodar teste específico
bundle exec rspec spec/boleto_spec.rb

# Com verbose
bundle exec rspec --format documentation

# Verificar cobertura
bundle exec rspec --format progress
```

### 4. Documentar

- Atualize `docs/` se mudou API
- Atualize `README.md` se mudou setup
- Adicione exemplos em `examples/`
- Comente código complexo

### 5. Commit

Siga as [convenções de commit](#commits-e-versionamento).

## 📝 Padrões de Código

### Ruby

```ruby
# ✅ BOM: Métodos claros e concisos
def validar_boleto(dados)
  return false unless dados[:valor].positive?
  return false unless dados[:nosso_numero].present?
  true
end

# ❌ RUIM: Método muito complexo
def processar(d)
  # código confuso sem comentários
end
```

**Diretrizes:**
- Use nomes descritivos de variáveis/métodos
- Métodos devem fazer uma única coisa
- Limite linhas a 100 caracteres
- Use Ruby idiomático (`.present?`, `.blank?`, etc.)
- Adicione comentários para lógica complexa
- Prefira guard clauses

### Python

```python
# ✅ BOM: Type hints e docstrings
def gerar_boleto(banco: str, dados: Dict[str, Any]) -> bytes:
    """
    Gera PDF do boleto.

    Args:
        banco: Código do banco (ex: 'banco_brasil')
        dados: Dicionário com dados do boleto

    Returns:
        bytes: Conteúdo do PDF

    Raises:
        BoletoValidationError: Se dados inválidos
    """
    # implementação

# ❌ RUIM: Sem type hints ou documentação
def gerar(b, d):
    # implementação
```

**Diretrizes:**
- Use type hints
- Adicione docstrings em funções públicas
- Siga PEP 8
- Use nomes descritivos
- Prefira list/dict comprehensions

### Markdown

- Use títulos hierárquicos (`#`, `##`, `###`)
- Adicione exemplos de código com syntax highlighting
- Use listas para enumerar itens
- Adicione links para documentação relacionada
- Use tabelas para comparações

## 📌 Commits e Versionamento

### Mensagens de Commit

Use o padrão **Conventional Commits** com prefixos:

```
[TIPO] Descrição curta (50 chars)

Descrição detalhada (se necessário)
- Item 1
- Item 2
```

**Tipos:**
- `[FEAT]` - Nova funcionalidade
- `[FIX]` - Correção de bug
- `[DOC]` - Mudanças em documentação
- `[TEST]` - Adicionar/modificar testes
- `[REFACTOR]` - Refatoração de código
- `[PERF]` - Melhorias de performance
- `[STYLE]` - Formatação, ponto e vírgula, etc.
- `[CHORE]` - Manutenção, deps, config
- `[RELEASE]` - Nova versão

**Exemplos:**

```bash
# ✅ BOM
git commit -m "[FEAT] Adicionar suporte para Banco Banrisul

- Implementar classe Brcobranca::Boleto::Banrisul
- Adicionar fixtures de teste
- Documentar campos obrigatórios
- Adicionar exemplo Python"

# ✅ BOM
git commit -m "[FIX] Corrigir linha_digitavel do Sicoob

Usar respond_to? para evitar NoMethodError quando
método não está disponível no banco."

# ❌ RUIM
git commit -m "fix bug"

# ❌ RUIM
git commit -m "mudanças"
```

### Versionamento Semântico

Use o script `bump-version.sh`:

```bash
# PATCH: Correções de bugs (1.0.0 -> 1.0.1)
./scripts/bump-version.sh patch

# MINOR: Nova funcionalidade compatível (1.0.1 -> 1.1.0)
./scripts/bump-version.sh minor

# MAJOR: Breaking changes (1.1.0 -> 2.0.0)
./scripts/bump-version.sh major
```

**Quando usar cada tipo:**

- **PATCH**: Bugfixes, correções de documentação, refatorações internas
- **MINOR**: Novo banco, novo endpoint, nova funcionalidade compatível
- **MAJOR**: Mudança na API, remoção de endpoint, mudança de campos obrigatórios

### Atribuição de Commits

**IMPORTANTE:** Commits devem ser atribuídos ao autor original:

```bash
git commit --author="Seu Nome <seu@email.com>" -m "[FEAT] Nova funcionalidade"
```

Para este projeto, commits do mantenedor:
```bash
git commit --author="Maxwell da Silva Oliveira <maxwbh@gmail.com>" -m "..."
```

## 🧪 Testes

### Estrutura de Testes

```
spec/
├── spec_helper.rb           # Configuração RSpec
├── boleto_spec.rb          # Testes principais da API
├── all_banks_spec.rb       # Testes de compatibilidade
└── fixtures/
    └── sample_data.json    # Dados de teste
```

### Escrevendo Testes

```ruby
# spec/banco_novo_spec.rb
require 'spec_helper'

RSpec.describe 'API - Banco Novo' do
  include Rack::Test::Methods

  def app
    BoletoApi
  end

  let(:dados_validos) do
    {
      # dados do banco
    }
  end

  describe 'GET /api/boleto/validate' do
    it 'valida dados corretos' do
      get '/api/boleto/validate', {
        bank: 'banco_novo',
        data: dados_validos.to_json
      }

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['valid']).to be true
    end

    it 'retorna erro para dados inválidos' do
      get '/api/boleto/validate', {
        bank: 'banco_novo',
        data: {}.to_json
      }

      expect(last_response.status).to eq(400)
    end
  end
end
```

### Rodando Testes

```bash
# Todos os testes
bundle exec rspec

# Teste específico
bundle exec rspec spec/boleto_spec.rb:45

# Com cobertura
bundle exec rspec --format documentation

# Watch mode (se tiver guard)
bundle exec guard
```

### Cobertura de Testes

Idealmente, novos códigos devem ter:
- ✅ Cobertura mínima de 80%
- ✅ Testes de casos felizes (happy path)
- ✅ Testes de casos de erro
- ✅ Testes de edge cases

## 📖 Documentação

### Onde Documentar

| O que                | Onde                           |
|----------------------|--------------------------------|
| API endpoints        | `docs/api/`                    |
| Campos por banco     | `docs/fields/`                 |
| Exemplos de uso      | `examples/python/`             |
| Cliente Python       | `python-client/README.md`      |
| Guia de deploy       | `DEPLOY.md`                    |
| Scripts              | `scripts/README.md`            |
| README principal     | `README.md`                    |
| Changelog            | `CHANGELOG.md`                 |
| Detalhes técnicos    | `docs/development/`            |

## 🔀 Pull Requests

### Antes de Submeter

Checklist:
- [ ] Código segue os padrões do projeto
- [ ] Testes foram adicionados/atualizados
- [ ] Todos os testes passam (`bundle exec rspec`)
- [ ] Documentação foi atualizada
- [ ] CHANGELOG.md foi atualizado (se aplicável)
- [ ] Commits seguem convenção
- [ ] Branch está atualizado com `master`

### Criando Pull Request

1. **Título descritivo:**
   ```
   [FEAT] Adicionar suporte para Banco Banrisul
   ```

2. **Descrição completa:**
   ```markdown
   ## Resumo
   Adiciona suporte completo para geração de boletos do Banco Banrisul (código 041).

   ## Mudanças
   - Implementação da classe Boleto::Banrisul
   - Testes de validação e geração
   - Documentação de campos obrigatórios
   - Exemplo Python

   ## Como testar
   1. Iniciar API
   2. Executar `python examples/python/exemplo_banrisul.py`
   3. Verificar PDF gerado

   ## Checklist
   - [x] Testes passam
   - [x] Documentação atualizada
   - [x] CHANGELOG atualizado
   - [x] Exemplo adicionado

   ## Screenshots
   [Se aplicável]

   ## Issues relacionadas
   Resolve #123
   ```

3. **Atribua labels apropriados:**
   - `enhancement` - Nova funcionalidade
   - `bug` - Correção de bug
   - `documentation` - Mudanças em docs
   - `good first issue` - Bom para iniciantes

### Revisão de Código

Ao revisar PRs:
- ✅ Seja construtivo e respeitoso
- ✅ Sugira melhorias específicas
- ✅ Teste o código localmente
- ✅ Verifique documentação
- ❌ Não seja excessivamente crítico
- ❌ Não aprove sem testar

### Merge

Mantedores irão:
1. Revisar código
2. Testar mudanças
3. Verificar documentação
4. Fazer merge usando "Squash and merge"
5. Atualizar versão (se aplicável)
6. Criar release (se nova versão)

## 🎓 Recursos Úteis

### Documentação Técnica

- [Ruby Style Guide](https://rubystyle.guide/)
- [PEP 8 - Python Style Guide](https://pep8.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

### Ferramentas

- [RuboCop](https://rubocop.org/) - Ruby linter
- [Black](https://black.readthedocs.io/) - Python formatter
- [RSpec](https://rspec.info/) - Ruby testing
- [Pytest](https://pytest.org/) - Python testing

### Repositórios Relacionados

- [BRCobranca](https://github.com/Maxwbh/brcobranca)
- [Grape Framework](https://github.com/ruby-grape/grape)

## 💬 Precisa de Ajuda?

- 📖 Leia a [documentação](./docs/)
- 💬 Abra uma [discussão](https://github.com/Maxwbh/boleto_cnab_api/discussions)
- 🐛 Reporte um [bug](https://github.com/Maxwbh/boleto_cnab_api/issues)
- 📧 Entre em contato: maxwbh@gmail.com

## 🙏 Agradecimentos

Obrigado por dedicar seu tempo para contribuir! Cada contribuição, grande ou pequena, é valiosa e apreciada.

---

**Desenvolvido por Maxwell da Silva Oliveira - M&S do Brasil Ltda**
