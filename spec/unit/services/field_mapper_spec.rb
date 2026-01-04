# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoletoApi::Services::FieldMapper do
  describe '.map_boleto' do
    it 'maps numero_documento to documento_numero' do
      values = { 'numero_documento' => '12345' }
      result = described_class.map_boleto(values)

      expect(result).not_to have_key('numero_documento')
      expect(result['documento_numero']).to eq('12345')
    end

    it 'keeps documento_numero when both fields are present' do
      values = {
        'numero_documento' => 'ignored',
        'documento_numero' => 'kept'
      }
      result = described_class.map_boleto(values)

      expect(result['documento_numero']).to eq('kept')
      expect(result).not_to have_key('numero_documento')
    end

    it 'converts date strings to Date objects' do
      values = {
        'data_documento' => '2024-01-15',
        'data_vencimento' => '2024-02-15',
        'data_processamento' => '2024-01-10'
      }
      result = described_class.map_boleto(values)

      expect(result['data_documento']).to be_a(Date)
      expect(result['data_documento']).to eq(Date.new(2024, 1, 15))
      expect(result['data_vencimento']).to be_a(Date)
      expect(result['data_processamento']).to be_a(Date)
    end

    it 'handles nil date values' do
      values = { 'data_documento' => nil }
      result = described_class.map_boleto(values)

      expect(result['data_documento']).to be_nil
    end

    it 'handles empty date strings' do
      values = { 'data_documento' => '' }
      result = described_class.map_boleto(values)

      expect(result['data_documento']).to be_nil
    end

    it 'preserves Date objects' do
      date = Date.today
      values = { 'data_vencimento' => date }
      result = described_class.map_boleto(values)

      expect(result['data_vencimento']).to eq(date)
    end

    it 'does not modify original hash' do
      values = { 'numero_documento' => '12345' }
      described_class.map_boleto(values)

      expect(values).to have_key('numero_documento')
    end
  end

  describe '.map_pagamento' do
    it 'converts pagamento date fields' do
      values = {
        'data_vencimento' => '2024-01-15',
        'data_emissao' => '2024-01-01',
        'data_desconto' => '2024-01-10'
      }
      result = described_class.map_pagamento(values)

      expect(result['data_vencimento']).to be_a(Date)
      expect(result['data_emissao']).to be_a(Date)
      expect(result['data_desconto']).to be_a(Date)
    end

    it 'sets default data_vencimento when not provided' do
      values = { 'valor' => 100.0 }
      result = described_class.map_pagamento(values)

      expect(result['data_vencimento']).to eq(Date.today)
    end

    it 'does not override existing data_vencimento' do
      values = { 'data_vencimento' => '2024-12-31' }
      result = described_class.map_pagamento(values)

      expect(result['data_vencimento']).to eq(Date.new(2024, 12, 31))
    end
  end

  describe '.map' do
    it 'accepts custom date fields' do
      values = { 'custom_date' => '2024-06-15' }
      result = described_class.map(values, date_fields: ['custom_date'])

      expect(result['custom_date']).to be_a(Date)
      expect(result['custom_date']).to eq(Date.new(2024, 6, 15))
    end
  end
end
