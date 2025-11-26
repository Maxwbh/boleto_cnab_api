# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Boleto API' do
  let(:fixtures) { JSON.parse(File.read('spec/fixtures/sample_data.json')) }
  let(:bb_data) { fixtures['banco_brasil_valido'] }
  let(:sicoob_data) { fixtures['sicoob_valido'] }
  let(:invalid_data) { fixtures['invalido_sem_nosso_numero'] }

  describe 'GET /api/health' do
    it 'returns OK status' do
      get '/api/health'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['status']).to eq('OK')
    end
  end

  describe 'GET /api/boleto/validate' do
    context 'with valid Banco do Brasil data' do
      it 'validates successfully' do
        get '/api/boleto/validate', {
          bank: 'banco_brasil',
          data: bb_data.to_json
        }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['valid']).to eq(true)
        expect(body['message']).to include('válidos')
      end
    end

    context 'with valid Sicoob data' do
      it 'validates successfully' do
        get '/api/boleto/validate', {
          bank: 'sicoob',
          data: sicoob_data.to_json
        }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['valid']).to eq(true)
      end
    end

    context 'with invalid data (missing nosso_numero)' do
      it 'returns validation errors' do
        get '/api/boleto/validate', {
          bank: 'banco_brasil',
          data: invalid_data.to_json
        }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body['valid']).to eq(false)
        expect(body).to have_key('validation_errors')
      end
    end

    context 'with malformed JSON' do
      it 'returns JSON parse error' do
        get '/api/boleto/validate', {
          bank: 'banco_brasil',
          data: fixtures['invalido_json_malformado']
        }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body['error']).to eq('JSON inválido')
      end
    end
  end

  describe 'GET /api/boleto/data' do
    context 'with valid Banco do Brasil data' do
      it 'returns boleto data including codigo_barras and linha_digitavel' do
        get '/api/boleto/data', {
          bank: 'banco_brasil',
          data: bb_data.to_json
        }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)

        expect(body).to have_key('nosso_numero')
        expect(body).to have_key('codigo_barras')
        expect(body).to have_key('linha_digitavel')
        expect(body).to have_key('numero_documento')
        expect(body['bank']).to eq('banco_brasil')

        # Verifica que codigo_barras e linha_digitavel não estão vazios
        expect(body['codigo_barras']).not_to be_nil
        expect(body['codigo_barras']).not_to be_empty
        expect(body['linha_digitavel']).not_to be_nil
        expect(body['linha_digitavel']).not_to be_empty
      end
    end

    context 'with numero_documento field' do
      it 'maps numero_documento to documento_numero correctly' do
        data_with_numero_doc = bb_data.dup
        data_with_numero_doc['numero_documento'] = 'TEST-12345'
        data_with_numero_doc.delete('documento_numero')

        get '/api/boleto/data', {
          bank: 'banco_brasil',
          data: data_with_numero_doc.to_json
        }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['numero_documento']).to eq('TEST-12345')
      end
    end
  end

  describe 'GET /api/boleto/nosso_numero' do
    context 'with valid data' do
      it 'generates nosso_numero and related fields' do
        get '/api/boleto/nosso_numero', {
          bank: 'banco_brasil',
          data: bb_data.to_json
        }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)

        expect(body).to have_key('nosso_numero')
        expect(body).to have_key('nosso_numero_dv')
        expect(body).to have_key('codigo_barras')
        expect(body).to have_key('linha_digitavel')
        expect(body).to have_key('agencia_conta_boleto')
      end
    end
  end

  describe 'GET /api/boleto' do
    context 'generating PDF for Banco do Brasil' do
      it 'returns PDF successfully' do
        get '/api/boleto', {
          bank: 'banco_brasil',
          type: 'pdf',
          data: bb_data.to_json
        }

        expect(last_response.status).to eq(200)
        expect(last_response.content_type).to include('application/pdf')
        expect(last_response.body).not_to be_empty
        expect(last_response.body.bytes[0..3]).to eq([0x25, 0x50, 0x44, 0x46]) # PDF magic number
      end
    end

    context 'generating PDF for Sicoob' do
      it 'returns PDF successfully with aceite=N' do
        get '/api/boleto', {
          bank: 'sicoob',
          type: 'pdf',
          data: sicoob_data.to_json
        }

        expect(last_response.status).to eq(200)
        expect(last_response.content_type).to include('application/pdf')
        expect(last_response.body).not_to be_empty
      end
    end

    context 'with missing type parameter' do
      it 'returns error' do
        get '/api/boleto', {
          bank: 'banco_brasil',
          data: bb_data.to_json
        }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body['error']).to include('type is missing')
      end
    end

    context 'with invalid type parameter' do
      it 'returns validation error' do
        get '/api/boleto', {
          bank: 'banco_brasil',
          type: 'invalid',
          data: bb_data.to_json
        }

        expect(last_response.status).to eq(400)
      end
    end

    context 'with invalid boleto data' do
      it 'returns validation errors' do
        get '/api/boleto', {
          bank: 'banco_brasil',
          type: 'pdf',
          data: invalid_data.to_json
        }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body['error']).to include('inválidos')
        expect(body).to have_key('validation_errors')
      end
    end
  end

  describe 'Field mapping' do
    it 'converts numero_documento to documento_numero automatically' do
      data_with_both = bb_data.dup
      data_with_both['numero_documento'] = 'NUM-DOC-123'
      data_with_both['documento_numero'] = 'DOC-NUM-456'

      get '/api/boleto/data', {
        bank: 'banco_brasil',
        data: data_with_both.to_json
      }

      expect(last_response.status).to eq(200)
      # Quando ambos existem, deve usar documento_numero
      body = JSON.parse(last_response.body)
      expect(body['numero_documento']).to eq('DOC-NUM-456')
    end
  end
end
