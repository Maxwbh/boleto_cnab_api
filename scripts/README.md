# Scripts de Automação

Scripts úteis para desenvolvimento e manutenção do projeto.

## 📦 bump-version.sh

Script para incrementar a versão do projeto seguindo [Semantic Versioning](https://semver.org/).

### Versionamento Semântico

```
MAJOR.MINOR.PATCH

1.0.0 -> 1.0.1  (patch - correção de bugs)
1.0.1 -> 1.1.0  (minor - nova funcionalidade)
1.1.0 -> 2.0.0  (major - mudança incompatível)
```

### Uso

```bash
# Incrementar PATCH (1.0.0 -> 1.0.1) - correções de bugs
./scripts/bump-version.sh patch

# Incrementar MINOR (1.0.1 -> 1.1.0) - nova funcionalidade
./scripts/bump-version.sh minor

# Incrementar MAJOR (1.1.0 -> 2.0.0) - breaking changes
./scripts/bump-version.sh major

# Sem argumentos = patch (padrão)
./scripts/bump-version.sh
```

### O que o script faz

1. ✅ Lê a versão atual do arquivo `VERSION`
2. ✅ Incrementa conforme o tipo (patch/minor/major)
3. ✅ Atualiza `VERSION`
4. ✅ Atualiza `python-client/boleto_cnab_client/__init__.py`
5. ✅ Adiciona entrada no `CHANGELOG.md`
6. ✅ Mostra próximos passos

### Exemplo Completo

```bash
# 1. Fazer alterações no código
vim lib/boleto_api.rb

# 2. Executar testes
bundle exec rspec

# 3. Incrementar versão (patch para bugfix)
./scripts/bump-version.sh patch

# 4. Editar CHANGELOG.md e descrever as mudanças
vim CHANGELOG.md

# 5. Commit
git add VERSION CHANGELOG.md python-client/boleto_cnab_client/__init__.py
git commit --author="Maxwell da Silva Oliveira <maxwbh@gmail.com>" -m "[RELEASE] Versão 1.0.1"

# 6. Criar tag
git tag -a v1.0.1 -m "Versão 1.0.1"

# 7. Push com tags
git push origin claude/fix-boleto-pdf-fields-01CJoiUip3iG8zHwHuHwygUk --tags
```

### Quando usar cada tipo de versão

#### PATCH (1.0.0 -> 1.0.1)
- ✅ Correção de bugs
- ✅ Pequenas melhorias
- ✅ Atualizações de documentação
- ✅ Refatorações internas
- ✅ Correções de segurança

Exemplo:
```bash
# Corrigiu bug no Sicoob
./scripts/bump-version.sh patch
```

#### MINOR (1.0.0 -> 1.1.0)
- ✅ Nova funcionalidade (compatível)
- ✅ Novo banco suportado
- ✅ Novo endpoint na API
- ✅ Melhorias significativas

Exemplo:
```bash
# Adicionou suporte para Banrisul
./scripts/bump-version.sh minor
```

#### MAJOR (1.0.0 -> 2.0.0)
- ✅ Breaking changes
- ✅ Mudança na estrutura da API
- ✅ Remoção de endpoints
- ✅ Mudança obrigatória de campos

Exemplo:
```bash
# Removeu campos deprecated
./scripts/bump-version.sh major
```

### Integração com CI/CD

Para automatizar versionamento em pipelines:

```bash
# No seu pipeline (GitHub Actions, etc.)
- name: Bump version
  run: |
    chmod +x scripts/bump-version.sh
    ./scripts/bump-version.sh patch

- name: Commit version
  run: |
    git config user.name "Maxwell da Silva Oliveira"
    git config user.email "maxwbh@gmail.com"
    git add VERSION CHANGELOG.md python-client/
    git commit -m "[AUTO] Bump version"
    git push
```

## 🔧 Manutenção

### Adicionar novo script

1. Crie o script em `scripts/`
2. Torne executável: `chmod +x scripts/seu-script.sh`
3. Documente neste README
4. Commit com mensagem descritiva

### Boas práticas para scripts

- ✅ Use `set -e` para parar em erros
- ✅ Adicione comentários explicativos
- ✅ Use cores para output (`echo -e "${GREEN}✅ Sucesso${NC}"`)
- ✅ Valide inputs e arquivos necessários
- ✅ Forneça mensagens de erro claras
- ✅ Documente uso e exemplos

---

**Versão:** 1.0.0
**Última atualização:** 2025-11-27
