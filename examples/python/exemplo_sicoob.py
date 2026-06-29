#!/usr/bin/env python3
"""
Exemplo de geração de boleto para Sicoob.

IMPORTANTE: O Sicoob tem particularidades:
- Campo 'variacao' é OBRIGATÓRIO
- Campo 'convenio' é OBRIGATÓRIO
- Campo 'aceite' deve ser 'N' (não 'S')
- linha_digitavel pode retornar None via API (mas aparece no PDF)
"""

from boleto_cnab_client import BoletoClient

def main():
    # Conectar à API
    client = BoletoClient('http://localhost:9292')

    # Dados do boleto Sicoob
    # ATENÇÃO: Verifique com sua cooperativa os valores corretos
    # de agência, conta, carteira, variação e convênio
    dados_sicoob = {
        "cedente": "Cooperativa Teste LTDA",
        "documento_cedente": "98765432000100",
        "sacado": "Maria Santos",
        "sacado_documento": "98765432100",
        "sacado_endereco": "Av. Principal, 50, Bairro, Rio de Janeiro, RJ, CEP 20000-000",

        # Dados da conta Sicoob
        "agencia": "4327",
        "conta_corrente": "417270",
        "carteira": "1",
        "variacao": "01",  # OBRIGATÓRIO para Sicoob!
        "convenio": "229385",  # OBRIGATÓRIO para Sicoob!

        # Dados do boleto
        "nosso_numero": "7890",
        "numero_documento": "NF-2025-1234",
        "valor": 2500.00,
        "data_vencimento": "2025/12/31",
        "data_documento": "2025/11/27",

        # Campos específicos
        "especie_documento": "DM",  # OBRIGATÓRIO
        "aceite": "N",  # DEVE ser 'N' para Sicoob!

        # Informações de pagamento
        "local_pagamento": "Pagavel em qualquer banco ate o vencimento",
        "instrucao1": "Nao receber apos 30 dias do vencimento"
    }

    print("🏦 Gerando boleto Sicoob...")
    print("=" * 60)

    # 1. Validar
    print("\n🔍 Validando dados...")
    resultado = client.validate('sicoob', dados_sicoob)
    if resultado['valid']:
        print("✅ Dados válidos!")
    else:
        print(f"❌ Erros: {resultado['errors']}")
        return

    # 2. Obter dados do boleto
    print("\n📊 Obtendo dados do boleto...")
    boleto = client.get_boleto_data('sicoob', dados_sicoob)

    print(f"✅ Nosso Número: {boleto.nosso_numero}")
    print(f"✅ Código de Barras: {boleto.codigo_barras}")

    # IMPORTANTE: linha_digitavel pode ser None no Sicoob via /data
    # mas sempre aparece no PDF gerado
    if boleto.linha_digitavel:
        print(f"✅ Linha Digitável: {boleto.linha_digitavel}")
    else:
        print("⚠️  Linha Digitável: Não disponível via API (estará no PDF)")

    # 3. Gerar PDF
    print("\n📄 Gerando PDF...")
    pdf_bytes = client.generate_boleto('sicoob', dados_sicoob)

    filename = 'boleto_sicoob.pdf'
    with open(filename, 'wb') as f:
        f.write(pdf_bytes)

    print(f"✅ PDF salvo: {filename}")
    print(f"   Tamanho: {len(pdf_bytes) / 1024:.2f} KB")

    print("\n" + "=" * 60)
    print("🎉 Boleto Sicoob gerado com sucesso!")
    print("\n💡 Dica: Abra o PDF e verifique que a linha digitável")
    print("   está presente mesmo que não apareça via API.")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n❌ Erro: {e}")
        import traceback
        traceback.print_exc()
