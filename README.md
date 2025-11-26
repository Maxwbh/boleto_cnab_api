# Boleto CNAB API

> API REST para geração de Boletos, Remessas e processamento de Retornos bancários usando [BRCobranca](https://github.com/kivanio/brcobranca)

**Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) - M&S do Brasil Ltda

[![Deploy on Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

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

### Guias Completos

📖 **[Documentação de Campos](./docs/fields/README.md)** - Todos os campos aceitos por banco (BB, Sicoob, etc.)

💡 **[Exemplos Práticos](./docs/fields/examples.md)** - Exemplos de código Python/Ruby com máximo de campos

🔧 **[Troubleshooting](./docs/api/troubleshooting.md)** - Solução de problemas comuns

⚙️ **[Fork BRCobranca](./docs/development/brcobranca-fork.md)** - Detalhes técnicos do fork utilizado

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
│   └── boleto_api.rb          # Código principal da API
├── spec/                       # Testes automatizados
│   ├── boleto_spec.rb
│   ├── spec_helper.rb
│   └── fixtures/
│       └── sample_data.json
├── docs/                       # Documentação
│   ├── api/
│   │   └── troubleshooting.md
│   ├── fields/
│   │   ├── README.md          # Guia de campos por banco
│   │   └── examples.md        # Exemplos práticos
│   └── development/
│       └── brcobranca-fork.md
├── examples/                   # Exemplos de uso
│   └── python/
│       └── generate_boleto.py
├── README.md                   # Este arquivo
├── Dockerfile                  # Configuração Docker
├── Gemfile                     # Dependências Ruby
└── config.ru                   # Configuração Rack
```

## 🐳 Deploy

### Render.com (Free Tier)

1. Faça fork deste repositório
2. Conecte sua conta no [Render.com](https://render.com)
3. Crie novo Web Service apontando para o fork
4. Configure: `Docker` como environment
5. Deploy automático! 🎉

### Railway / Fly.io

O projeto inclui configuração para deploy direto. Consulte [`render.yaml`](./render.yaml).

## 🔄 Este é um Fork

Este projeto é um **fork** do excelente [akretion/boleto_cnab_api](https://github.com/akretion/boleto_cnab_api) pela [Akretion](http://www.akretion.com).

### Melhorias Implementadas

- ✅ Fork atualizado [maxwbh/brcobranca](https://github.com/maxwbh/brcobranca)
- ✅ Endpoint `/api/boleto/data` para obter dados sem gerar PDF
- ✅ Documentação completa de campos por banco
- ✅ Mapeamento automático `numero_documento` ↔ `documento_numero`
- ✅ Logs estruturados com timestamps e tempo de processamento
- ✅ Testes automatizados com RSpec
- ✅ Exemplos práticos Python/Ruby
- ✅ Estrutura de projeto moderna e organizada

## 📄 Licença

MIT License - Ver [LICENSE](./LICENSE)

O código continua **completamente LIVRE** e disponível sob os mesmos termos do projeto original.

## 🤝 Contribuições

Contribuições são bem-vindas! Sinta-se livre para abrir issues ou pull requests.

## 💬 Suporte

- 📖 [Documentação Completa](./docs/)
- 🐛 [Reportar Bug](https://github.com/Maxwbh/boleto_cnab_api/issues)
- 💡 [Sugerir Melhoria](https://github.com/Maxwbh/boleto_cnab_api/issues)

---

**Desenvolvido com ❤️ pela comunidade Ruby brasileira**
