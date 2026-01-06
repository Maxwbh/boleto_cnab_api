# Guia de Deploy - Render.com Free Tier

> **Versão:** 1.1.0 | **Atualizado:** 2026-01-06

Este guia explica como fazer deploy da Boleto CNAB API no Render.com usando o plano gratuito.

## Requisitos da v1.1.0

- Docker multi-stage build (~150MB)
- Integração com brcobranca v12.5+ (fork @maxwbh)
- Otimizado para 512MB RAM

## Pré-requisitos

- Conta no [Render.com](https://render.com)
- Repositório no GitHub: `https://github.com/Maxwbh/boleto_cnab_api`

## Deploy Automático (Recomendado)

### 1. Conectar Repositório

1. Acesse [dashboard.render.com](https://dashboard.render.com)
2. Clique em **New +** → **Web Service**
3. Conecte sua conta GitHub
4. Selecione o repositório `Maxwbh/boleto_cnab_api`

### 2. Configuração Automática

O Render detectará automaticamente o arquivo `render.yaml` e configurará:

- **Tipo**: Docker
- **Plano**: Free
- **Região**: Oregon (US West)
- **Health Check**: `/api/health`
- **Deploy Automático**: Ativado

### 3. Variáveis de Ambiente

As seguintes variáveis são configuradas automaticamente:

| Variável | Valor | Descrição |
|----------|-------|-----------|
| `PORT` | 9292 | Porta da aplicação |
| `RACK_ENV` | production | Ambiente |
| `PUMA_WORKERS` | 1 | Workers do Puma |
| `PUMA_MIN_THREADS` | 0 | Threads mínimas |
| `PUMA_MAX_THREADS` | 5 | Threads máximas |
| `MALLOC_ARENA_MAX` | 2 | Otimização de memória |

### 4. Aguardar Build

O primeiro build pode levar 5-10 minutos. Acompanhe em **Logs**.

## Deploy Manual (Alternativo)

Se preferir configurar manualmente:

### 1. Criar Web Service

1. **New +** → **Web Service**
2. **Environment**: Docker
3. **Dockerfile Path**: `./Dockerfile`
4. **Plan**: Free

### 2. Configurar Variáveis

Adicione as variáveis listadas acima em **Environment**.

### 3. Configurar Health Check

- **Path**: `/api/health`
- **Timeout**: 30s

## Limitações do Free Tier

| Recurso | Limite |
|---------|--------|
| Memória RAM | 512 MB |
| CPU | Compartilhada |
| Banda | 100 GB/mês |
| Build Minutes | 500/mês |
| Sleep | Após 15 min inativo |

### Spin-up Time

Após inatividade, a primeira requisição pode levar 30-60 segundos enquanto o container é iniciado.

**Dica**: Use um serviço de uptime monitoring (ex: UptimeRobot) para manter o serviço ativo.

## Endpoints Disponíveis

Após o deploy, sua API estará disponível em:

```
https://boleto-cnab-api.onrender.com
```

### Testar Health

```bash
curl https://boleto-cnab-api.onrender.com/api/health
```

Resposta esperada:
```json
{"status":"OK","timestamp":"2024-01-15T10:30:00Z"}
```

### Testar Geração de Boleto

```bash
curl -G "https://boleto-cnab-api.onrender.com/api/boleto/validate" \
  --data-urlencode 'bank=banco_brasil' \
  --data-urlencode 'data={"valor":100.0,"cedente":"Empresa LTDA","documento_cedente":"12345678000199","sacado":"Cliente","sacado_documento":"12345678901","agencia":"1234","conta_corrente":"12345","convenio":"123456","nosso_numero":"12345678"}'
```

## Monitoramento

### Logs

Acesse os logs em tempo real:

1. Dashboard → Seu serviço → **Logs**

### Métricas

Visualize uso de CPU/Memória em:

1. Dashboard → Seu serviço → **Metrics**

## Troubleshooting

### Erro: Out of Memory

Se o container reiniciar por falta de memória:

1. Verifique se `PUMA_WORKERS=1`
2. Reduza `PUMA_MAX_THREADS` para 3
3. Adicione `MALLOC_ARENA_MAX=2`

### Erro: Build Failed

1. Verifique os logs de build
2. Certifique-se que `Gemfile.lock` está atualizado
3. Verifique se todas as gems são compatíveis com Alpine Linux

### Erro: Health Check Failed

1. Verifique se a porta está correta (9292)
2. Aumente o timeout do health check para 60s
3. Verifique logs para erros de inicialização

## Upgrade para Plano Pago

Para remover limitações:

1. Dashboard → Seu serviço → **Settings**
2. **Change Plan** → Starter ($7/mês)

Benefícios do plano pago:
- Sem sleep após inatividade
- Mais CPU e memória
- SSL customizado
- Melhor suporte

## Links Úteis

- [Documentação Render](https://render.com/docs)
- [Status Render](https://status.render.com)
- [Repositório API](https://github.com/Maxwbh/boleto_cnab_api)
- [Repositório brcobranca](https://github.com/Maxwbh/brcobranca)

---

**Mantenedor**: Maxwell Oliveira (@maxwbh)
**Empresa**: M&S do Brasil LTDA
**Website**: [www.msbrasil.inf.br](https://www.msbrasil.inf.br)
