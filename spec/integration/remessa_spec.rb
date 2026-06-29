# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

# Testes de integração do endpoint POST /api/remessa
#
# Obs: a geração real de arquivos CNAB requer muitos campos específicos
# por banco (variacao_carteira, convenio, tipo de documento, etc).
# Os testes de integração focam em validar:
# - Estrutura da API (parâmetros, upload de arquivo, resposta HTTP)
# - Tratamento de erros
# - Casos de invalidação óbvios
#
# Para testes de geração real de CNAB, veja spec/unit/services/remessa_service_spec.rb
RSpec.describe 'Remessa API', type: :integration do
  let(:pagamento_bb) do
    {
      'nosso_numero' => '123456789',
      'numero_documento' => 'DOC-2025-001',
      'data_vencimento' => '2025/12/31',
      'valor' => 1500.00,
      'sacado' => 'Joao da Silva',
      'sacado_documento' => '12345678900',
      'sacado_endereco' => 'Rua Teste, 100, Centro',
      'sacado_cidade' => 'Sao Paulo',
      'sacado_uf' => 'SP',
      'sacado_cep' => '01000000'
    }
  end

  let(:remessa_data_bb) do
    {
      'empresa_mae' => 'Empresa Teste LTDA',
      'documento_cedente' => '12345678000100',
      'agencia' => '3073',
      'conta_corrente' => '12345678',
      'digito_conta' => '0',
      'convenio' => '01234567',
      'carteira' => '18',
      'variacao_carteira' => '017',
      'sequencial_remessa' => 1,
      'pagamentos' => [pagamento_bb]
    }
  end

  def post_remessa(bank:, type:, data:)
    file = Tempfile.new(['remessa', '.json'])
    file.write(data.to_json)
    file.rewind
    begin
      post "/api/remessa?bank=#{bank}&type=#{type}", {
        data: Rack::Test::UploadedFile.new(file.path, 'application/json')
      }
    ensure
      file.close
      file.unlink
    end
  end

  describe 'POST /api/remessa' do
    context 'with missing required fields' do
      it 'returns validation error when pagamentos is missing' do
        invalid_data = remessa_data_bb.dup
        invalid_data.delete('pagamentos')

        post_remessa(bank: 'banco_brasil', type: 'cnab400', data: invalid_data)

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body).to have_key('error')
      end
    end

    context 'with empty payments array' do
      it 'returns validation error' do
        data = remessa_data_bb.dup
        data['pagamentos'] = []

        post_remessa(bank: 'banco_brasil', type: 'cnab400', data: data)

        expect(last_response.status).to eq(400)
      end
    end

    context 'with invalid CNAB type' do
      it 'returns validation error' do
        post_remessa(bank: 'banco_brasil', type: 'cnab999', data: remessa_data_bb)

        expect(last_response.status).to eq(400)
      end
    end

    context 'with missing type parameter' do
      it 'returns validation error' do
        file = Tempfile.new(['remessa', '.json'])
        file.write(remessa_data_bb.to_json)
        file.rewind
        begin
          post '/api/remessa?bank=banco_brasil', {
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }
        ensure
          file.close
          file.unlink
        end

        expect(last_response.status).to eq(400)
      end
    end

    context 'with missing bank parameter' do
      it 'returns validation error' do
        file = Tempfile.new(['remessa', '.json'])
        file.write(remessa_data_bb.to_json)
        file.rewind
        begin
          post '/api/remessa?type=cnab400', {
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }
        ensure
          file.close
          file.unlink
        end

        expect(last_response.status).to eq(400)
      end
    end

    context 'with malformed JSON file' do
      it 'returns JSON parse error' do
        file = Tempfile.new(['remessa', '.json'])
        file.write('{invalid json')
        file.rewind
        begin
          post '/api/remessa?bank=banco_brasil&type=cnab400', {
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }
        ensure
          file.close
          file.unlink
        end

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body['error']).to match(/JSON|inv/i)
      end
    end
  end
end
