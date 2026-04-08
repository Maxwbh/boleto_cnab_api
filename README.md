# Boleto CNAB API
Este projeto é um FORK  atualizado de https://github.com/akretion/boleto_cnab_api
> API REST para geração de Boletos, Remessas e processamento de Retornos bancários usando [BRCobranca](https://github.com/Maxwbh/brcobranca)

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) - M&S do Brasil Ltda

[![Deploy on Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)
[![Python Package](https://img.shields.io/badge/python-3.7%2B-blue)](python-client/)
[![Version](https://img.shields.io/badge/version-1.1.0-green)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## 🚀 Quick Start

```bash
# 1. Clone o repositório
git clone https://github.com/Maxwbh/boleto_cnab_api.git
cd boleto_cnab_api

# 2. Com Docker (recomendado)
docker build -t boleto_cnab_api .
docker run -p 9292:9292 boleto_cnab_api

# 3. Sem Docker
bundle install
rackup -p 9292

# 4. Testar
curl http://localhost:9292/api/health
```

## 🐍 Cliente Python (Recomendado)

Instale o cliente Python oficial para uma integração mais fácil:

```bash
# Instalar via pip (quando publicado)
pip install boleto-cnab-client

# Ou instalar do repositório
cd python-client
pip install -e .
```

### Exemplo de Uso

```python
from boleto_cnab_client import BoletoClient

# Conectar à API
client = BoletoClient('http://localhost:9292')

# Dados do boleto
dados = {
    "cedente": "Minha Empresa LTDA",
    "documento_cedente": "12345678000100",
    "sacado": "João da Silva",
    "sacado_documento": "12345678900",
    "agencia": "3073",
    "conta_corrente": "12345678",
    "convenio": "01234567",
    "carteira": "18",
    "nosso_numero": "123",
    "valor": 150.00,
    "data_vencimento": "2025/12/31"
}

# Gerar boleto
pdf_bytes = client.generate_boleto('banco_brasil', dados)
with open('boleto.pdf', 'wb') as f:
    f.write(pdf_bytes)
```

**📖 Documentação completa:** [python-client/README.md](python-client/README.md)

**💡 Exemplos práticos:** [examples/python/](examples/python/)

## 📚 Documentação

### API Endpoints

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/api/health` | GET | Health check |
| `/api/boleto/validate` | GET | Validar dados do boleto |
| `/api/boleto/data` | GET | Obter dados completos (sem gerar PDF) |
| `/api/boleto/nosso_numero` | GET | Obter nosso_numero e códigos |
| `/api/boleto` | GET | Gerar boleto (PDF/JPG/PNG/TIF) |
| `/api/boleto/multi` | POST | Gerar múltiplos boletos |
| `/api/remessa` | POST | Gerar arquivo de remessa CNAB |
| `/api/retorno` | POST | Processar arquivo de retorno CNAB |
| `/api/ofx/parse` | POST | Parsear arquivo OFX (extrato bancário) |

### Guias Completos

📖 **[Documentação de Campos](./docs/fields/README.md)** - Todos os campos aceitos por banco (BB, Sicoob, etc.)

💡 **[Exemplos Práticos](./docs/fields/examples.md)** - Exemplos de código Python/Ruby com máximo de campos

🔧 **[Troubleshooting](./docs/api/troubleshooting.md)** - Solução de problemas comuns

⚙️ **[Detalhes Técnicos](./docs/development/brcobranca-fork.md)** - Informações sobre a gem BRCobranca

## 💡 Exemplo Rápido

### Gerar Boleto do Banco do Brasil

```python
import requests
import json

boleto_data = {
    "agencia": "3073",
    "conta_corrente": "12345678",
    "convenio": "01234567",
    "carteira": "18",
    "nosso_numero": "123",
    "numero_documento": "NF-2025-001",
    "cedente": "Minha Empresa LTDA",
    "documento_cedente": "12345678000100",
    "sacado": "João da Silva",
    "sacado_documento": "12345678900",
    "valor": 1500.00,
    "data_vencimento": "2025/12/31",
    "aceite": "N",
    "especie_documento": "DM",
    "instrucao1": "Não receber após o vencimento"
}

# Obter dados do boleto (sem gerar PDF)
response = requests.get(
    "http://localhost:9292/api/boleto/data",
    params={
        "bank": "banco_brasil",
        "data": json.dumps(boleto_data)
    }
)

data = response.json()
print(f"Linha Digitável: {data['linha_digitavel']}")
print(f"Código de Barras: {data['codigo_barras']}")
print(f"Nosso Número: {data['nosso_numero']}")

# Gerar PDF
response = requests.get(
    "http://localhost:9292/api/boleto",
    params={
        "bank": "banco_brasil",
        "type": "pdf",
        "data": json.dumps(boleto_data)
    }
)

with open("boleto.pdf", "wb") as f:
    f.write(response.content)
```

Ver mais exemplos em [`examples/python/`](./examples/python/)

## 🏦 Bancos Suportados

- ✅ Banco do Brasil (001)
- ✅ Sicoob (756)
- ✅ Sicredi
- ✅ Santander
- ✅ Bradesco
- ✅ Itaú
- ✅ Caixa Econômica Federal
- ✅ E mais 9 bancos!

Ver documentação completa de campos em [`docs/fields/README.md`](./docs/fields/README.md)

## 📄 Parsing de Extrato OFX

O endpoint `POST /api/ofx/parse` permite parsear arquivos OFX (extrato bancário) e obter transações em JSON.

```bash
# Enviar arquivo OFX
curl -X POST http://localhost:9292/api/ofx/parse \
  -F "file=@extrato.ofx"

# Filtrar apenas créditos
curl -X POST http://localhost:9292/api/ofx/parse \
  -F "file=@extrato.ofx" \
  -F "somente_creditos=true"
```

**Recursos:**
- Suporta OFX v1 (SGML) e v2 (XML)
- Conversão automática de encoding Latin-1 para UTF-8
- Extração automática de `nosso_numero` do campo memo por banco (Sicoob, Itaú, BB, Bradesco, Caixa)
- Resumo com totais de créditos/débitos

## 🧪 Testes

```bash
# Rodar testes automatizados
bundle exec rspec

# Rodar testes específicos
bundle exec rspec spec/boleto_spec.rb

# Rodar com coverage
bundle exec rspec --format documentation
```

## 📁 Estrutura do Projeto

```
boleto_cnab_api/
├── lib/
│   ├── boleto_api.rb                     # Entry point principal
│   └── boleto_api/                       # Módulos da API (v1.1.0)
│       ├── version.rb                    # Versão da API
│       ├── config/
│       │   └── constants.rb              # Constantes centralizadas
│       ├── services/
│       │   ├── field_mapper.rb           # Mapeamento de campos
│       │   ├── boleto_service.rb         # Lógica de boletos
│       │   ├── remessa_service.rb        # Lógica de remessas
│       │   ├── retorno_service.rb        # Lógica de retornos
│       │   ├── ofx_parser_service.rb     # Parsing de arquivos OFX
│       │   └── nosso_numero_extractor.rb # Extração de nosso_numero
│       ├── endpoints/
│       │   ├── health_endpoint.rb        # GET /api/health
│       │   ├── boleto_endpoint.rb        # /api/boleto/*
│       │   ├── remessa_endpoint.rb       # POST /api/remessa
│       │   ├── retorno_endpoint.rb       # POST /api/retorno
│       │   └── ofx_endpoint.rb           # POST /api/ofx/parse
│       └── middleware/
│           ├── error_handler.rb          # Tratamento de erros
│           └── request_logger.rb         # Logs estruturados
├── config/
│   └── puma.rb                           # Configuração Puma
├── spec/                                 # Testes automatizados
│   ├── boleto_spec.rb
│   ├── all_banks_spec.rb
│   ├── spec_helper.rb
│   ├── fixtures/
│   │   └── sample_data.json
│   └── unit/                             # Testes unitários
│       ├── config/
│       └── services/
├── docs/                                 # Documentação
│   ├── ARCHITECTURE.md                   # Arquitetura da API
│   ├── DEPLOY.md                         # Guia de deploy
│   ├── TODO_INTEGRACAO.md                # Roadmap de integração
│   ├── api/
│   │   └── troubleshooting.md
│   ├── fields/
│   │   ├── README.md
│   │   ├── all-banks.md
│   │   └── examples.md
│   └── development/
│       └── brcobranca-fork.md
├── examples/                             # Exemplos de uso
│   └── python/
├── python-client/                        # Cliente Python oficial
├── scripts/                              # Scripts de automação
├── VERSION                               # Versão atual (1.1.0)
├── CHANGELOG.md                          # Histórico de versões
├── Dockerfile                            # Multi-stage build otimizado
├── docker-compose.yml                    # Orquestração Docker
├── render.yaml                           # Config Render Free Tier
├── Gemfile                               # Dependências Ruby
└── config.ru                             # Configuração Rack
```

## 🐳 Deploy

### Desenvolvimento Local

```bash
# Opção 1: Docker Compose (Mais Fácil)
docker-compose up

# Opção 2: Script Helper
./start.sh

# Opção 3: Docker Direto
docker build -t boleto_cnab_api .
docker run -p 9292:9292 boleto_cnab_api

# Opção 4: Local (sem Docker)
bundle install
bundle exec rackup -p 9292
```

### Render.com (Free Tier) - RECOMENDADO

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

**Ou siga o guia completo:** 📖 **[DEPLOY.md](./DEPLOY.md)**

**Resumo:**
1. Fork este repositório
2. Conecte no [Render.com](https://render.com)
3. New → Web Service → Seu repositório
4. Ambiente: Docker
5. Deploy! 🚀

**Recursos do Free Tier:**
- ✅ 512 MB RAM
- ✅ 100 GB bandwidth/mês
- ✅ Auto-deploy do `main`
- ⚠️ Sleep após 15min inatividade

### Railway / Fly.io

O projeto inclui `Dockerfile` e `render.yaml` para deploy direto em outras plataformas.

## 🎯 Características

### ✅ Recursos Implementados

- 🐍 **Cliente Python oficial** - Interface Pythonic com retry automático e type hints
- 📦 **Instalação via pip** - Pacote Python distribuível e fácil de instalar
- 🔢 **Versionamento semântico** - Sistema MAJOR.MINOR.PATCH com script automático
- 📋 **CHANGELOG completo** - Histórico de todas as versões e mudanças
- 🔄 Mapeamento automático `numero_documento` ↔ `documento_numero`
- 📊 Endpoint `/api/boleto/data` para obter dados sem gerar PDF
- 📝 Documentação completa de campos por banco (6+ bancos)
- ⏱️ Logs estruturados com timestamps e tempo de processamento
- 🧪 Testes automatizados com RSpec (cobertura completa)
- 💡 Exemplos práticos Python com tratamento de erros
- 🗂️ Estrutura de projeto moderna e organizada
- 🔍 Tratamento robusto de erros com hints
- 🐳 Docker Compose para desenvolvimento local
- 🚀 Otimizado para Render Free Tier (512MB RAM)
- 🛡️ Acesso seguro a métodos com `respond_to?` e `rescue`

## 🔧 Tecnologias

**Backend:**
- **Ruby** - Linguagem principal
- **Grape** - Framework para API REST
- **BRCobranca** - Geração de boletos ([maxwbh/brcobranca](https://github.com/Maxwbh/brcobranca))
- **RSpec** - Framework de testes
- **Docker** - Containerização
- **Alpine Linux** - Imagem base otimizada

**Cliente Python:**
- **Python 3.7+** - Compatibilidade moderna
- **Requests** - Cliente HTTP com retry
- **Type Hints** - Tipagem estática
- **Dataclasses** - Modelos de dados estruturados

## 🔢 Versionamento

Este projeto segue [Versionamento Semântico](https://semver.org/) (MAJOR.MINOR.PATCH).

**Versão atual:** `1.1.0` (veja [VERSION](VERSION))

**Histórico:** Veja [CHANGELOG.md](CHANGELOG.md) para todas as mudanças.

### Como incrementar versão

```bash
# Correção de bugs (1.0.0 -> 1.0.1)
./scripts/bump-version.sh patch

# Nova funcionalidade (1.0.1 -> 1.1.0)
./scripts/bump-version.sh minor

# Breaking change (1.1.0 -> 2.0.0)
./scripts/bump-version.sh major
```

Veja [scripts/README.md](scripts/README.md) para mais detalhes.

## 📄 Licença

MIT License - Ver [LICENSE](./LICENSE)

## 🤝 Contribuições

Contribuições são bem-vindas! Sinta-se livre para abrir issues ou pull requests.

## 💬 Suporte

- 📖 [Documentação Completa](./docs/)
- 🐛 [Reportar Bug](https://github.com/Maxwbh/boleto_cnab_api/issues)
- 💡 [Sugerir Melhoria](https://github.com/Maxwbh/boleto_cnab_api/issues)

## 🔗 Links Úteis

**Documentação:**
- [Cliente Python - README](./python-client/README.md)
- [Exemplos Python](./examples/python/README.md)
- [Documentação de Campos por Banco](./docs/fields/README.md)
- [Compatibilidade de Todos os Bancos](./docs/fields/all-banks.md)
- [Guia de Deploy](./DEPLOY.md)
- [Scripts de Versionamento](./scripts/README.md)
- [Troubleshooting](./docs/api/troubleshooting.md)

**Gem BRCobranca:**
- [Repositório GitHub](https://github.com/Maxwbh/brcobranca)
- [Detalhes Técnicos](./docs/development/brcobranca-fork.md)

**Changelog e Versões:**
- [CHANGELOG.md](./CHANGELOG.md)
- [VERSION](./VERSION)

---

**Desenvolvido por Maxwell da Silva Oliveira - M&S do Brasil Ltda**
