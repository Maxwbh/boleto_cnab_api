# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoletoApi::Config::Constants do
  describe '::SUPPORTED_BANKS' do
    it 'includes major Brazilian banks' do
      expect(described_class::SUPPORTED_BANKS).to include('banco_brasil')
      expect(described_class::SUPPORTED_BANKS).to include('itau')
      expect(described_class::SUPPORTED_BANKS).to include('bradesco')
      expect(described_class::SUPPORTED_BANKS).to include('caixa')
      expect(described_class::SUPPORTED_BANKS).to include('santander')
      expect(described_class::SUPPORTED_BANKS).to include('sicoob')
    end

    it 'is frozen' do
      expect(described_class::SUPPORTED_BANKS).to be_frozen
    end
  end

  describe '::OUTPUT_TYPES' do
    it 'includes all supported output formats' do
      expect(described_class::OUTPUT_TYPES).to eq(%w[pdf jpg png tif])
    end

    it 'is frozen' do
      expect(described_class::OUTPUT_TYPES).to be_frozen
    end
  end

  describe '::CNAB_TYPES' do
    it 'includes cnab400 and cnab240' do
      expect(described_class::CNAB_TYPES).to eq(%w[cnab400 cnab240])
    end
  end

  describe '::RETORNO_FIELDS' do
    it 'includes essential return fields' do
      expect(described_class::RETORNO_FIELDS).to include(:codigo_registro)
      expect(described_class::RETORNO_FIELDS).to include(:nosso_numero)
      expect(described_class::RETORNO_FIELDS).to include(:valor_titulo)
      expect(described_class::RETORNO_FIELDS).to include(:data_vencimento)
    end

    it 'is frozen' do
      expect(described_class::RETORNO_FIELDS).to be_frozen
    end
  end

  describe '.bank_supported?' do
    it 'returns true for supported banks' do
      expect(described_class.bank_supported?('banco_brasil')).to be true
      expect(described_class.bank_supported?('itau')).to be true
      expect(described_class.bank_supported?('sicoob')).to be true
    end

    it 'returns false for unsupported banks' do
      expect(described_class.bank_supported?('unknown_bank')).to be false
      expect(described_class.bank_supported?('')).to be false
    end

    it 'handles symbols' do
      expect(described_class.bank_supported?(:banco_brasil)).to be true
    end

    it 'normalizes bank names with dashes' do
      expect(described_class.bank_supported?('banco-brasil')).to be true
    end
  end

  describe '.cnab_type_supported?' do
    it 'returns true for supported CNAB types' do
      expect(described_class.cnab_type_supported?('cnab400')).to be true
      expect(described_class.cnab_type_supported?('cnab240')).to be true
    end

    it 'returns false for unsupported types' do
      expect(described_class.cnab_type_supported?('cnab500')).to be false
    end
  end

  describe '.output_type_supported?' do
    it 'returns true for supported output types' do
      expect(described_class.output_type_supported?('pdf')).to be true
      expect(described_class.output_type_supported?('jpg')).to be true
      expect(described_class.output_type_supported?('png')).to be true
      expect(described_class.output_type_supported?('tif')).to be true
    end

    it 'returns false for unsupported types' do
      expect(described_class.output_type_supported?('gif')).to be false
      expect(described_class.output_type_supported?('bmp')).to be false
    end
  end

  describe '.content_type_for' do
    it 'returns correct content types' do
      expect(described_class.content_type_for('pdf')).to eq('application/pdf')
      expect(described_class.content_type_for('jpg')).to eq('image/jpeg')
      expect(described_class.content_type_for('png')).to eq('image/png')
      expect(described_class.content_type_for('tif')).to eq('image/tiff')
    end

    it 'returns octet-stream for unknown types' do
      expect(described_class.content_type_for('unknown')).to eq('application/octet-stream')
    end
  end
end
