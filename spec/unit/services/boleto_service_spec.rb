# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoletoApi::Services::BoletoService do
  let(:fixtures) { JSON.parse(File.read('spec/fixtures/sample_data.json')) }
  let(:bb_data) { fixtures['banco_brasil_valido'] }
  let(:invalid_data) { fixtures['invalido_sem_nosso_numero'] }

  describe '.create' do
    it 'creates a boleto object for valid bank' do
      boleto = described_class.create('banco_brasil', bb_data)

      expect(boleto).to be_a(Brcobranca::Boleto::BancoBrasil)
    end

    it 'maps field names correctly' do
      data = bb_data.dup
      data['numero_documento'] = 'TEST123'
      data.delete('documento_numero')

      boleto = described_class.create('banco_brasil', data)

      expect(boleto.documento_numero).to eq('TEST123')
    end

    it 'converts date strings to Date objects' do
      data = bb_data.dup
      data['data_vencimento'] = '2024-12-31'

      boleto = described_class.create('banco_brasil', data)

      expect(boleto.data_vencimento).to be_a(Date)
    end

    it 'raises ArgumentError for unsupported bank' do
      expect {
        described_class.create('unknown_bank', bb_data)
      }.to raise_error(ArgumentError, /não suportado/)
    end
  end

  describe '.validate' do
    it 'returns valid: true for valid data' do
      result = described_class.validate('banco_brasil', bb_data)

      expect(result[:valid]).to be true
      expect(result[:errors]).to be_empty
    end

    it 'returns valid: false with errors for invalid data' do
      result = described_class.validate('banco_brasil', invalid_data)

      expect(result[:valid]).to be false
      expect(result[:errors]).not_to be_empty
    end
  end

  describe '.data' do
    context 'with valid data' do
      it 'returns complete boleto data' do
        result = described_class.data('banco_brasil', bb_data)

        expect(result[:valid]).to be true
        expect(result[:bank]).to eq('banco_brasil')
        expect(result).to have_key(:nosso_numero)
        expect(result).to have_key(:codigo_barras)
        expect(result).to have_key(:linha_digitavel)
        expect(result).to have_key(:numero_documento)
        expect(result).to have_key(:valor)
      end

      it 'includes calculated fields' do
        result = described_class.data('banco_brasil', bb_data)

        expect(result[:codigo_barras]).not_to be_nil
        expect(result[:codigo_barras].length).to eq(44)
      end
    end

    context 'with invalid data' do
      it 'returns valid: false with errors' do
        result = described_class.data('banco_brasil', invalid_data)

        expect(result[:valid]).to be false
        expect(result[:errors]).not_to be_empty
      end
    end
  end

  describe '.nosso_numero' do
    it 'returns nosso_numero and related fields' do
      result = described_class.nosso_numero('banco_brasil', bb_data)

      expect(result[:valid]).to be true
      expect(result).to have_key(:nosso_numero)
      expect(result).to have_key(:codigo_barras)
      expect(result).to have_key(:linha_digitavel)
    end
  end

  describe '.generate' do
    it 'generates PDF for valid data' do
      result = described_class.generate('banco_brasil', bb_data, format: 'pdf')

      expect(result[:valid]).to be true
      expect(result[:content]).not_to be_nil
      expect(result[:content].bytes[0..3]).to eq([0x25, 0x50, 0x44, 0x46]) # PDF magic
    end

    it 'returns errors for invalid data' do
      result = described_class.generate('banco_brasil', invalid_data, format: 'pdf')

      expect(result[:valid]).to be false
      expect(result[:content]).to be_nil
      expect(result[:errors]).not_to be_empty
    end

    it 'raises error for invalid format' do
      expect {
        described_class.generate('banco_brasil', bb_data, format: 'invalid')
      }.to raise_error(ArgumentError, /não suportado/)
    end
  end

  describe '.generate_multi' do
    it 'generates PDF with multiple boletos' do
      boletos = [
        bb_data.merge('bank' => 'banco_brasil'),
        bb_data.merge('bank' => 'banco_brasil')
      ]
      result = described_class.generate_multi(boletos, format: 'pdf')

      expect(result[:valid]).to be true
      expect(result[:valid_count]).to eq(2)
      expect(result[:invalid_count]).to eq(0)
      expect(result[:content]).not_to be_nil
    end

    it 'reports errors for invalid boletos' do
      boletos = [
        bb_data.merge('bank' => 'banco_brasil'),
        invalid_data.merge('bank' => 'banco_brasil')
      ]
      result = described_class.generate_multi(boletos, format: 'pdf')

      expect(result[:valid]).to be false
      expect(result[:valid_count]).to eq(1)
      expect(result[:invalid_count]).to eq(1)
      expect(result[:errors]).not_to be_empty
    end

    it 'reports error when bank is missing' do
      boletos = [bb_data] # sem campo 'bank'
      result = described_class.generate_multi(boletos, format: 'pdf')

      expect(result[:valid]).to be false
      expect(result[:errors].first[:error]).to include('bank')
    end
  end
end
