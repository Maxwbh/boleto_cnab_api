#!/usr/bin/env python3
"""
Exemplo de geração de boletos para múltiplos bancos.

Demonstra como gerar boletos para diferentes bancos
mantendo uma estrutura base de dados e ajustando
campos específicos de cada banco.
"""

from boleto_cnab_client import BoletoClient

def main():
    client = BoletoClient('http://localhost:9292')

    # Dados base (comuns a todos os bancos)
    dados_base = {
        "cedente": "Empresa Exemplo LTDA",
        "documento_cedente": "12345678000100",
        "sacado": "João da Silva",
        "sacado_documento": "12345678900",
        "sacado_endereco": "Rua Exemplo, 100, Centro, São Paulo, SP, CEP 01000-000",
        "valor": 500.00,
        "data_vencimento": "2025/12/31",
        "data_documento": "2025/11/27",
        "especie_documento": "DM",
        "aceite": "N",
        "local_pagamento": "Pagavel em qualquer banco ate o vencimento",
        "instrucao1": "Nao receber apos o vencimento"
    }

    # Configurações específicas por banco
    bancos_config = {
        'banco_brasil': {
            "agencia": "3073",
            "conta_corrente": "12345678",
            "convenio": "01234567",  # OBRIGATÓRIO
            "carteira": "18",
            "nosso_numero": "100",
            "numero_documento": "BB-001"
        },
        'sicoob': {
            "agencia": "4327",
            "conta_corrente": "417270",
            "carteira": "1",
            "variacao": "01",  # OBRIGATÓRIO
            "convenio": "229385",  # OBRIGATÓRIO
            "nosso_numero": "200",
            "numero_documento": "SICOOB-001"
        },
        'bradesco': {
            "agencia": "1234",
            "conta_corrente": "123456",
            "digito_conta": "7",  # OBRIGATÓRIO
            "carteira": "09",
            "nosso_numero": "300",
            "numero_documento": "BRAD-001"
        },
        'itau': {
            "agencia": "0057",
            "conta_corrente": "12345",
            "digito_conta": "6",
            "carteira": "175",
            "nosso_numero": "400",
            "numero_documento": "ITAU-001"
        },
        'caixa': {
            "agencia": "1565",
            "conta_corrente": "123456789",
            "digito_conta": "1",  # OBRIGATÓRIO
            "convenio": "654321",  # OBRIGATÓRIO
            "carteira": "RG",
            "nosso_numero": "500000000000000",  # 15 dígitos
            "numero_documento": "CAIXA-001"
        },
        'santander': {
            "agencia": "0001",
            "conta_corrente": "1234567",
            "digito_conta": "8",
            "carteira": "102",
            "nosso_numero": "600",
            "numero_documento": "SANT-001"
        }
    }

    print("🏦 Gerando boletos para múltiplos bancos")
    print("=" * 60)

    for banco_code, config in bancos_config.items():
        print(f"\n📄 Gerando boleto: {banco_code.upper()}")
        print("-" * 60)

        # Combinar dados base com configuração específica
        dados_completos = {**dados_base, **config}

        try:
            # Validar
            resultado = client.validate(banco_code, dados_completos)
            if not resultado['valid']:
                print(f"❌ Validação falhou: {resultado['errors']}")
                continue

            # Obter dados
            boleto = client.get_boleto_data(banco_code, dados_completos)
            print(f"✅ Nosso Número: {boleto.nosso_numero}")
            print(f"✅ Código de Barras: {boleto.codigo_barras}")

            if boleto.linha_digitavel:
                print(f"✅ Linha Digitável: {boleto.linha_digitavel}")
            else:
                print(f"⚠️  Linha Digitável: Não disponível via API")

            # Gerar PDF
            pdf_bytes = client.generate_boleto(banco_code, dados_completos)
            filename = f'boleto_{banco_code}.pdf'
            with open(filename, 'wb') as f:
                f.write(pdf_bytes)

            print(f"✅ PDF salvo: {filename} ({len(pdf_bytes) / 1024:.2f} KB)")

        except Exception as e:
            print(f"❌ Erro ao gerar {banco_code}: {e}")
            continue

    print("\n" + "=" * 60)
    print("🎉 Processamento concluído!")
    print("\nArquivos gerados:")
    for banco_code in bancos_config.keys():
        print(f"  - boleto_{banco_code}.pdf")

if __name__ == "__main__":
    main()
