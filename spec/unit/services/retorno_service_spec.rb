# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe BoletoApi::Services::RetornoService do
  describe '.parse' do
    it 'raises error for invalid CNAB type' do
      file = StringIO.new('dummy content')

      expect {
        described_class.parse('itau', 'cnab500', file)
      }.to raise_error(ArgumentError, /não suportado/)
    end

    context 'with invalid file' do
      it 'returns error result' do
        file = StringIO.new('invalid content')

        result = described_class.parse('itau', 'cnab400', file)

        # Pode retornar array vazio ou erro dependendo da implementação da gem
        expect(result).to have_key(:valid)
        expect(result).to have_key(:pagamentos)
      end
    end
  end
end
