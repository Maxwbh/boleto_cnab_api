# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'Remessa PIX', type: :integration do
  def post_remessa(bank:, type:, data:, pix: false)
    file = Tempfile.new(['remessa', '.json'])
    file.write(data.to_json)
    file.rewind
    begin
      pix_param = pix ? '&pix=true' : ''
      post "/api/remessa?bank=#{bank}&type=#{type}#{pix_param}", {
        data: Rack::Test::UploadedFile.new(file.path, 'application/json')
      }
    ensure
      file.close
      file.unlink
    end
  end

  let(:pagamento_base) do
    {
      'nosso_numero' => '123456789',
      'data_vencimento' => '2026/12/31',
      'valor' => 1500.00,
      'sacado' => 'Joao da Silva',
      'sacado_documento' => '12345678900',
      'sacado_endereco' => 'Rua Teste, 100',
      'sacado_cidade' => 'Sao Paulo',
      'sacado_uf' => 'SP',
      'sacado_cep' => '01000000'
    }
  end

  describe 'POST /api/remessa?pix=true' do
    context 'com banco que nao suporta PIX no formato solicitado' do
      it 'retorna erro 400 para Banrisul CNAB400 PIX' do
        data = {
          'empresa_mae' => 'Empresa Teste',
          'documento_cedente' => '12345678000100',
          'agencia' => '1234',
          'conta_corrente' => '1234567',
          'convenio' => '1234567',
          'carteira' => '1',
          'pagamentos' => [pagamento_base]
        }

        post_remessa(bank: 'banrisul', type: 'cnab400', data: data, pix: true)

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        full_msg = [body['error'], body['details'], body['validation_errors'].to_s].compact.join(' ')
        expect(full_msg).to match(/PIX|pix|não disponível|Remessa/i)
      end
    end

    context 'com banco inexistente para PIX' do
      it 'retorna erro 400' do
        data = {
          'empresa_mae' => 'Empresa',
          'documento_cedente' => '12345678000100',
          'agencia' => '1234',
          'conta_corrente' => '12345',
          'pagamentos' => [pagamento_base]
        }

        post_remessa(bank: 'hsbc', type: 'cnab400', data: data, pix: true)

        expect(last_response.status).to eq(400)
      end
    end

    context 'sem pix=true (remessa normal)' do
      it 'funciona normalmente para validacao' do
        data = {
          'empresa_mae' => 'Empresa Teste',
          'documento_cedente' => '12345678000100',
          'agencia' => '3073',
          'conta_corrente' => '12345678',
          'convenio' => '01234567',
          'carteira' => '18',
          'variacao_carteira' => '017',
          'pagamentos' => []
        }

        post_remessa(bank: 'banco_brasil', type: 'cnab400', data: data, pix: false)

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body['details'] || body['error']).to match(/pagamentos|vazio/i)
      end
    end

    context 'com formato CNAB invalido para pix' do
      it 'retorna erro para tipo invalido' do
        data = {
          'empresa_mae' => 'Empresa',
          'documento_cedente' => '12345678000100',
          'agencia' => '1234',
          'conta_corrente' => '12345',
          'pagamentos' => [pagamento_base]
        }

        post_remessa(bank: 'bradesco', type: 'cnab240', data: data, pix: true)

        expect(last_response.status).to eq(400)
      end
    end
  end
end
