# Guia de Deploy - Render Free Tier

> Como fazer deploy da API no Render.com usando o plano gratuito

## 🚀 Deploy Rápido (1-Click)

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

**OU** siga o passo a passo abaixo:

---

## 📋 Pré-requisitos

1. Conta no [Render.com](https://render.com) (gratuita)
2. Repositório no GitHub com este código
3. 5 minutos do seu tempo ⏱️

---

## 🔧 Passo a Passo

### 1. Preparar Repositório

Certifique-se de que seu repositório tem:
- ✅ `Dockerfile` (já incluído)
- ✅ `render.yaml` (já incluído)
- ✅ `Gemfile` (já incluído)

```bash
# Verificar arquivos
ls Dockerfile render.yaml Gemfile

# Se estiver tudo ok, fazer push
git add .
git commit -m "Deploy para Render"
git push origin main
```

### 2. Criar Serviço no Render

1. Acesse [dashboard.render.com](https://dashboard.render.com)
2. Clique em **"New +"** → **"Web Service"**
3. Conecte seu repositório GitHub
4. Configure:

```yaml
Name: boleto-cnab-api
Environment: Docker
Region: Oregon (ou Frankfurt/Singapore)
Plan: Free
```

5. Clique em **"Create Web Service"**

### 3. Aguardar Deploy

O Render irá:
1. ✅ Clonar o repositório
2. ✅ Ler o `render.yaml`
3. ✅ Fazer build do `Dockerfile`
4. ✅ Executar a aplicação
5. ✅ Fornecer URL pública

**Tempo estimado:** 3-5 minutos

---

## ✅ Verificar Deploy

Após o deploy, você terá uma URL como:

```
https://boleto-cnab-api.onrender.com
```

**Testar:**

```bash
# Health check
curl https://boleto-cnab-api.onrender.com/api/health

# Deve retornar:
{"status":"OK"}
```

---

## 🔧 Configurações do Free Tier

### Recursos Incluídos (Grátis)

| Recurso | Limite |
|---------|--------|
| RAM | 512 MB |
| CPU | Compartilhado |
| Build Time | 500 minutos/mês |
| Bandwidth | 100 GB/mês |
| Deploy | Ilimitados |

### ⚠️ Importante: Sleep Mode

**O plano gratuito entra em "sleep" após 15 minutos de inatividade.**

**Comportamento:**
- ✅ Primeira requisição: ~30-60s (wake-up)
- ✅ Próximas requisições: Normal (~200-500ms)
- ✅ Após 15min sem uso: Sleep novamente

**Soluções:**

1. **Aceitar o comportamento** (recomendado para testes)
2. **Usar ping service** (ex: UptimeRobot, cron-job.org)
3. **Upgrade para plano pago** ($7/mês - sem sleep)

---

## 🔄 Deploy Automático

O `render.yaml` já está configurado com `autoDeploy: true`.

**Isso significa:**
- ✅ Push para `main` → Deploy automático
- ✅ Pull Request merged → Deploy automático
- ✅ Não precisa fazer nada manual

**Desabilitar auto-deploy:**

```yaml
# render.yaml
autoDeploy: false
```

---

## 🌍 Regiões Disponíveis

Escolha a região mais próxima dos seus usuários:

| Região | Localização | Latência Brasil |
|--------|-------------|-----------------|
| `oregon` | EUA (Oeste) | ~200ms |
| `ohio` | EUA (Leste) | ~150ms |
| `frankfurt` | Alemanha | ~250ms |
| `singapore` | Singapura | ~350ms |

**Alterar região:** Edite `render.yaml` e faça commit.

---

## 📊 Monitoramento

### Logs em Tempo Real

```bash
# Via Dashboard
Dashboard → Seu Service → Logs (tab)

# Via CLI (opcional)
render logs -f
```

### Métricas

O Render fornece automaticamente:
- ✅ CPU usage
- ✅ Memory usage
- ✅ Request count
- ✅ Response times

**Acesso:** Dashboard → Seu Service → Metrics

---

## 🔐 Variáveis de Ambiente

### Já Configuradas no `render.yaml`:

```yaml
- PORT=9292
- RACK_ENV=production
- PUMA_WORKERS=1
- PUMA_MAX_THREADS=5
- MALLOC_ARENA_MAX=2
```

### Adicionar Novas:

**Via Dashboard:**
1. Service → Environment
2. Add Environment Variable
3. Key: `MINHA_VAR`
4. Value: `meu_valor`
5. Save Changes (faz redeploy)

**Via render.yaml:**

```yaml
envVars:
  - key: MINHA_VAR
    value: meu_valor
```

---

## 🐛 Troubleshooting

### Deploy Falhou

```bash
# Ver logs completos
Dashboard → Deploy Logs

# Causas comuns:
1. Dockerfile com erro
2. Dependências faltando
3. Gem incompatível
```

### Serviço Lento

```bash
# Verificar se está em sleep
curl https://sua-url.onrender.com/api/health

# Primeira requisição ~30-60s = Normal (wake-up)
# Se sempre lento, verificar:
- Logs de erro
- Memory usage (dashboard)
```

### Out of Memory (OOM)

```bash
# Free tier: 512MB RAM
# Se estourar, otimize:

1. Reduzir PUMA_MAX_THREADS (render.yaml)
2. Usar MALLOC_ARENA_MAX=2 (já configurado)
3. Considerar upgrade para Starter ($7/mês, 2GB RAM)
```

---

## 💰 Upgrade para Plano Pago

### Starter Plan ($7/mês)

**Benefícios:**
- ✅ **2GB RAM** (4x mais)
- ✅ **Sem sleep mode** (sempre ativo)
- ✅ Mais CPU
- ✅ Deploy mais rápido

**Quando fazer upgrade:**
- Produção real
- Requisitos de SLA
- Tráfego constante
- Performance crítica

**Como fazer:**
```
Dashboard → Service → Settings → Plan → Starter
```

---

## 📚 Documentação Oficial

- [Render Docs](https://render.com/docs)
- [Docker Deploys](https://render.com/docs/docker)
- [render.yaml Reference](https://render.com/docs/yaml-spec)

---

## 🔗 URLs Úteis

Após deploy, você terá:

```bash
# URL pública
https://boleto-cnab-api.onrender.com

# Endpoints
https://boleto-cnab-api.onrender.com/api/health
https://boleto-cnab-api.onrender.com/api/boleto
https://boleto-cnab-api.onrender.com/api/boleto/data

# Dashboard
https://dashboard.render.com/web/[seu-service-id]
```

---

## ✅ Checklist de Deploy

Antes de fazer deploy, verifique:

- [ ] `Dockerfile` presente e testado localmente
- [ ] `render.yaml` com configurações corretas
- [ ] `Gemfile` atualizado
- [ ] Código commitado e pushed para `main`
- [ ] Testes passando (`bundle exec rspec`)
- [ ] Health check funcionando (`/api/health`)

**Pronto!** Agora é só criar o service no Render! 🚀

---

**Desenvolvido por Maxwell da Silva Oliveira - M&S do Brasil Ltda**
