# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoletoApi::Services::RemessaService do
  let(:remessa_data) do
    {
      'carteira' => '123',
      'agencia' => '1234',
      'conta_corrente' => '12345',
      'digito_conta' => '1',
      'empresa_mae' => 'EMPRESA TESTE LTDA',
      'documento_cedente' => '12345678910',
      'pagamentos' => [
        {
          'valor' => 199.90,
          'data_vencimento' => '2024-06-15',
          'nosso_numero' => 123,
          'documento_sacado' => '12345678901',
          'nome_sacado' => 'Cliente Teste',
          'endereco_sacado' => 'Rua Teste, 123',
          'bairro_sacado' => 'Centro',
          'cep_sacado' => '12345678',
          'cidade_sacado' => 'São Paulo',
          'uf_sacado' => 'SP'
        }
      ]
    }
  end

  describe '.create_pagamento' do
    it 'creates a Pagamento object' do
      pagamento_data = {
        'valor' => 100.0,
        'data_vencimento' => '2024-06-15',
        'nosso_numero' => 123,
        'documento_sacado' => '12345678901',
        'nome_sacado' => 'Teste'
      }

      pagamento = described_class.create_pagamento(pagamento_data)

      expect(pagamento).to be_a(Brcobranca::Remessa::Pagamento)
    end

    it 'converts date strings' do
      pagamento_data = {
        'valor' => 100.0,
        'data_vencimento' => '2024-12-31',
        'nosso_numero' => 123
      }

      pagamento = described_class.create_pagamento(pagamento_data)

      expect(pagamento.data_vencimento).to be_a(Date)
    end

    it 'sets default data_vencimento when not provided' do
      pagamento_data = { 'valor' => 100.0, 'nosso_numero' => 123 }

      pagamento = described_class.create_pagamento(pagamento_data)

      expect(pagamento.data_vencimento).to eq(Date.today)
    end
  end

  describe '.generate' do
    it 'raises error for invalid CNAB type' do
      expect {
        described_class.generate('itau', 'cnab500', remessa_data)
      }.to raise_error(ArgumentError, /não suportado/)
    end

    it 'returns errors for invalid pagamentos' do
      invalid_remessa = remessa_data.merge(
        'pagamentos' => [{ 'valor' => nil }]
      )

      result = described_class.generate('itau', 'cnab400', invalid_remessa)

      expect(result[:valid]).to be false
      expect(result[:errors]).not_to be_empty
    end
  end
end
