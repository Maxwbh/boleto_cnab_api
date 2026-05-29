<p align="center">
  <h1 align="center">Boleto CNAB API</h1>
  <p align="center">
    API REST para geração de boletos bancários, CNAB (remessa/retorno), parsing OFX e PIX híbrido.
    <br />
    <strong>18 bancos</strong> · <strong>15 endpoints</strong> · <strong>172 testes</strong> · <strong>Swagger UI</strong>
    <br /><br />
    <a href="https://boleto-cnab-api.onrender.com/api/docs">Documentação Interativa</a>
    ·
    <a href="https://github.com/Maxwbh/boleto_cnab_api/issues">Reportar Bug</a>
    ·
    <a href="./docs/ROADMAP.md">Roadmap</a>
  </p>
</p>

[![Deploy on Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)
[![Version](https://img.shields.io/badge/version-1.3.0-green)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Ruby](https://img.shields.io/badge/ruby-3.3-red)](https://www.ruby-lang.org)
[![brcobranca](https://img.shields.io/badge/brcobranca-12.8.0-orange)](https://github.com/Maxwbh/brcobranca)

---

## Quick Start

```bash
git clone https://github.com/Maxwbh/boleto_cnab_api.git
cd boleto_cnab_api

# Docker (recomendado)
docker build -t boleto-api .
docker run -p 9292:9292 boleto-api

# Testar
curl http://localhost:9292/api/health
```

Acesse **http://localhost:9292/api/docs** para a documentação interativa (Swagger UI).

## Endpoints

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/api/docs` | GET | Swagger UI interativa |
| `/api/bancos` | GET | 18 bancos com capacidades detalhadas |
| `/api/boleto/data` | GET | Dados do boleto (nosso_numero, código de barras, linha digitável) |
| `/api/boleto` | GET | Gerar boleto PDF. `include_data=true` retorna JSON + PDF base64 |
| `/api/boleto/multi` | POST | Gerar múltiplos boletos em um arquivo |
| `/api/remessa` | POST | Gerar remessa CNAB 240/400. `pix=true` para remessa PIX |
| `/api/retorno` | POST | Processar arquivo de retorno CNAB |
| `/api/ofx/parse` | POST | Parsear extrato bancário OFX |

[Ver todos os 15 endpoints →](./docs/README.md)

## Bancos Suportados

| Banco | Cód | Boleto | CNAB 400 | CNAB 240 | PIX |
|-------|:---:|:------:|:--------:|:--------:|:---:|
| Banco do Brasil | 001 | ✅ | ✅ | ✅ | ✅ |
| Santander | 033 | ✅ | ✅ | ✅ | ✅ |
| Caixa | 104 | ✅ | — | ✅ | ✅ |
| Bradesco | 237 | ✅ | ✅ | — | ✅ |
| **Banco C6** | 336 | ✅ | ✅ | — | ✅ |
| Itaú | 341 | ✅ | ✅ | — | ✅ |
| Sicredi | 748 | ✅ | — | ✅ | ✅ |
| Sicoob | 756 | ✅ | ✅ | ✅ | ✅ |
| + 10 bancos | — | ✅ | — | — | — |

Consulte `GET /api/bancos` para capacidades detalhadas em tempo real.

## Exemplo: Gerar Boleto + Dados (1 chamada)

```python
import requests, json, base64

response = requests.get("http://localhost:9292/api/boleto", params={
    "bank": "sicoob",
    "type": "pdf",
    "include_data": "true",
    "data": json.dumps({
        "agencia": "4327",
        "conta_corrente": "417270",
        "convenio": "229385",
        "carteira": "1",
        "variacao": "01",
        "nosso_numero": "7890",
        "cedente": "Minha Empresa LTDA",
        "documento_cedente": "12345678000100",
        "sacado": "João da Silva",
        "sacado_documento": "12345678900",
        "valor": 2500.00,
        "data_vencimento": "2026/12/31",
        "aceite": "N"
    })
})

data = response.json()
print(f"Nosso Número: {data['nosso_numero']}")
print(f"Formatado:    {data['nosso_numero_formatado']}")
print(f"DV:           {data['nosso_numero_dv']}")
print(f"Código Barras: {data['codigo_barras']}")

# Salvar PDF
with open("boleto.pdf", "wb") as f:
    f.write(base64.b64decode(data["content_base64"]))
```

## Funcionalidades

| Recurso | Descrição |
|---------|-----------|
| **Boletos** | PDF, JPG, PNG, TIF para 18 bancos. Template Prawn (sem GhostScript) disponível via `template=prawn` |
| **Remessa CNAB** | Geração de arquivos CNAB 240/400/444. Remessa PIX com `pix=true` |
| **Retorno CNAB** | Parsing de arquivos de retorno com detecção automática de formato |
| **PIX Híbrido** | Boleto com QR Code PIX embutido. Campos `emv`, `chave_pix`, `tipo_chave_pix`, `txid` |
| **OFX** | Parsing de extrato bancário com extração de nosso_numero por banco |
| **include_data** | PDF + todos os dados do boleto em uma única chamada (base64) |
| **Swagger UI** | Documentação interativa em `/api/docs` |
| **OpenAPI 3.0** | Spec consumível por Postman, Insomnia e geradores de SDK |

## Deploy

```bash
# Docker padrão (com GhostScript — suporta PDF, JPG, PNG, TIF)
docker build -t boleto-api .

# Docker Prawn (sem GhostScript — apenas PDF, imagem ~70MB menor)
docker build -f Dockerfile.prawn -t boleto-api-prawn .
```

### Render.com

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

O projeto inclui `render.yaml` com configuração pronta para o free tier. [Guia completo →](./DEPLOY.md)

## Tecnologias

| Componente | Tecnologia |
|-----------|-----------|
| API | Ruby 3.3 + Grape |
| Boletos | [brcobranca](https://github.com/Maxwbh/brcobranca) v12.8.0 |
| PDF | RGhost (GhostScript) ou Prawn (Ruby puro) |
| OFX | gem `ofx` |
| Servidor | Puma |
| Testes | RSpec (172 testes) |
| Container | Docker (Alpine) |
| Docs | OpenAPI 3.0 + Swagger UI |

## Documentação

| Recurso | Link |
|---------|------|
| Swagger UI | [`/api/docs`](https://boleto-cnab-api.onrender.com/api/docs) |
| Arquitetura | [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) |
| Campos por Banco | [docs/fields/all-banks.md](./docs/fields/all-banks.md) |
| Nosso Número | [docs/fields/nosso-numero.md](./docs/fields/nosso-numero.md) |
| PIX Híbrido | [docs/api/pix.md](./docs/api/pix.md) |
| OFX Parsing | [docs/api/ofx-parsing.md](./docs/api/ofx-parsing.md) |
| Troubleshooting | [docs/api/troubleshooting.md](./docs/api/troubleshooting.md) |
| Roadmap | [docs/ROADMAP.md](./docs/ROADMAP.md) |
| Cliente Python | [python-client/README.md](./python-client/README.md) |

## Licença

MIT — [LICENSE](./LICENSE)

---

<p align="center">
  Desenvolvido por <strong>Maxwell da Silva Oliveira</strong> — <a href="https://github.com/maxwbh">@maxwbh</a> — M&S do Brasil LTDA
</p>
