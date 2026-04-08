# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoletoApi::Services::NossoNumeroExtractor do
  describe '.extrair' do
    context 'com memo nil ou vazio' do
      it 'retorna nil para memo nil' do
        expect(described_class.extrair(nil, 'SICOOB')).to be_nil
      end

      it 'retorna nil para memo vazio' do
        expect(described_class.extrair('', 'SICOOB')).to be_nil
      end

      it 'retorna nil para memo apenas com espaços' do
        expect(described_class.extrair('   ', 'SICOOB')).to be_nil
      end
    end

    context 'Sicoob (756)' do
      it 'extrai sequência de 7 dígitos' do
        expect(described_class.extrair('COBRANCA SICOOB 1234567', 'SICOOB')).to eq('1234567')
      end

      it 'extrai sequência de 10 dígitos' do
        expect(described_class.extrair('COBRANCA SICOOB 0000012345', '756')).to eq('0000012345')
      end

      it 'extrai sequência de 12 dígitos' do
        expect(described_class.extrair('PAG 123456789012 SICOOB', 'sicoob')).to eq('123456789012')
      end

      it 'retorna nil quando não há sequência suficiente' do
        expect(described_class.extrair('COBRANCA 123', 'SICOOB')).to be_nil
      end
    end

    context 'Itaú (341)' do
      it 'extrai sequência de 8 dígitos' do
        expect(described_class.extrair('RECEBIMENTO BOLETO 12345678', 'ITAU')).to eq('12345678')
      end

      it 'funciona com FID 341' do
        expect(described_class.extrair('BOLETO 87654321 RECEBIDO', '341')).to eq('87654321')
      end

      it 'retorna nil quando não há 8 dígitos consecutivos' do
        expect(described_class.extrair('BOLETO 12345 RECEBIDO', 'ITAU')).to be_nil
      end
    end

    context 'Banco do Brasil (001)' do
      it 'extrai sequência de 10 dígitos' do
        expect(described_class.extrair('COBRANCA BB 1234567890', 'BRASIL')).to eq('1234567890')
      end

      it 'extrai sequência de 17 dígitos' do
        expect(described_class.extrair('BB 12345678901234567', '001')).to eq('12345678901234567')
      end

      it 'retorna nil quando sequência é curta' do
        expect(described_class.extrair('BB 123456789', 'BRASIL')).to be_nil
      end
    end

    context 'Bradesco (237)' do
      it 'extrai sequência de 11 dígitos' do
        expect(described_class.extrair('BRADESCO COB 12345678901', 'BRADESCO')).to eq('12345678901')
      end

      it 'funciona com FID 237' do
        expect(described_class.extrair('PAG 98765432101 BRAD', '237')).to eq('98765432101')
      end
    end

    context 'Caixa (104)' do
      it 'extrai sequência de 14 dígitos' do
        expect(described_class.extrair('CAIXA 12345678901234', 'CAIXA')).to eq('12345678901234')
      end

      it 'extrai sequência de 17 dígitos' do
        expect(described_class.extrair('CEF 12345678901234567', '104')).to eq('12345678901234567')
      end

      it 'retorna nil quando sequência é curta' do
        expect(described_class.extrair('CAIXA 1234567890123', 'CAIXA')).to be_nil
      end
    end

    context 'banco genérico' do
      it 'extrai primeira sequência de 7 a 17 dígitos' do
        expect(described_class.extrair('PAGAMENTO 1234567 EFETUADO', 'OUTRO_BANCO')).to eq('1234567')
      end

      it 'retorna nil quando não há sequência suficiente' do
        expect(described_class.extrair('PAGAMENTO 123456', 'DESCONHECIDO')).to be_nil
      end
    end
  end
end
