# Análise do Fork maxwbh/brcobranca

## 🔍 Problema Identificado

Há uma **inconsistência crítica** no nome do campo de documento entre diferentes versões do brcobranca.

### Campo Correto na Gem BRCobranca

De acordo com a documentação oficial da gem brcobranca (classe Base):

**Nome do campo na gem:** `documento_numero`

**Descrição:** "OPCIONAL: Número de pedido, Nota fiscal ou documento que originou o boleto."

### Campo Usado nesta API

**Nome do campo na API:** `numero_documento`

### ⚠️ Inconsistência Detectada

```ruby
# Na gem brcobranca (CORRETO):
attr_accessor :documento_numero

# Nesta API estamos usando (INCONSISTENTE):
numero_documento: boleto.numero_documento
```

## 📊 Histórico de Mudanças no Fork

### Commits Relevantes no maxwbh/brcobranca:

1. **November 24, 2025** - Correção de nomenclatura
   - Documentado que o campo correto é `documento_numero`
   - Identificado como erro comum: usar `numero_documento`
   - Causa NoMethodError se usar nome errado

2. **November 25, 2025** - Fix para Sicoob (Bank 756)
   - Ajuste no campo `aceite` padrão para 'N'
   - Correção de campos removidos incorretamente

3. **Problemas reportados:**
   - "type is missing" - parâmetro obrigatório faltando
   - Campos vazios no PDF - falta de `documento_numero`

## 🔧 Problema no Código Atual

### No arquivo `lib/boleto_api.rb:105`

```ruby
{
  banco: params[:bank],
  nosso_numero: boleto.nosso_numero_boleto,
  # ...
  numero_documento: boleto.numero_documento,  # ❌ ERRADO!
  # ...
}
```

**Deveria ser:**
```ruby
numero_documento: boleto.documento_numero,  # ✅ CORRETO!
```

## 🎯 Campos Afetados

A API está tentando acessar `boleto.numero_documento`, mas o método correto é `boleto.documento_numero`.

### Onde o erro aparece:

1. **GET /api/boleto/data** (linha 105)
   - Retorna dados do boleto
   - Tenta acessar `numero_documento` (campo inexistente)

2. **Documentação**
   - Exemplos usam `numero_documento`
   - Deveria usar `documento_numero`

3. **Testes**
   - URLs de exemplo usam `numero_documento`
   - Gem espera `documento_numero`

## ⚡ Impacto

### Comportamento Atual:
- API recebe `numero_documento` nos dados de entrada ✅
- BRCobranca converte para objeto boleto ✅
- Ao acessar `boleto.numero_documento` → **NoMethodError** ❌
- Campo retorna `nil` ou causa erro

### Comportamento Esperado:
- API recebe dados com qualquer nome
- BRCobranca usa internamente `documento_numero`
- API acessa `boleto.documento_numero` ✅
- Campo retorna valor correto

## 🔍 Verificação Necessária

Precisamos verificar:

1. ✅ Qual nome de campo a gem brcobranca aceita na entrada?
   - Resposta: Aceita ambos mas internamente usa `documento_numero`

2. ✅ Qual método accessor está disponível no objeto boleto?
   - Resposta: `documento_numero` (não `numero_documento`)

3. ❌ Nossa API está usando o accessor correto?
   - Resposta: NÃO! Estamos usando `numero_documento`

## 📝 Correção Necessária

### Arquivo: lib/boleto_api.rb

**Linha 105** - Endpoint /api/boleto/data:
```ruby
# ANTES (ERRADO):
numero_documento: boleto.numero_documento,

# DEPOIS (CORRETO):
numero_documento: boleto.documento_numero,
```

### Observação Importante:

O campo na **entrada** pode continuar como `numero_documento` (para compatibilidade com usuários da API).

O campo na **saída** deve acessar o método correto: `documento_numero`.

## 🎯 Testes Recomendados

Após correção, testar:

```python
# 1. Enviar boleto com documento_numero
boleto_data = {
    "documento_numero": "NF-12345",  # Nome interno da gem
    # ... outros campos
}

# 2. Enviar boleto com numero_documento (compatibilidade)
boleto_data = {
    "numero_documento": "NF-12345",  # Nome usado na API
    # ... outros campos
}

# 3. Verificar resposta do endpoint /data
response = requests.get(f"{API_URL}/api/boleto/data", ...)
assert response.json()["numero_documento"] == "NF-12345"
```

## 📚 Referências

- [BRCobranca Base Class](https://www.rubydoc.info/gems/brcobranca/Brcobranca/Boleto/Base)
- [Fork maxwbh/brcobranca](https://github.com/maxwbh/brcobranca)
- [Banco 756 API Fix](https://github.com/maxwbh/brcobranca/blob/master/BANCO_756_API_FIX.md)

---

**Data da Análise:** 2025-11-25
**Analisado por:** Claude Code
**Mantido por:** Maxwell da Silva Oliveira (@maxwbh)
