# Sobre o projeto boleto_cnab_api

> **Mantido por:** Maxwell da Silva Oliveira ([@maxwbh](https://github.com/maxwbh)) - M&S do Brasil Ltda

## 🔄 Este é um FORK do projeto original

Este repositório é um **fork** do excelente projeto [akretion/boleto_cnab_api](https://github.com/akretion/boleto_cnab_api), criado e mantido pela [Akretion](http://www.akretion.com).

### 🎯 Objetivo deste Fork

As melhorias e modificações implementadas neste fork visam **atender necessidades específicas** enfrentadas em projetos particulares da **M&S do Brasil Ltda**, incluindo:

- ✅ Utilização do fork atualizado [maxwbh/brcobranca](https://github.com/maxwbh/brcobranca)
- ✅ Documentação detalhada de campos por banco
- ✅ Novos endpoints para retornar dados do boleto sem gerar PDF/imagem
- ✅ Otimizações para deploy em plataformas free tier (Render, Railway, etc)
- ✅ Exemplos práticos de integração em Python
- ✅ Melhorias na documentação e usabilidade

### 📜 Licença e Disponibilidade

**O código continua completamente LIVRE e disponível** sob os mesmos termos do projeto original. Todas as melhorias são open-source e podem ser utilizadas, modificadas e distribuídas livremente.

Encorajamos contribuições da comunidade e estamos abertos a pull requests que melhorem o projeto!

---

### 🏛️ Projeto Original

O projeto original de gestão de Boletos, Remessas e Retornos Bancários [BRCobranca](https://github.com/kivanio/brcobranca) é muito bem feito, bem testado e mantido pela comunidade Ruby brasileira.

É interessante poder usar o projeto BRCobranca (escrito em Ruby) a partir de outras linguagens na forma de um micro-serviço REST. A [Akretion](http://www.akretion.com), empresa que lidera a localização do Odoo no Brasil desde 2009 ([OCA/l10n-brazil](https://github.com/OCA/l10n-brazil)) e co-criou a fundação [OCA](https://odoo-community.org/), usa esse projeto para gerenciar Boletos, Remessas e Retornos a partir do ERP Odoo (módulo específico: [l10n_br_account_payment_brcobranca](https://github.com/OCA/l10n-brazil/tree/14.0/l10n_br_account_payment_brcobranca)).

A imagem usada no projeto é do OS [Alpine](https://hub.docker.com/_/alpine), o motivo é que por ser um Micro-Serviço quanto menor a imagem melhor e apesar de existir dentro das imagens [Ruby](https://hub.docker.com/_/ruby) tanto a opção Debian quanto Alpine a imagem criada a partir da versão "pura" acaba sendo menor( Ruby-Debian 746MB | Ruby-Alpine 565MB | Alpine 523MB ), existem diferenças entre o [Debian](https://pt.wikipedia.org/wiki/Debian) e o [Alpine](https://pt.wikipedia.org/wiki/Alpine_Linux) basicamente "na superfície" são alguns nomes de pacote e o instalador de pacotes, no Debian apt-get e no Alpine apk, outros comandos Linux são iguais, em caso de algum erro complexo o Debian pode acabar sendo usado.

# Funcionalidades

Imprime **Boletos**, gera arquivos de **Remessa** e lê os arquivos de **Retorno** nos formatos CNAB 240, CNAB 400 para os 16 principais bancos do Brasil (Banco do Brasil, Banco do Nordeste, Banestes, Santander, Banrisul, Banco de Brasília, Caixa, Bradesco, Itaú, HSBC, Sicredi, Sicoob, AILOS, Unicred, CREDISIS e Citibank). Mas o grande barato desse projeto é que fazemos isso com menos de 200 linhas de código! Já comparou quantas linhas de de código você tem que manter sozinho ou quase se for re-fazer na linguagem que você quer tudo que o BRCobranca já faz? Seriam dezenas de milhares de linhas e você nunca teria uma qualidade tão boa...

# API

## Endpoints de Boleto

### Validar os dados de um Boleto
```ruby
GET /api/boleto/validate
  requires :bank, type: String, desc: 'Bank name'
  requires :data, type: String, desc: 'Boleto data as a stringified json'
```
Valida se todos os campos obrigatórios estão presentes e corretos.

### Obter todos os dados do Boleto (SEM gerar PDF/imagem) - **NOVO**
```ruby
GET /api/boleto/data
  requires :bank, type: String, desc: 'Bank name'
  requires :data, type: String, desc: 'Boleto data as a stringified json'
```
Retorna todos os dados importantes do boleto incluindo:
- `codigo_barras` - Código de barras completo
- `linha_digitavel` - Linha digitável para pagamento
- `nosso_numero` - Nosso número completo com DV
- `agencia_conta_boleto` - Agência e conta formatadas
- Todos os dados do boleto (valor, datas, cedente, sacado, etc)

**Este endpoint é mais leve e rápido** pois não gera o PDF/imagem, apenas retorna os dados essenciais.

### Obter o nosso_numero de um Boleto
```ruby
GET /api/boleto/nosso_numero
  requires :bank, type: String, desc: 'Bank name'
  requires :data, type: String, desc: 'Boleto data as a stringified json'
```
Retorna o nosso_numero com DV, código de barras, linha digitável e agência/conta.

### Imprimir um Boleto apenas
```ruby
GET /api/boleto
  requires :bank, type: String, desc: 'Bank name'
  requires :type, type: String, desc: 'Type: pdf|jpg|png|tif'
  requires :data, type: String, desc: 'Boleto data as a stringified json'
```

### Imprimir uma lista de Boletos
```ruby
POST /api/boleto/multi
  requires :type, type: String, desc: 'Type: pdf|jpg|png|tif'
  requires :data, type: File, desc: 'json of the list of boletos, including the "bank" key'
```

## Endpoints de Remessa

### Gerar arquivo de Remessa CNAB 240 ou CNAB 400
```ruby
POST /api/remessa
  requires :bank, type: String, desc: 'Bank name'
  requires :type, type: String, desc: 'Type: cnab400|cnab240'
  requires :data, type: File, desc: 'json of the list of pagamentos'
```

## Endpoints de Retorno

### Transformar arquivo de Retorno CNAB em JSON
```ruby
POST /api/retorno
  requires :bank, type: String, desc: 'Bank name'
  requires :type, type: String, desc: 'Type: cnab400|cnab240'
  requires :data, type: File, desc: 'txt of the retorno file'
```

## Health Check
```ruby
GET /api/health
```
Retorna `{status: 'OK'}` se o serviço está funcionando.

---

## Bancos Suportados

**16 principais bancos brasileiros:**
- Banco do Brasil (001)
- Banco do Nordeste (004)
- Banestes (021)
- Santander (033)
- Banrisul (041)
- Banco de Brasília - BRB (070)
- AILOS (085)
- CREDISIS (097)
- Caixa Econômica Federal (104)
- Unicred (136)
- Bradesco (237)
- Itaú (341)
- HSBC (399)
- Citibank (745)
- Sicredi (748)
- Sicoob (756)

## Documentação de Campos

**📖 Para informações detalhadas sobre os campos necessários para cada banco, consulte:**

[**CAMPOS_BOLETOS_POR_BANCO.md**](./CAMPOS_BOLETOS_POR_BANCO.md)

Este documento contém:
- Campos obrigatórios por banco
- Campos opcionais
- Validações específicas (tamanho de agência, conta, convênio, etc)
- Exemplos de valores válidos
- Campos calculados automaticamente

## 🔧 Troubleshooting

**Encontrou problemas ao usar a API? Consulte o guia de troubleshooting:**

[**TROUBLESHOOTING_API.md**](./TROUBLESHOOTING_API.md)

Este guia contém:
- Como resolver o erro "type is missing"
- Explicação dos logs melhorados da API
- Como debugar boletos com campos vazios
- Diferença entre `nosso_numero` e `numero_documento`
- Checklist completo para debug
- Exemplos de código correto

---

**Nota importante:** Os campos de datas devem estar no formato `YYYY/MM/DD`

O API está documentado com mais detalhes no código aqui: [lib/boleto_api.rb](./lib/boleto_api.rb)

# Como rodar o micro-serviço

## Localmente com Docker

```bash
docker run -p 9292:9292 ghcr.io/akretion/boleto_cnab_api
```

## Deploy no Render (Free Tier)

Este projeto está otimizado para rodar no [Render](https://render.com) free tier. Para fazer o deploy:

### Via Dockerfile (Recomendado)
1. Crie um novo **Web Service** no Render
2. Conecte seu repositório GitHub
3. Configure:
   - **Environment**: Docker
   - **Region**: Escolha a mais próxima (Oregon ou Frankfurt)
   - **Branch**: `main` ou sua branch preferida
   - **Instance Type**: Free

O Render automaticamente detectará o Dockerfile e fará o build.

### Configurações Importantes para Free Tier

#### 1. Health Check Endpoint
O Render usa o endpoint `/api/health` para verificar se o serviço está funcionando:
```bash
curl https://seu-app.onrender.com/api/health
# Retorna: {"status":"OK"}
```

#### 2. Inatividade (Spin Down)
No plano free, o Render coloca o serviço em modo sleep após 15 minutos de inatividade.
- **Primeira requisição após sleep**: ~30-60 segundos para "acordar"
- **Requisições subsequentes**: milissegundos

#### 3. Otimizações Implementadas
- ✅ Imagem Alpine Linux (menor tamanho = deploy mais rápido)
- ✅ Health check endpoint para monitoring
- ✅ Puma como servidor web (leve e eficiente)
- ✅ Build otimizado com cache de dependências

#### 4. Limites do Free Tier
- 750 horas/mês de runtime (suficiente para 1 serviço 24/7)
- 15 minutos de inatividade antes de entrar em sleep
- Banda: 100 GB/mês
- Build: 500 horas/mês

### Variáveis de Ambiente (Opcionais)

Você pode configurar as seguintes variáveis no Render:

```bash
PORT=9292                    # Porta padrão (não mudar)
RACK_ENV=production         # Ambiente de execução
PUMA_WORKERS=1              # Número de workers (free tier: 1)
PUMA_MIN_THREADS=0          # Threads mínimas
PUMA_MAX_THREADS=5          # Threads máximas (ajuste conforme uso)
```

### Exemplo de render.yaml

Se preferir usar Infrastructure as Code, crie um arquivo `render.yaml` na raiz do projeto:

```yaml
services:
  - type: web
    name: boleto-cnab-api
    env: docker
    region: oregon
    plan: free
    healthCheckPath: /api/health
    envVars:
      - key: PORT
        value: 9292
      - key: RACK_ENV
        value: production
```

# Exemplos de como consumir o serviço usando sua linguagem preferida:

## Bash

Por exemplo, para imprimir uma lista de Boletos é preciso criar um arquivo temporario com os Boletos em formato JSON e depois fazer um POST do arquivo:
```bash
echo '[{"valor":5.0,"cedente":"Kivanio Barbosa","documento_cedente":"12345678912","sacado":"Claudio Pozzebom",
"sacado_documento":"12345678900","agencia":"0810","conta_corrente":"53678","convenio":12387,"nosso_numero":"12345678","bank":"itau"},
{"valor": 10.00,"cedente": "PREFEITURA MUNICIPAL DE VILHENA","documento_cedente": "04092706000181","sacado": "João Paulo Barbosa",
"sacado_documento": "77777777777","agencia": "1825","conta_corrente": "0000528","convenio": "245274","nosso_numero": "000000000000001","bank":"caixa"}]'\
> /tmp/boletos_data.json
curl -X POST -F type=pdf -F 'data=@/tmp/boletos_data.json' localhost:9292/api/boleto/multi > /tmp/boletos.pdf
```
Você pode então conferir os Boletos gerados no arquivo ```/tmp/boletos.pdf```

## Python

### Exemplo 1: Gerar Boleto Sicoob em PDF

```python
import requests
import json

# URL da API (ajuste conforme seu ambiente)
API_URL = "http://localhost:9292/api"
# Para produção no Render: API_URL = "https://seu-app.onrender.com/api"

# Dados do boleto Sicoob
boleto_data = {
    "valor": 150.50,
    "cedente": "M&S do Brasil Ltda",
    "documento_cedente": "12345678000190",
    "sacado": "João da Silva",
    "sacado_documento": "12345678901",
    "agencia": "4327",
    "conta_corrente": "417270",
    "carteira": "1",
    "variacao": "01",  # Modalidade da carteira
    "convenio": "229385",
    "nosso_numero": "1234567",
    "numero_documento": "1234567",
    "data_documento": "2025/11/24",
    "data_vencimento": "2025/12/24",
    "data_processamento": "2025/11/24",
    "instrucao1": "Não receber após o vencimento",
    "instrucao2": "Juros de mora de 2% ao mês",
    "sacado_endereco": "Rua Exemplo, 123 - Centro",
}

# Converter para JSON string
data_json = json.dumps(boleto_data)

# Fazer requisição GET para gerar PDF
response = requests.get(
    f"{API_URL}/boleto",
    params={
        "bank": "sicoob",
        "type": "pdf",
        "data": data_json
    }
)

if response.status_code == 200:
    # Salvar o PDF
    with open("boleto_sicoob.pdf", "wb") as f:
        f.write(response.content)
    print("✅ Boleto gerado com sucesso: boleto_sicoob.pdf")
else:
    print(f"❌ Erro ao gerar boleto: {response.status_code}")
    print(response.json())
```

### Exemplo 2: Obter Dados do Boleto Sicoob (sem gerar PDF)

```python
import requests
import json

API_URL = "http://localhost:9292/api"

boleto_data = {
    "valor": 150.50,
    "cedente": "M&S do Brasil Ltda",
    "documento_cedente": "12345678000190",
    "sacado": "João da Silva",
    "sacado_documento": "12345678901",
    "agencia": "4327",
    "conta_corrente": "417270",
    "carteira": "1",
    "variacao": "01",
    "convenio": "229385",
    "nosso_numero": "1234567",
    "data_vencimento": "2025/12/24",
}

data_json = json.dumps(boleto_data)

# Usar o novo endpoint /boleto/data (mais rápido, não gera PDF)
response = requests.get(
    f"{API_URL}/boleto/data",
    params={
        "bank": "sicoob",
        "data": data_json
    }
)

if response.status_code == 200:
    dados = response.json()
    print("✅ Dados do boleto obtidos com sucesso!\n")
    print(f"🏦 Banco: {dados['bank']}")
    print(f"📄 Nosso Número: {dados['nosso_numero']}")
    print(f"🔢 Código de Barras: {dados['codigo_barras']}")
    print(f"💳 Linha Digitável: {dados['linha_digitavel']}")
    print(f"🏢 Agência/Conta: {dados['agencia_conta_boleto']}")
    print(f"💰 Valor: R$ {dados['valor']}")
    print(f"📅 Vencimento: {dados['data_vencimento']}")
else:
    print(f"❌ Erro: {response.status_code}")
    print(response.json())
```

### Exemplo 3: Validar Dados do Boleto Sicoob

```python
import requests
import json

API_URL = "http://localhost:9292/api"

# Dados com erro proposital (faltando campo obrigatório)
boleto_data = {
    "valor": 150.50,
    "cedente": "M&S do Brasil Ltda",
    # "documento_cedente": "12345678000190",  # Campo obrigatório comentado
    "sacado": "João da Silva",
    "sacado_documento": "12345678901",
    "agencia": "4327",
    "conta_corrente": "417270",
}

data_json = json.dumps(boleto_data)

# Validar antes de gerar
response = requests.get(
    f"{API_URL}/boleto/validate",
    params={
        "bank": "sicoob",
        "data": data_json
    }
)

if response.status_code == 200:
    print("✅ Dados válidos!")
else:
    print(f"❌ Dados inválidos:")
    erros = response.json()
    for campo, mensagens in erros.items():
        print(f"  • {campo}: {', '.join(mensagens)}")
```

### Exemplo 4: Gerar Múltiplos Boletos Sicoob

```python
import requests
import json

API_URL = "http://localhost:9292/api"

# Lista de boletos
boletos = [
    {
        "bank": "sicoob",  # Importante: incluir o banco em cada boleto
        "valor": 100.00,
        "cedente": "M&S do Brasil Ltda",
        "documento_cedente": "12345678000190",
        "sacado": "Cliente 1",
        "sacado_documento": "11111111111",
        "agencia": "4327",
        "conta_corrente": "417270",
        "carteira": "1",
        "variacao": "01",
        "convenio": "229385",
        "nosso_numero": "1000001",
        "data_vencimento": "2025/12/24",
    },
    {
        "bank": "sicoob",
        "valor": 200.00,
        "cedente": "M&S do Brasil Ltda",
        "documento_cedente": "12345678000190",
        "sacado": "Cliente 2",
        "sacado_documento": "22222222222",
        "agencia": "4327",
        "conta_corrente": "417270",
        "carteira": "1",
        "variacao": "01",
        "convenio": "229385",
        "nosso_numero": "1000002",
        "data_vencimento": "2025/12/24",
    },
]

# Criar arquivo JSON temporário
with open("/tmp/boletos_sicoob.json", "w") as f:
    json.dump(boletos, f)

# Fazer POST com arquivo
with open("/tmp/boletos_sicoob.json", "rb") as f:
    response = requests.post(
        f"{API_URL}/boleto/multi",
        data={"type": "pdf"},
        files={"data": f}
    )

if response.status_code == 200:
    with open("boletos_sicoob_multiplos.pdf", "wb") as f:
        f.write(response.content)
    print("✅ Boletos gerados com sucesso: boletos_sicoob_multiplos.pdf")
else:
    print(f"❌ Erro: {response.status_code}")
    print(response.json())
```

### Exemplo 5: Classe Helper para Boletos Sicoob

```python
import requests
import json
from typing import Dict, Optional, List
from datetime import datetime, timedelta

class BoletoSicoobAPI:
    """Helper para geração de boletos Sicoob via API"""

    def __init__(self, api_url: str = "http://localhost:9292/api"):
        self.api_url = api_url
        self.bank = "sicoob"

    def gerar_boleto_pdf(self, dados: Dict) -> bytes:
        """Gera boleto em PDF e retorna o conteúdo"""
        data_json = json.dumps(dados)
        response = requests.get(
            f"{self.api_url}/boleto",
            params={"bank": self.bank, "type": "pdf", "data": data_json}
        )
        response.raise_for_status()
        return response.content

    def obter_dados_boleto(self, dados: Dict) -> Dict:
        """Obtém dados do boleto sem gerar PDF"""
        data_json = json.dumps(dados)
        response = requests.get(
            f"{self.api_url}/boleto/data",
            params={"bank": self.bank, "data": data_json}
        )
        response.raise_for_status()
        return response.json()

    def validar_boleto(self, dados: Dict) -> bool:
        """Valida dados do boleto"""
        data_json = json.dumps(dados)
        response = requests.get(
            f"{self.api_url}/boleto/validate",
            params={"bank": self.bank, "data": data_json}
        )
        return response.status_code == 200

    def criar_dados_boleto(
        self,
        valor: float,
        sacado_nome: str,
        sacado_cpf: str,
        nosso_numero: str,
        agencia: str = "4327",
        conta_corrente: str = "417270",
        convenio: str = "229385",
        cedente: str = "M&S do Brasil Ltda",
        documento_cedente: str = "12345678000190",
        dias_vencimento: int = 30,
        **kwargs
    ) -> Dict:
        """Cria estrutura de dados para boleto Sicoob"""
        hoje = datetime.now()
        vencimento = hoje + timedelta(days=dias_vencimento)

        dados = {
            "valor": valor,
            "cedente": cedente,
            "documento_cedente": documento_cedente,
            "sacado": sacado_nome,
            "sacado_documento": sacado_cpf,
            "agencia": agencia,
            "conta_corrente": conta_corrente,
            "carteira": "1",
            "variacao": "01",
            "convenio": convenio,
            "nosso_numero": nosso_numero,
            "numero_documento": nosso_numero,
            "data_documento": hoje.strftime("%Y/%m/%d"),
            "data_vencimento": vencimento.strftime("%Y/%m/%d"),
            "data_processamento": hoje.strftime("%Y/%m/%d"),
        }

        # Adicionar campos extras
        dados.update(kwargs)
        return dados

# Exemplo de uso da classe
if __name__ == "__main__":
    api = BoletoSicoobAPI()

    # Criar dados do boleto
    boleto = api.criar_dados_boleto(
        valor=150.50,
        sacado_nome="João da Silva",
        sacado_cpf="12345678901",
        nosso_numero="1234567",
        instrucao1="Não receber após o vencimento",
        instrucao2="Juros de 2% ao mês"
    )

    # Validar
    if api.validar_boleto(boleto):
        print("✅ Boleto válido!")

        # Obter dados (sem PDF)
        dados = api.obter_dados_boleto(boleto)
        print(f"📄 Linha Digitável: {dados['linha_digitavel']}")

        # Gerar PDF
        pdf_content = api.gerar_boleto_pdf(boleto)
        with open("boleto.pdf", "wb") as f:
            f.write(pdf_content)
        print("✅ PDF gerado: boleto.pdf")
    else:
        print("❌ Boleto inválido!")
```

### 📚 Campos Específicos do Sicoob

Para detalhes completos sobre campos obrigatórios, opcionais e validações do Sicoob, consulte:
[CAMPOS_BOLETOS_POR_BANCO.md - Seção Sicoob](./CAMPOS_BOLETOS_POR_BANCO.md#7-sicoob-756)

**Campos importantes do Sicoob:**
- `agencia`: máximo 4 dígitos
- `conta_corrente`: máximo 8 dígitos
- `nosso_numero`: máximo 7 dígitos
- `convenio`: máximo 7 dígitos
- `variacao`: modalidade da carteira (padrão: '01')
- `carteira`: padrão '1'

### 🔧 Troubleshooting - Campos Vazios no Boleto PDF

Se o PDF do boleto for gerado mas apresentar **linha digitável**, **código de barras** ou **nosso número vazios**, verifique:

#### Para TODOS os bancos:
1. ✅ O campo `nosso_numero` está sendo informado corretamente
2. ✅ O campo `data_vencimento` está no formato correto (`YYYY/MM/DD`)
3. ✅ O campo `valor` foi informado (mesmo que seja 0.0)
4. ✅ Todos os campos obrigatórios do banco estão preenchidos
5. ✅ Use o endpoint `/api/boleto/validate` para verificar se há erros de validação

#### Para Banco do Brasil:
- Verifique se o `convenio` tem o número correto de dígitos (4, 6, 7 ou 8)
- Verifique se o `nosso_numero` tem o tamanho compatível com o convênio
- O campo `numero_documento` é **opcional** e NÃO afeta código de barras

#### Para Sicoob:
- Verifique se os campos `convenio` e `variacao` estão corretos
- O `nosso_numero` deve ter no máximo 7 dígitos
- O campo `numero_documento` é **opcional** e NÃO afeta código de barras

#### Diferença importante:
- **`nosso_numero`**: Obrigatório, faz parte do código de barras
- **`numero_documento`**: Opcional, apenas para controle interno (NF, pedido, etc)

**Exemplo de validação antes de gerar o PDF:**

```python
import requests
import json

API_URL = "http://localhost:9292/api"

boleto_data = {
    "valor": 100.00,
    "cedente": "Empresa LTDA",
    "documento_cedente": "12345678000190",
    "sacado": "Cliente",
    "sacado_documento": "12345678901",
    "agencia": "4327",
    "conta_corrente": "417270",
    "convenio": "229385",
    "nosso_numero": "1234567",  # OBRIGATÓRIO
    "numero_documento": "NF-12345",  # OPCIONAL
    "data_vencimento": "2025/12/31",
}

# Validar ANTES de gerar PDF
response = requests.get(
    f"{API_URL}/boleto/validate",
    params={"bank": "sicoob", "data": json.dumps(boleto_data)}
)

if response.status_code == 200:
    print("✅ Dados válidos! Pode gerar o PDF.")
else:
    print("❌ Dados inválidos:")
    print(response.json())
```

---

Para outros exemplos de integração com Odoo, veja: [l10n_br_account_payment_brcobranca](https://github.com/OCA/l10n-brazil/tree/14.0/l10n_br_account_payment_brcobranca)

## Java

```
TODO (contribuições bem vindas)
```

## Testar alterações na imagem sem necessidade de commit

No arquivo Gemfile.lock é possível alterar o repositório e o commit específico que será usado na criação da imagem, o que é necessário durante uma correção, atualização ou implementação de um novo caso, um exemplo simples pode ser visto nesse PR https://github.com/akretion/boleto_cnab_api/pull/11/files , mas também é possível alterar o Dockerfile para criar uma imagem de teste onde seja possível editar os arquivos dentro do container (o que evita subir um commit desnecessário ou com erro), para isso no arquivo Dockerfile são feitas as seguintes alterações:

Instalar algum editor de texto, por exemplo VIM ou Nano (por padrão o VI já está instalado mas caracteres UTF-8 não são mostrados corretamente) e alterar o usuário **app** para o **root** para poder editar os arquivos
```bash
            git \
            ruby-dev \
+           vim \
+           nano \
         && rm -rf /var/cache/apk/* \
         ;

-USER app
+USER root
```

Criação da imagem
```bash
$ docker build -t akretion/boleto_cnab_api-teste .
```

Depois de iniciar a imagem podemos entrar dentro do container
```bash
Localizar o container ID

$ docker ps
CONTAINER ID   IMAGE                             COMMAND                  CREATED             STATUS             PORTS                                                 NAMES
1ea95da3a3c3   akretion/boleto_cnab_api-teste   "/bin/sh -c 'bundle …"   4 minutes ago   Up 4 minutes   0.0.0.0:9292->9292/tcp, :::9292->9292/tcp   eloquent_noether
```

Acessando o container (No Debian usa /bin/bash no Alpine /bin/sh)
```bash
$ docker exec -it <container-id> /bin/sh

O valor <container-id> varia, nesse exemplo o comando seria

$ docker exec -it 1ea95da3a3c3 /bin/sh
```

Dentro do container é preciso localizar a pasta onde está instalada a biblioteca, no exemplo é usado o comando **find** e a partir disso é possível realizar alterações necessárias
```bash
/usr/src/app # find /usr -name unicred.rb
/usr/lib/ruby/gems/3.3.0/bundler/gems/brcobranca-cd928e87554b/lib/brcobranca/retorno/cnab400/unicred.rb
/usr/lib/ruby/gems/3.3.0/bundler/gems/brcobranca-cd928e87554b/lib/brcobranca/remessa/cnab240/unicred.rb
/usr/lib/ruby/gems/3.3.0/bundler/gems/brcobranca-cd928e87554b/lib/brcobranca/remessa/cnab400/unicred.rb
```

A partir disso é possível realizar alterações necessárias, por exemplo verificar o valor de alguma variável "imprimindo" no LOG com o comando "puts" (algumas referencias https://www.dotnetperls.com/console-ruby https://www.rubyguides.com/2018/10/puts-vs-print/ http://ruby-for-beginners.rubymonstas.org/writing_methods/printing.html )
```bash
/usr/src/app # vim /usr/lib/ruby/gems/3.3.0/bundler/gems/brcobranca-cd928e87554b/lib/brcobranca/
boleto/unicred.rb

      def codigo_barras_segunda_parte
        puts "TESTE puts algum valor qualquer " + "#{agencia}"
        "#{agencia}#{conta_corrente}#{conta_corrente_dv}#{nosso_numero}#{nosso_numero_dv}"
      end
    end
```

Nesse exemplo ao criar um Boleto do UNICRED é possível ver no LOG o resultado do "puts"
```bash
$ docker logs -f 28f2881e4dd7
Puma starting in single mode...
* Puma version: 6.4.2 (ruby 3.3.3-p89) ("The Eagle of Durango")
*  Min threads: 0
*  Max threads: 5
*  Environment: development
*          PID: 1
* Listening on http://0.0.0.0:9292
Use Ctrl-C to stop
TESTE puts algum valor qualquer 1234
```

Se a imagem estiver sendo iniciada dentro de um **Docker Compose**, por exemplo por um projeto Odoo é possível ver o LOG usando:
```bash
$ docker logs -f 28f2881e4dd7
Puma starting in single mode...
* Puma version: 6.4.2 (ruby 3.3.3-p89) ("The Eagle of Durango")
*  Min threads: 0
*  Max threads: 5
*  Environment: development
*          PID: 1
* Listening on http://0.0.0.0:9292
Use Ctrl-C to stop
- Gracefully stopping, waiting for requests to finish
=== puma shutdown: 2024-07-05 19:50:05 +0000 ===
- Goodbye!
```

**IMPORTANTE:** por algum motivo as alterações dentro do container só tem efeito na primeira vez que o arquivo é Salvo, uma segunda alteração não tem efeito, isso pode ser algo referente ao comportamento da imagem, ou do Docker ou do Docker Compose, já que nos testes realizados esse container é iniciado e usado por outro container rodando o Odoo, é preciso investigar melhor para entender se isso é algo normal e já esperado ou se teria uma forma de corrigir, porque devido a isso para testar dessa forma está sendo necessário alterar uma vez e se for preciso fazer outra alteração sair do container fazer um kill e inicia-lo novamente.
