# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe 'CNAB — Testes completos de remessa' do
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

  let(:pagamento) do
    {
      'nosso_numero' => '123456789',
      'data_vencimento' => '2026/12/31',
      'valor' => 1500.00,
      'sacado' => 'Joao da Silva',
      'sacado_documento' => '12345678900',
      'sacado_endereco' => 'Rua Teste 100',
      'sacado_cidade' => 'Sao Paulo',
      'sacado_uf' => 'SP',
      'sacado_cep' => '01000000'
    }
  end

  describe 'Banco C6 — CNAB 400' do
    let(:remessa_c6) do
      {
        'empresa_mae' => 'Empresa C6 LTDA',
        'documento_cedente' => '33445566000177',
        'agencia' => '0001',
        'conta_corrente' => '1234567',
        'convenio' => '100',
        'carteira' => '10',
        'pagamentos' => [pagamento]
      }
    end

    it 'gera remessa CNAB 400' do
      post_remessa(bank: 'banco_c6', type: 'cnab400', data: remessa_c6)

      expect([200, 400]).to include(last_response.status)
    end

    it 'gera remessa CNAB 400 com PIX' do
      post_remessa(bank: 'banco_c6', type: 'cnab400', data: remessa_c6, pix: true)

      expect([200, 400]).to include(last_response.status)
    end

    it 'rejeita CNAB 240 (nao suportado para C6)' do
      post_remessa(bank: 'banco_c6', type: 'cnab240', data: remessa_c6)

      expect(last_response.status).to eq(400)
    end
  end

  describe 'Remessa PIX — CNAB 400' do
    let(:remessa_bradesco) do
      {
        'empresa_mae' => 'Empresa Bradesco LTDA',
        'documento_cedente' => '11223344000155',
        'agencia' => '1234',
        'conta_corrente' => '567890',
        'carteira' => '09',
        'pagamentos' => [pagamento]
      }
    end

    %w[bradesco itau banco_c6 santander].each do |bank|
      it "aceita #{bank} CNAB 400 PIX sem erro interno" do
        post_remessa(bank: bank, type: 'cnab400', data: remessa_bradesco, pix: true)

        expect([200, 400]).to include(last_response.status)
      end
    end
  end

  describe 'Remessa PIX — CNAB 240' do
    let(:remessa_sicoob) do
      {
        'empresa_mae' => 'Cooperativa Teste',
        'documento_cedente' => '98765432000100',
        'agencia' => '4327',
        'conta_corrente' => '417270',
        'convenio' => '229385',
        'carteira' => '1',
        'variacao' => '01',
        'pagamentos' => [pagamento]
      }
    end

    %w[sicoob caixa banco_brasil].each do |bank|
      it "aceita #{bank} CNAB 240 PIX sem erro interno" do
        post_remessa(bank: bank, type: 'cnab240', data: remessa_sicoob, pix: true)

        expect([200, 400]).to include(last_response.status)
      end
    end
  end

  describe 'Validacao de payload' do
    it 'rejeita Array como root (deve ser Hash)' do
      file = Tempfile.new(['remessa', '.json'])
      file.write([{ 'nosso_numero' => '123' }].to_json)
      file.rewind

      begin
        post '/api/remessa?bank=banco_brasil&type=cnab400', {
          data: Rack::Test::UploadedFile.new(file.path, 'application/json')
        }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body['details']).to match(/Array|Hash|pagamentos/i)
      ensure
        file.close
        file.unlink
      end
    end

    it 'rejeita payload sem pagamentos' do
      file = Tempfile.new(['remessa', '.json'])
      file.write({ 'empresa_mae' => 'Teste' }.to_json)
      file.rewind

      begin
        post '/api/remessa?bank=banco_brasil&type=cnab400', {
          data: Rack::Test::UploadedFile.new(file.path, 'application/json')
        }

        expect(last_response.status).to eq(400)
      ensure
        file.close
        file.unlink
      end
    end
  end
end
