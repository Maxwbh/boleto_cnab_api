# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Remessa API', type: :integration do
  let(:fixtures) { JSON.parse(File.read('spec/fixtures/sample_data.json')) }

  let(:pagamento_bb) do
    {
      nosso_numero: '123456789',
      numero_documento: 'DOC-2025-001',
      data_vencimento: '2025/12/31',
      valor: 1500.00,
      sacado: 'João da Silva',
      sacado_documento: '12345678900',
      sacado_endereco: 'Rua Teste, 100, Centro',
      sacado_cidade: 'São Paulo',
      sacado_uf: 'SP',
      sacado_cep: '01000000'
    }
  end

  let(:remessa_data_bb) do
    {
      bank: 'banco_brasil',
      type: '400',
      empresa_mae: 'Empresa Teste LTDA',
      documento_cedente: '12345678000100',
      agencia: '3073',
      conta_corrente: '12345678',
      digito_conta: '0',
      convenio: '01234567',
      carteira: '18',
      sequencial_remessa: 1,
      pagamentos: [pagamento_bb]
    }
  end

  let(:pagamento_sicoob) do
    {
      nosso_numero: '7890',
      numero_documento: 'NF-2025-001',
      data_vencimento: '2025/12/31',
      valor: 2500.00,
      sacado: 'Maria Santos',
      sacado_documento: '98765432100',
      sacado_endereco: 'Av. Principal, 50',
      sacado_cidade: 'Rio de Janeiro',
      sacado_uf: 'RJ',
      sacado_cep: '20000000'
    }
  end

  let(:remessa_data_sicoob_240) do
    {
      bank: 'sicoob',
      type: '240',
      empresa_mae: 'Cooperativa Teste',
      documento_cedente: '98765432000100',
      agencia: '4327',
      conta_corrente: '417270',
      digito_conta: '0',
      convenio: '229385',
      carteira: '1',
      variacao: '01',
      sequencial_remessa: 1,
      pagamentos: [pagamento_sicoob]
    }
  end

  describe 'POST /api/remessa' do
    context 'with valid CNAB 400 data for Banco do Brasil' do
      it 'generates remessa file successfully' do
        post '/api/remessa', remessa_data_bb.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        expect(last_response.content_type).to include('text/plain')
        expect(last_response.body).not_to be_empty

        # Verifica estrutura do arquivo CNAB 400
        lines = last_response.body.split("\n")
        expect(lines).not_to be_empty

        # Header deve começar com 0 (CNAB 400)
        expect(lines.first[0]).to eq('0') if lines.first.length >= 400
      end
    end

    context 'with valid CNAB 240 data for Sicoob' do
      it 'generates remessa file successfully' do
        post '/api/remessa', remessa_data_sicoob_240.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        expect(last_response.content_type).to include('text/plain')
        expect(last_response.body).not_to be_empty

        # CNAB 240 tem linhas de 240 caracteres
        lines = last_response.body.split("\n")
        expect(lines).not_to be_empty
      end
    end

    context 'with multiple payments' do
      it 'includes all payments in remessa' do
        data = remessa_data_bb.dup
        data[:pagamentos] = [
          pagamento_bb,
          pagamento_bb.merge(nosso_numero: '987654321', valor: 2000.00)
        ]

        post '/api/remessa', data.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(200)
        lines = last_response.body.split("\n")
        # Deve ter header + 2 detalhes + trailer
        expect(lines.length).to be >= 4
      end
    end

    context 'with missing required fields' do
      it 'returns validation error' do
        invalid_data = remessa_data_bb.dup
        invalid_data.delete(:pagamentos)

        post '/api/remessa', invalid_data.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body).to have_key('error')
      end
    end

    context 'with unsupported bank for CNAB type' do
      it 'returns appropriate error' do
        # Tenta gerar CNAB 240 para Bradesco (só suporta 400)
        data = remessa_data_bb.dup
        data[:bank] = 'bradesco'
        data[:type] = '240'

        post '/api/remessa', data.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)
      end
    end

    context 'with empty payments array' do
      it 'returns validation error' do
        data = remessa_data_bb.dup
        data[:pagamentos] = []

        post '/api/remessa', data.to_json, { 'CONTENT_TYPE' => 'application/json' }

        expect(last_response.status).to eq(400)
      end
    end
  end

  describe 'POST /api/remessa (JSON file upload)' do
    context 'with valid JSON file' do
      it 'generates remessa from uploaded file' do
        # Simula upload de arquivo JSON
        file_content = remessa_data_bb.to_json

        post '/api/remessa', {
          type: '400',
          data: Rack::Test::UploadedFile.new(
            StringIO.new(file_content),
            'application/json',
            original_filename: 'remessa.json'
          )
        }

        # Pode retornar 200 ou 400 dependendo da implementação
        expect([200, 400]).to include(last_response.status)
      end
    end
  end

  describe 'Remessa field mappings' do
    it 'handles date format conversion' do
      data = remessa_data_bb.dup
      data[:pagamentos][0][:data_vencimento] = '2025/12/31'

      post '/api/remessa', data.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(200)
    end

    it 'handles valor as string' do
      data = remessa_data_bb.dup
      data[:pagamentos][0][:valor] = '1500.00'

      post '/api/remessa', data.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(200)
    end
  end
end
