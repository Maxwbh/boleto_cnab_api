<p align="center">
  <img src="https://img.shields.io/badge/🏦_Boleto_CNAB_API-v1.3.3-blue?style=for-the-badge" alt="Boleto CNAB API" />
</p>

<h3 align="center">
  API REST open-source para boletos bancários brasileiros, CNAB e PIX
</h3>

<p align="center">
  Gere boletos, remessas CNAB e processe extratos OFX para <strong>18 bancos brasileiros</strong> com uma única API.
  <br />
  Integre em qualquer linguagem — Python, Node.js, PHP, Java, Go — via HTTP.
  <br /><br />
  <a href="https://boleto-cnab-api.onrender.com/api/docs"><strong>🔗 Documentação Interativa (Swagger) →</strong></a>
  <br /><br />
  <a href="https://boleto-cnab-api.onrender.com/api/docs">Demo ao Vivo</a>
  ·
  <a href="#quick-start">Quick Start</a>
  ·
  <a href="./docs/ROADMAP.md">Roadmap</a>
  ·
  <a href="https://github.com/Maxwbh/boleto_cnab_api/issues">Reportar Bug</a>
</p>

<p align="center">
  <a href="https://render.com/deploy"><img src="https://render.com/images/deploy-to-render-button.svg" alt="Deploy to Render" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.3.3-green" alt="Version" />
  <img src="https://img.shields.io/badge/bancos-18-blue" alt="Bancos" />
  <img src="https://img.shields.io/badge/testes-172_passando-brightgreen" alt="Tests" />
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License" />
  <img src="https://img.shields.io/badge/ruby-3.3-red" alt="Ruby" />
  <img src="https://img.shields.io/badge/brcobranca-12.10.1-orange" alt="brcobranca" />
  <img src="https://img.shields.io/badge/PIX-8_bancos-blueviolet" alt="PIX" />
</p>

---

## Por que usar?

Se você precisa **gerar boletos**, **processar arquivos CNAB** ou **conciliar pagamentos via OFX** no Brasil, esta API resolve tudo via HTTP — sem precisar instalar gems Ruby no seu sistema.

| Problema | Solução |
|----------|---------|
| "Preciso gerar boletos em Python/Node/PHP" | API REST — chame de qualquer linguagem |
| "Preciso de CNAB 240/400 para enviar ao banco" | `POST /api/remessa` gera o arquivo pronto |
| "Preciso processar o retorno do banco" | `POST /api/retorno` parseia e retorna JSON |
| "Preciso conciliar pagamentos com extrato" | `POST /api/ofx/parse` extrai nosso_numero do OFX |
| "Preciso de boleto com QR Code PIX" | Campo `emv` no payload + `pix=true` na remessa |
| "Não quero instalar GhostScript" | `template=prawn` gera PDF em Ruby puro |
| "Preciso saber quais bancos/formatos são suportados" | `GET /api/bancos` retorna tudo dinamicamente |

### Diferenciais

- **18 bancos** — Incluindo Banco C6 (336), o mais completo do mercado open-source
- **PIX nativo** — Boleto híbrido com QR Code + remessa CNAB com segmento PIX
- **2 templates PDF** — RGhost (completo) ou Prawn (sem GhostScript, 92% menor)
- **Swagger UI** — Documentação interativa em `/api/docs`, teste no browser
- **OpenAPI 3.0** — Importe no Postman/Insomnia em 1 clique
- **include_data** — PDF + dados do boleto em 1 chamada (base64)
- **Docker ready** — Deploy em 1 minuto no Render, Railway ou qualquer cloud
- **217 testes** — Cobertura real com todos os bancos validados

---

## Quick Start

```bash
git clone https://github.com/Maxwbh/boleto_cnab_api.git && cd boleto_cnab_api

# Docker
docker build -t boleto-api . && docker run -p 9292:9292 boleto-api

# Swagger UI
open http://localhost:9292/api/docs
```

### Gerar boleto (1 chamada = PDF + dados)

```bash
curl "http://localhost:9292/api/boleto?bank=banco_brasil&type=pdf&include_data=true&data=$(python3 -c "
import json; print(json.dumps({
    'agencia': '3073', 'conta_corrente': '12345678', 'convenio': '01234567',
    'carteira': '18', 'nosso_numero': '123', 'cedente': 'Empresa LTDA',
    'documento_cedente': '12345678000100', 'sacado': 'Joao da Silva',
    'sacado_documento': '12345678900', 'valor': 1500.0,
    'data_vencimento': '2026/12/31', 'aceite': 'N'
}))"
)" | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
print(f'Nosso Numero: {data[\"nosso_numero\"]}')
print(f'Formatado:    {data[\"nosso_numero_formatado\"]}')
print(f'Cod. Barras:  {data[\"codigo_barras\"]}')
with open('boleto.pdf', 'wb') as f:
    f.write(base64.b64decode(data['content_base64']))
print('PDF salvo: boleto.pdf')
"
```

---

## Endpoints

| Endpoint | Método | O que faz |
|----------|:------:|-----------|
| **`/api/docs`** | GET | Swagger UI interativa |
| **`/api/bancos`** | GET | 18 bancos com capacidades (boleto, CNAB, PIX, carteiras) |
| `/api/boleto/data` | GET | Dados calculados: nosso_numero, código barras, linha digitável |
| `/api/boleto` | GET | Gerar PDF/JPG/PNG/TIF. `include_data=true` → JSON + base64 |
| `/api/boleto/multi` | POST | Múltiplos boletos em 1 arquivo |
| `/api/remessa` | POST | Remessa CNAB 240/400. `pix=true` → com segmento PIX |
| `/api/retorno` | POST | Processar retorno CNAB → JSON |
| `/api/ofx/parse` | POST | Extrato OFX → JSON com nosso_numero extraído |

<details>
<summary>Ver todos os 15 endpoints</summary>

| Endpoint | Método | Descrição |
|----------|:------:|-----------|
| `/api/health` | GET | Health check |
| `/api/info` | GET | Versão e configuração |
| `/api/metadata` | GET | Metadados da API e gem |
| `/api/bancos` | GET | Capacidades por banco |
| `/api/boleto/validate` | GET | Validar dados do boleto |
| `/api/boleto/data` | GET | Dados calculados |
| `/api/boleto/nosso_numero` | GET | Apenas nosso_numero |
| `/api/boleto` | GET | Gerar boleto (PDF/JPG/PNG/TIF) |
| `/api/boleto/multi` | POST | Múltiplos boletos |
| `/api/remessa` | POST | Remessa CNAB |
| `/api/retorno` | POST | Retorno CNAB |
| `/api/ofx/parse` | POST | Parsing OFX |
| `/api/docs` | GET | Swagger UI |
| `/api/openapi.json` | GET | Spec OpenAPI (JSON) |
| `/api/openapi.yaml` | GET | Spec OpenAPI (YAML) |

</details>

---

## Bancos Suportados

| Banco | Cód | Boleto | Remessa | Retorno | PIX |
|-------|:---:|:------:|:-------:|:-------:|:---:|
| Banco do Brasil | 001 | ✅ | 400 + 240 | 400 | ✅ |
| Santander | 033 | ✅ | 400 + 240 | 400 + 240 | ✅ |
| Caixa | 104 | ✅ | 240 | 240 | ✅ |
| Bradesco | 237 | ✅ | 400 | 400 | ✅ |
| **Banco C6** | **336** | ✅ | 400 | 400 | ✅ |
| Itaú | 341 | ✅ | 400 + 444 | 400 | ✅ |
| Sicredi | 748 | ✅ | 240 | 240 | ✅ |
| Sicoob | 756 | ✅ | 400 + 240 | 240 | ✅ |
| Banrisul | 041 | ✅ | 400 | 400 | — |
| Unicred | 136 | ✅ | 400 + 240 | 400 | — |
| + 8 bancos | — | ✅ | — | — | — |

> Use `GET /api/bancos` para capacidades completas em tempo real, incluindo carteiras aceitas e formatos PIX.

---

## Exemplo: Python

```python
import requests, json, base64

API = "http://localhost:9292"

# 1. Gerar boleto com dados + PDF
response = requests.get(f"{API}/api/boleto", params={
    "bank": "sicoob", "type": "pdf", "include_data": "true",
    "data": json.dumps({
        "agencia": "4327", "conta_corrente": "417270",
        "convenio": "229385", "carteira": "1", "variacao": "01",
        "nosso_numero": "7890", "cedente": "Empresa LTDA",
        "documento_cedente": "12345678000100",
        "sacado": "João da Silva", "sacado_documento": "12345678900",
        "valor": 2500.00, "data_vencimento": "2026/12/31", "aceite": "N"
    })
})
data = response.json()
with open("boleto.pdf", "wb") as f:
    f.write(base64.b64decode(data["content_base64"]))

# 2. Parsear extrato OFX
with open("extrato.ofx", "rb") as f:
    ofx = requests.post(f"{API}/api/ofx/parse", files={"file": f}).json()
for tx in ofx["transacoes"]:
    if tx["nosso_numero_extraido"]:
        print(f"{tx['data']} R$ {tx['valor']} nn={tx['nosso_numero_extraido']}")
```

---

## Deploy

| Opção | Comando |
|-------|---------|
| **Docker** | `docker build -t boleto-api . && docker run -p 9292:9292 boleto-api` |
| **Docker (sem GhostScript)** | `docker build -f Dockerfile.prawn -t boleto-api .` |
| **Docker Compose** | `docker compose up` |
| **Render.com** | [![Deploy](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy) |
| **Local** | `bundle install && bundle exec rackup -p 9292` |

> 🐳 **Imagem otimizada para o Render Free Tier (512MB):** jemalloc (`LD_PRELOAD`)
> para baixa fragmentação de memória em Alpine/musl, `tini` para shutdown
> gracioso e tuning de GC do Ruby. Detalhes em [DEPLOY.md](./DEPLOY.md).

---

## Stack

| Componente | Tecnologia |
|-----------|-----------|
| API | Ruby 3.3 · Grape · Puma |
| Boletos | [brcobranca v12.10.1](https://github.com/Maxwbh/brcobranca) (fork com C6, PIX, Prawn) |
| PDF | RGhost ou Prawn (sem GhostScript) |
| OFX | gem `ofx` |
| Testes | RSpec · 217 testes |
| Docs | OpenAPI 3.0 · Swagger UI |
| Container | Docker · Alpine Linux |

---

## Documentação

| O que | Onde |
|-------|------|
| **Testar a API agora** | [Swagger UI (demo ao vivo)](https://boleto-cnab-api.onrender.com/api/docs) |
| Importar no Postman | [`/api/openapi.json`](https://boleto-cnab-api.onrender.com/api/openapi.json) |
| Campos por banco | [docs/fields/all-banks.md](./docs/fields/all-banks.md) |
| Nosso número (entrada/saída/conciliação) | [docs/fields/nosso-numero.md](./docs/fields/nosso-numero.md) |
| PIX híbrido + Remessa PIX | [docs/api/pix.md](./docs/api/pix.md) |
| Parsing OFX | [docs/api/ofx-parsing.md](./docs/api/ofx-parsing.md) |
| Troubleshooting | [docs/api/troubleshooting.md](./docs/api/troubleshooting.md) |
| Arquitetura | [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) |
| Roadmap v1.4 | [docs/ROADMAP.md](./docs/ROADMAP.md) |
| Cliente Python | [python-client/README.md](./python-client/README.md) |
| Deploy | [DEPLOY.md](./DEPLOY.md) |

---

## Contribuindo

Contribuições são bem-vindas! Veja o [guia de contribuição](./CONTRIBUTING.md).

```bash
# Setup
git clone https://github.com/Maxwbh/boleto_cnab_api.git && cd boleto_cnab_api
bundle install

# Testes
bundle exec rspec

# Servidor local
bundle exec rackup -p 9292
```

## Licença

[MIT](./LICENSE) — use livremente em projetos comerciais e open-source.

---

<p align="center">
  Desenvolvido por <strong><a href="https://github.com/maxwbh">Maxwell da Silva Oliveira</a></strong>
  <br />
  <a href="https://github.com/maxwbh">@maxwbh</a> · M&S do Brasil LTDA
  <br /><br />
  ⭐ Se este projeto foi útil, considere dar uma estrela!
</p>
