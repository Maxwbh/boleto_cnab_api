# Exemplos com Máximo de Campos Possíveis

## 🎯 Objetivo

Demonstrar como enviar o MÁXIMO de informações possíveis para a API, garantindo:
1. ✅ Boletos mais completos e profissionais
2. ✅ Melhor rastreabilidade
3. ✅ Conformidade com requisitos bancários
4. ✅ Nenhum campo importante esquecido

---

## 🏦 Exemplo Completo - Sicoob (756)

### Python - Payload Completo Recomendado

```python
import requests
import json
from datetime import datetime, timedelta

API_URL = "http://localhost:9292/api"
# Para produção: API_URL = "https://brcobranca-api.onrender.com/api"

# Data de hoje e vencimento
hoje = datetime.now()
vencimento = hoje + timedelta(days=30)

boleto_sicoob_completo = {
    # ============================================
    # DADOS BANCÁRIOS (OBRIGATÓRIOS)
    # ============================================
    "agencia": "4327",
    "conta_corrente": "417270",
    "carteira": "1",
    "variacao": "01",           # Modalidade da carteira
    "convenio": "229385",
    "nosso_numero": "1234567",

    # ============================================
    # DADOS DO BOLETO (OBRIGATÓRIOS)
    # ============================================
    "valor": 1500.50,
    "data_vencimento": vencimento.strftime("%Y/%m/%d"),
    "data_documento": hoje.strftime("%Y/%m/%d"),
    "data_processamento": hoje.strftime("%Y/%m/%d"),

    # ============================================
    # CONFIGURAÇÕES DO BOLETO
    # ============================================
    "aceite": "N",              # ⚠️ Sicoob usa 'N'!
    "especie_documento": "DM",  # Duplicata Mercantil
    "especie": "R$",
    "moeda": "9",
    "quantidade": "001",

    # ============================================
    # DADOS DO BENEFICIÁRIO (CEDENTE)
    # ============================================
    "cedente": "M&S do Brasil Ltda",
    "documento_cedente": "12345678000190",
    "cedente_endereco": "Rua Exemplo, 1234 - Sala 101 - Centro - São Paulo/SP - CEP: 01000-000",

    # ============================================
    # DADOS DO PAGADOR (SACADO) - OBRIGATÓRIOS
    # ============================================
    "sacado": "João da Silva Santos",
    "sacado_documento": "12345678901",
    "sacado_endereco": "Av. Paulista, 1000 - Apto 501 - Bela Vista - São Paulo/SP - CEP: 01310-100",

    # ============================================
    # DADOS DO AVALISTA (SE HOUVER)
    # ============================================
    "avalista": "Maria Santos Silva",
    "avalista_documento": "98765432100",

    # ============================================
    # NÚMERO DO DOCUMENTO (RECOMENDADO!)
    # ============================================
    "documento_numero": "NF-2025-001234",  # ✅ SEMPRE ENVIAR para rastreabilidade

    # ============================================
    # INSTRUÇÕES PARA O CAIXA/BANCO
    # ============================================
    "instrucao1": "Não receber após o vencimento",
    "instrucao2": "Multa de 2% após o vencimento",
    "instrucao3": "Juros de mora de 1% ao mês",
    "instrucao4": "Desconto de R$ 50,00 até 5 dias antes do vencimento",
    "instrucao5": "Em caso de dúvidas, ligar para (11) 1234-5678",
    "instrucao6": "Pagamento ref. contrato 2025/1234",
    "instrucao7": "Emitido eletronicamente via API BRCobranca",

    # ============================================
    # INFORMAÇÕES ADICIONAIS
    # ============================================
    "demonstrativo": "Referente a prestação de serviços de consultoria conforme contrato 2025/1234",
    "local_pagamento": "PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO",

    # ============================================
    # DESCONTOS/ABATIMENTOS (SE APLICÁVEL)
    # ============================================
    "descontos_e_abatimentos": "Desconto de R$ 50,00 para pagamento antecipado",
}

# Gerar PDF do boleto
response = requests.get(
    f"{API_URL}/boleto",
    params={
        "bank": "sicoob",
        "type": "pdf",
        "data": json.dumps(boleto_sicoob_completo)
    }
)

if response.status_code == 200:
    with open("boleto_sicoob_completo.pdf", "wb") as f:
        f.write(response.content)
    print("✅ Boleto completo gerado: boleto_sicoob_completo.pdf")
else:
    print(f"❌ Erro: {response.status_code}")
    print(response.json())
```

---

## 🏦 Exemplo Completo - Banco do Brasil (001)

### Python - Payload Completo Recomendado

```python
import requests
import json
from datetime import datetime, timedelta

API_URL = "http://localhost:9292/api"

# Data de hoje e vencimento
hoje = datetime.now()
vencimento = hoje + timedelta(days=30)

boleto_bb_completo = {
    # ============================================
    # DADOS BANCÁRIOS (OBRIGATÓRIOS)
    # ============================================
    "agencia": "4042",
    "conta_corrente": "61900",
    "carteira": "18",           # Ou '16', '17'
    "convenio": "12387989",     # 8 dígitos
    "nosso_numero": "777700168",
    "codigo_servico": False,    # Booleano

    # ============================================
    # DADOS DO BOLETO (OBRIGATÓRIOS)
    # ============================================
    "valor": 2500.00,
    "data_vencimento": vencimento.strftime("%Y/%m/%d"),
    "data_documento": hoje.strftime("%Y/%m/%d"),
    "data_processamento": hoje.strftime("%Y/%m/%d"),

    # ============================================
    # CONFIGURAÇÕES DO BOLETO
    # ============================================
    "aceite": "S",              # BB geralmente usa 'S'
    "especie_documento": "DM",  # Duplicata Mercantil
    "especie": "R$",
    "moeda": "9",
    "quantidade": 1,

    # ============================================
    # DADOS DO BENEFICIÁRIO (CEDENTE)
    # ============================================
    "cedente": "Empresa XYZ Comércio e Serviços Ltda",
    "documento_cedente": "98765432000100",
    "cedente_endereco": "Rua Comercial, 500 - Conj 202 - Jardins - São Paulo/SP - CEP: 01400-000",

    # ============================================
    # DADOS DO PAGADOR (SACADO)
    # ============================================
    "sacado": "Carlos Eduardo Oliveira",
    "sacado_documento": "11122233344",
    "sacado_endereco": "Rua das Flores, 123 - Casa 2 - Vila Nova - Campinas/SP - CEP: 13000-000",

    # ============================================
    # DADOS DO AVALISTA (SE HOUVER)
    # ============================================
    "avalista": "Ana Paula Oliveira",
    "avalista_documento": "55566677788",

    # ============================================
    # NÚMERO DO DOCUMENTO (RECOMENDADO!)
    # ============================================
    "documento_numero": "PED-2025-5678",  # ✅ Número do pedido/NF

    # ============================================
    # INSTRUÇÕES PARA O CAIXA/BANCO
    # ============================================
    "instrucao1": "Protestar após 10 dias do vencimento",
    "instrucao2": "Não receber após 60 dias do vencimento",
    "instrucao3": "Multa de 2% após vencimento",
    "instrucao4": "Juros de 0,033% ao dia (1% ao mês)",
    "instrucao5": "Desconto de R$ 100,00 até 7 dias antes do vencimento",
    "instrucao6": "Ref. Pedido #5678 - Lote de Produtos XYZ",
    "instrucao7": "Dúvidas: sac@empresaxyz.com.br ou (11) 9999-8888",

    # ============================================
    # INFORMAÇÕES ADICIONAIS
    # ============================================
    "demonstrativo": "Fornecimento de materiais conforme pedido #5678 - Data de entrega: 15/12/2025",
    "local_pagamento": "PAGÁVEL EM QUALQUER BANCO.",
    "descontos_e_abatimentos": "Desconto de R$ 100,00 para pagamento até 7 dias antes",
}

# Gerar PDF do boleto
response = requests.get(
    f"{API_URL}/boleto",
    params={
        "bank": "banco_brasil",  # Ou "bb"
        "type": "pdf",
        "data": json.dumps(boleto_bb_completo)
    }
)

if response.status_code == 200:
    with open("boleto_bb_completo.pdf", "wb") as f:
        f.write(response.content)
    print("✅ Boleto completo gerado: boleto_bb_completo.pdf")
else:
    print(f"❌ Erro: {response.status_code}")
    print(response.json())
```

---

## 🔧 Classe Helper Python - Geração Completa de Boletos

```python
from typing import Dict, Optional, List
from datetime import datetime, timedelta
import requests
import json

class BoletoCompleto:
    """Helper para gerar boletos com MÁXIMO de informações"""

    def __init__(self, api_url: str = "http://localhost:9292/api"):
        self.api_url = api_url

    def dados_completos_sicoob(
        self,
        # Dados obrigatórios
        agencia: str,
        conta_corrente: str,
        convenio: str,
        nosso_numero: str,
        valor: float,
        cedente: str,
        documento_cedente: str,
        sacado: str,
        sacado_documento: str,
        # Dados opcionais mas RECOMENDADOS
        documento_numero: Optional[str] = None,
        sacado_endereco: Optional[str] = None,
        cedente_endereco: Optional[str] = None,
        # Avalista (se houver)
        avalista: Optional[str] = None,
        avalista_documento: Optional[str] = None,
        # Instruções
        instrucoes: Optional[List[str]] = None,
        demonstrativo: Optional[str] = None,
        descontos_e_abatimentos: Optional[str] = None,
        # Configurações
        dias_vencimento: int = 30,
        carteira: str = "1",
        variacao: str = "01",
    ) -> Dict:
        """Cria payload COMPLETO para Sicoob"""

        hoje = datetime.now()
        vencimento = hoje + timedelta(days=dias_vencimento)

        dados = {
            # Dados bancários
            "agencia": agencia,
            "conta_corrente": conta_corrente,
            "carteira": carteira,
            "variacao": variacao,
            "convenio": convenio,
            "nosso_numero": nosso_numero,

            # Dados do boleto
            "valor": valor,
            "data_vencimento": vencimento.strftime("%Y/%m/%d"),
            "data_documento": hoje.strftime("%Y/%m/%d"),
            "data_processamento": hoje.strftime("%Y/%m/%d"),

            # Configurações
            "aceite": "N",  # Sicoob usa 'N'
            "especie_documento": "DM",
            "especie": "R$",
            "moeda": "9",
            "quantidade": "001",
            "local_pagamento": "PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO",

            # Beneficiário
            "cedente": cedente,
            "documento_cedente": documento_cedente,

            # Pagador
            "sacado": sacado,
            "sacado_documento": sacado_documento,
        }

        # Adicionar campos opcionais SE FORNECIDOS
        if documento_numero:
            dados["documento_numero"] = documento_numero

        if sacado_endereco:
            dados["sacado_endereco"] = sacado_endereco

        if cedente_endereco:
            dados["cedente_endereco"] = cedente_endereco

        if avalista:
            dados["avalista"] = avalista
            if avalista_documento:
                dados["avalista_documento"] = avalista_documento

        if demonstrativo:
            dados["demonstrativo"] = demonstrativo

        if descontos_e_abatimentos:
            dados["descontos_e_abatimentos"] = descontos_e_abatimentos

        # Instruções (até 7)
        if instrucoes:
            for i, instrucao in enumerate(instrucoes[:7], 1):
                dados[f"instrucao{i}"] = instrucao

        return dados

    def gerar_boleto(
        self,
        bank: str,
        dados: Dict,
        tipo: str = "pdf"
    ) -> bytes:
        """Gera boleto com todos os dados fornecidos"""

        response = requests.get(
            f"{self.api_url}/boleto",
            params={
                "bank": bank,
                "type": tipo,
                "data": json.dumps(dados)
            }
        )

        response.raise_for_status()
        return response.content


# ============================================
# EXEMPLO DE USO
# ============================================
if __name__ == "__main__":
    api = BoletoCompleto()

    # Criar boleto Sicoob com MÁXIMO de informações
    dados = api.dados_completos_sicoob(
        # Obrigatórios
        agencia="4327",
        conta_corrente="417270",
        convenio="229385",
        nosso_numero="1234567",
        valor=1500.50,
        cedente="M&S do Brasil Ltda",
        documento_cedente="12345678000190",
        sacado="João da Silva",
        sacado_documento="12345678901",

        # Opcionais mas RECOMENDADOS
        documento_numero="NF-2025-001234",
        sacado_endereco="Av. Paulista, 1000 - São Paulo/SP - CEP: 01310-100",
        cedente_endereco="Rua Exemplo, 1234 - São Paulo/SP - CEP: 01000-000",

        # Avalista
        avalista="Maria Santos",
        avalista_documento="98765432100",

        # Instruções
        instrucoes=[
            "Não receber após o vencimento",
            "Multa de 2% após vencimento",
            "Juros de 1% ao mês",
            "Desconto de R$ 50 até 5 dias antes",
            "Contato: (11) 1234-5678",
            "Ref. Contrato 2025/1234",
            "Emitido via API BRCobranca",
        ],

        # Informações adicionais
        demonstrativo="Prestação de serviços - Contrato 2025/1234",
        descontos_e_abatimentos="Desconto de R$ 50 para pgto antecipado",

        # Vencimento
        dias_vencimento=30,
    )

    # Gerar PDF
    try:
        pdf_content = api.gerar_boleto("sicoob", dados)
        with open("boleto_completo.pdf", "wb") as f:
            f.write(pdf_content)
        print("✅ Boleto completo gerado com SUCESSO!")
        print(f"   Campos enviados: {len(dados)}")
        print(f"   Documento número: {dados.get('documento_numero', 'N/A')}")
    except Exception as e:
        print(f"❌ Erro ao gerar boleto: {e}")
```

---

## 📋 Checklist de Validação

Ao gerar um boleto, verifique se está enviando:

### ✅ Campos Obrigatórios Básicos
- [x] agencia
- [x] conta_corrente
- [x] carteira
- [x] convenio (ou equivalente)
- [x] nosso_numero
- [x] valor
- [x] data_vencimento
- [x] cedente
- [x] documento_cedente
- [x] sacado
- [x] sacado_documento

### ✅ Campos Opcionais Recomendados
- [ ] **documento_numero** (NF/pedido) - **SEMPRE ENVIAR!**
- [ ] sacado_endereco
- [ ] cedente_endereco
- [ ] data_documento
- [ ] data_processamento
- [ ] instrucao1 a instrucao7
- [ ] demonstrativo

### ✅ Campos Opcionais Se Aplicável
- [ ] avalista
- [ ] avalista_documento
- [ ] descontos_e_abatimentos
- [ ] aceite específico por banco
- [ ] variacao (Sicoob)

---

## 🎯 Benefícios de Enviar Máximo de Campos

1. **Rastreabilidade**: `documento_numero` vincula boleto ao pedido/NF
2. **Compliance**: Endereços completos atendem requisitos regulatórios
3. **Profissionalismo**: Instruções claras melhoram experiência do cliente
4. **Menos Erros**: Informações completas reduzem dúvidas e contestações
5. **Facilita Conciliação**: Demonstrativo e número do documento facilitam baixa

---

**Data de Criação:** 2025-11-25
**Mantido por:** Maxwell da Silva Oliveira (@maxwbh)
**M&S do Brasil Ltda**
