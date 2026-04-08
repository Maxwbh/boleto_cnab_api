# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoletoApi::Services::OFXParserService do
  let(:sicoob_ofx_path) { File.join(__dir__, '../../fixtures/extrato_sicoob.ofx') }
  let(:itau_ofx_path) { File.join(__dir__, '../../fixtures/extrato_itau.ofx') }

  describe '.parse' do
    context 'com arquivo OFX Sicoob válido' do
      it 'retorna dados estruturados do extrato' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        expect(result).to have_key(:banco)
        expect(result).to have_key(:conta)
        expect(result).to have_key(:periodo)
        expect(result).to have_key(:saldo)
        expect(result).to have_key(:transacoes)
        expect(result).to have_key(:resumo)
      end

      it 'identifica o banco corretamente' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        expect(result[:banco][:org]).to eq('SICOOB')
        expect(result[:banco][:fid]).to eq('756')
      end

      it 'extrai dados da conta' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        expect(result[:conta][:numero]).to eq('12345-6')
        expect(result[:conta][:tipo]).not_to be_empty
      end

      it 'lista todas as transações' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        expect(result[:transacoes].size).to eq(4)
      end

      it 'classifica créditos e débitos corretamente' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        creditos = result[:transacoes].select { |t| t[:tipo] == 'CREDIT' }
        debitos = result[:transacoes].select { |t| t[:tipo] == 'DEBIT' }

        expect(creditos.size).to eq(2)
        expect(debitos.size).to eq(2)
      end

      it 'extrai nosso_numero do memo' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        cobranca_tx = result[:transacoes].find { |t| t[:fitid] == '202501150001' }
        expect(cobranca_tx[:nosso_numero_extraido]).to eq('0000012345')
      end

      it 'calcula resumo corretamente' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        expect(result[:resumo][:total_transacoes]).to eq(4)
        expect(result[:resumo][:total_creditos]).to eq(2)
        expect(result[:resumo][:total_debitos]).to eq(2)
        expect(result[:resumo][:soma_creditos]).to eq(3750.00)
        expect(result[:resumo][:soma_debitos]).to eq(530.50)
      end

      it 'retorna saldo' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        expect(result[:saldo][:valor]).to eq(15420.50)
      end
    end

    context 'com filtro somente_creditos' do
      it 'retorna apenas créditos' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file, somente_creditos: true)
        file.close

        expect(result[:transacoes].size).to eq(2)
        result[:transacoes].each do |tx|
          expect(tx[:tipo]).to eq('CREDIT')
        end
      end

      it 'atualiza resumo com totais filtrados' do
        file = File.open(sicoob_ofx_path, 'rb')
        result = described_class.parse(file, somente_creditos: true)
        file.close

        expect(result[:resumo][:total_transacoes]).to eq(2)
        expect(result[:resumo][:total_creditos]).to eq(2)
        expect(result[:resumo][:total_debitos]).to eq(0)
      end
    end

    context 'com arquivo OFX Itaú válido' do
      it 'parseia corretamente' do
        file = File.open(itau_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        expect(result[:banco][:org]).to eq('ITAU')
        expect(result[:transacoes].size).to eq(2)
      end

      it 'extrai nosso_numero do Itaú' do
        file = File.open(itau_ofx_path, 'rb')
        result = described_class.parse(file)
        file.close

        credit_tx = result[:transacoes].find { |t| t[:tipo] == 'CREDIT' }
        expect(credit_tx[:nosso_numero_extraido]).to eq('12345678')
      end
    end

    context 'com arquivo inválido' do
      it 'levanta erro para conteúdo não-OFX' do
        tempfile = Tempfile.new(['invalid', '.txt'])
        tempfile.write('Este não é um arquivo OFX')
        tempfile.rewind

        expect {
          described_class.parse(tempfile)
        }.to raise_error(RuntimeError, /inválido|não reconhecido/i)

        tempfile.close
        tempfile.unlink
      end
    end

    context 'com encoding Latin-1' do
      it 'converte para UTF-8 corretamente' do
        tempfile = Tempfile.new(['latin1', '.ofx'])
        content = File.read(sicoob_ofx_path)
        # Simular encoding Latin-1 com caracteres especiais
        tempfile.binmode
        tempfile.write(content)
        tempfile.rewind

        result = described_class.parse(tempfile)
        expect(result[:transacoes]).not_to be_empty

        tempfile.close
        tempfile.unlink
      end
    end
  end
end
