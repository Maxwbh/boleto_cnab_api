#!/usr/bin/env python3
"""
Exemplo de tratamento robusto de erros ao usar o cliente Python.

Demonstra como lidar com:
- Erros de conexão
- Timeouts
- Erros de validação
- Dados inválidos
- Retry automático
"""

import logging
from boleto_cnab_client import (
    BoletoClient,
    BoletoValidationError,
    BoletoConnectionError,
    BoletoTimeoutError,
    BoletoAPIError
)

# Configurar logging para ver detalhes
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

def exemplo_validacao_erros():
    """Exemplo: Dados inválidos que falham na validação"""
    print("\n" + "=" * 60)
    print("📋 Exemplo 1: Tratamento de Erros de Validação")
    print("=" * 60)

    client = BoletoClient('http://localhost:9292')

    # Dados INVÁLIDOS (faltam campos obrigatórios)
    dados_invalidos = {
        "cedente": "Empresa Teste",
        # Faltando: documento_cedente, sacado, etc.
        "valor": 100.00
    }

    try:
        resultado = client.validate('banco_brasil', dados_invalidos)

        if resultado['valid']:
            print("✅ Dados válidos!")
        else:
            print("❌ Dados inválidos encontrados:")
            for error in resultado.get('errors', []):
                print(f"   - {error}")

    except BoletoValidationError as e:
        print(f"❌ Erro de validação: {e}")
        if hasattr(e, 'details') and e.details:
            print("   Detalhes:")
            for key, value in e.details.items():
                print(f"   - {key}: {value}")

def exemplo_conexao_erro():
    """Exemplo: API não disponível"""
    print("\n" + "=" * 60)
    print("📋 Exemplo 2: Tratamento de Erro de Conexão")
    print("=" * 60)

    # Tentar conectar em URL inválida
    client = BoletoClient('http://localhost:9999', timeout=5, retries=2)

    dados = {
        "cedente": "Teste",
        "documento_cedente": "12345678000100",
        "sacado": "João",
        "sacado_documento": "12345678900",
        "agencia": "1234",
        "conta_corrente": "12345",
        "convenio": "12345",
        "carteira": "18",
        "nosso_numero": "123",
        "valor": 100.00,
        "data_vencimento": "2025/12/31"
    }

    try:
        resultado = client.validate('banco_brasil', dados)
        print(f"✅ Validação OK: {resultado}")

    except BoletoConnectionError as e:
        print(f"❌ Erro de conexão: {e}")
        print("   💡 Verifique se a API está rodando")
        print("   💡 Comando: docker-compose up -d")

    except BoletoTimeoutError as e:
        print(f"❌ Timeout na requisição: {e}")
        print("   💡 A API pode estar lenta ou sobrecarregada")

def exemplo_retry_automatico():
    """Exemplo: Demonstração do retry automático"""
    print("\n" + "=" * 60)
    print("📋 Exemplo 3: Retry Automático")
    print("=" * 60)

    # Cliente com retry configurado
    client = BoletoClient(
        'http://localhost:9292',
        timeout=10,
        retries=3  # Tentará 3 vezes antes de falhar
    )

    dados = {
        "cedente": "Empresa Exemplo LTDA",
        "documento_cedente": "12345678000100",
        "sacado": "João da Silva",
        "sacado_documento": "12345678900",
        "agencia": "3073",
        "conta_corrente": "12345678",
        "convenio": "01234567",
        "carteira": "18",
        "nosso_numero": "123",
        "valor": 150.00,
        "data_vencimento": "2025/12/31"
    }

    try:
        print("🔄 Tentando conectar (com retry automático)...")
        boleto = client.get_boleto_data('banco_brasil', dados)
        print(f"✅ Sucesso! Código de barras: {boleto.codigo_barras}")

    except BoletoConnectionError as e:
        print(f"❌ Falhou após todas as tentativas: {e}")

def exemplo_campos_especificos_banco():
    """Exemplo: Erro ao esquecer campos obrigatórios do banco"""
    print("\n" + "=" * 60)
    print("📋 Exemplo 4: Campos Específicos do Banco")
    print("=" * 60)

    client = BoletoClient('http://localhost:9292')

    # Sicoob SEM campo 'variacao' (OBRIGATÓRIO)
    dados_sicoob_incompleto = {
        "cedente": "Cooperativa",
        "documento_cedente": "12345678000100",
        "sacado": "João",
        "sacado_documento": "12345678900",
        "agencia": "4327",
        "conta_corrente": "417270",
        "carteira": "1",
        "convenio": "229385",
        # FALTANDO: variacao (OBRIGATÓRIO para Sicoob!)
        "nosso_numero": "123",
        "valor": 100.00,
        "data_vencimento": "2025/12/31"
    }

    try:
        resultado = client.validate('sicoob', dados_sicoob_incompleto)
        if not resultado['valid']:
            print("❌ Validação falhou:")
            print(f"   Erros: {resultado['errors']}")
            print("\n💡 Dica: Para Sicoob, o campo 'variacao' é OBRIGATÓRIO")

    except BoletoValidationError as e:
        print(f"❌ Erro: {e}")
        print("💡 Verifique a documentação do banco específico")

def exemplo_tratamento_completo():
    """Exemplo: Tratamento completo com todos os tipos de erro"""
    print("\n" + "=" * 60)
    print("📋 Exemplo 5: Tratamento Completo")
    print("=" * 60)

    client = BoletoClient('http://localhost:9292', timeout=10, retries=3)

    dados = {
        "cedente": "Empresa Exemplo LTDA",
        "documento_cedente": "12345678000100",
        "sacado": "João da Silva",
        "sacado_documento": "12345678900",
        "agencia": "3073",
        "conta_corrente": "12345678",
        "convenio": "01234567",
        "carteira": "18",
        "nosso_numero": "123",
        "numero_documento": "NF-2025-001",
        "valor": 150.00,
        "data_vencimento": "2025/12/31"
    }

    try:
        # 1. Health check
        print("🔍 Verificando disponibilidade da API...")
        status = client.health_check()
        print(f"✅ API: {status['status']}")

        # 2. Validar
        print("\n🔍 Validando dados...")
        resultado = client.validate('banco_brasil', dados)
        if not resultado['valid']:
            raise BoletoValidationError(f"Dados inválidos: {resultado['errors']}")
        print("✅ Validação OK")

        # 3. Obter dados
        print("\n📊 Obtendo dados do boleto...")
        boleto = client.get_boleto_data('banco_brasil', dados)
        print(f"✅ Código de barras: {boleto.codigo_barras}")

        # 4. Gerar PDF
        print("\n📄 Gerando PDF...")
        pdf_bytes = client.generate_boleto('banco_brasil', dados)
        with open('boleto_completo.pdf', 'wb') as f:
            f.write(pdf_bytes)
        print(f"✅ PDF salvo: boleto_completo.pdf")

        print("\n🎉 Processo concluído com sucesso!")

    except BoletoValidationError as e:
        print(f"\n❌ Erro de validação: {e}")
        print("💡 Corrija os dados e tente novamente")

    except BoletoConnectionError as e:
        print(f"\n❌ Erro de conexão: {e}")
        print("💡 Verifique se a API está rodando")
        print("   docker-compose up -d")

    except BoletoTimeoutError as e:
        print(f"\n❌ Timeout: {e}")
        print("💡 Aumente o timeout ou verifique a performance da API")

    except BoletoAPIError as e:
        print(f"\n❌ Erro da API: {e}")
        print("💡 Verifique os logs da API para mais detalhes")

    except Exception as e:
        print(f"\n❌ Erro inesperado: {e}")
        import traceback
        traceback.print_exc()

def main():
    print("🔧 Exemplos de Tratamento de Erros")
    print("=" * 60)

    # Executar todos os exemplos
    exemplo_validacao_erros()
    exemplo_conexao_erro()
    exemplo_retry_automatico()
    exemplo_campos_especificos_banco()
    exemplo_tratamento_completo()

    print("\n" + "=" * 60)
    print("✅ Todos os exemplos foram executados")
    print("\n💡 Principais dicas:")
    print("   1. Sempre use try/except para capturar erros")
    print("   2. Valide os dados antes de gerar o boleto")
    print("   3. Configure retry para APIs instáveis")
    print("   4. Use logging para debug em produção")
    print("   5. Consulte a documentação do banco específico")

if __name__ == "__main__":
    main()
