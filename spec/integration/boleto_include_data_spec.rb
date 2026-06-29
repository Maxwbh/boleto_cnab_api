# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'tempfile'

RSpec.describe 'Boleto endpoints com include_data=true' do
  let(:fixtures) { JSON.parse(File.read('spec/fixtures/sample_data.json')) }

  describe 'GET /api/boleto?include_data=true' do
    it 'retorna JSON com dados do boleto + arquivo em base64' do
      data = fixtures['banco_brasil_valido']

      get '/api/boleto', {
        bank: 'banco_brasil',
        type: 'pdf',
        data: data.to_json,
        include_data: 'true'
      }

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/json')

      body = JSON.parse(last_response.body)

      expect(body).to have_key('nosso_numero')
      expect(body).to have_key('nosso_numero_formatado')
      expect(body).to have_key('nosso_numero_dv')
      expect(body).to have_key('codigo_barras')
      expect(body).to have_key('linha_digitavel')
      expect(body).to have_key('content_base64')
      expect(body).to have_key('content_type')
      expect(body).to have_key('filename')

      expect(body['nosso_numero']).to eq('000000123')
      expect(body['nosso_numero_formatado']).to eq('01234567000000123')
      expect(body['content_type']).to eq('application/pdf')

      pdf = Base64.strict_decode64(body['content_base64'])
      expect(pdf.bytes[0..3]).to eq([0x25, 0x50, 0x44, 0x46])
    end

    it 'sem include_data retorna binário + headers X-*' do
      data = fixtures['banco_brasil_valido']

      get '/api/boleto', {
        bank: 'banco_brasil',
        type: 'pdf',
        data: data.to_json
      }

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/pdf')
      expect(last_response.headers['X-Nosso-Numero']).to eq('000000123')
      expect(last_response.headers['X-Nosso-Numero-Formatado']).to eq('01234567000000123')
      expect(last_response.headers['X-Nosso-Numero-DV']).to eq('9')
    end
  end

  describe 'POST /api/boleto/multi?include_data=true' do
    it 'retorna JSON com array de boletos + arquivo em base64' do
      boletos = [
        fixtures['banco_brasil_valido'].merge('bank' => 'banco_brasil'),
        fixtures['sicoob_valido'].merge('bank' => 'sicoob')
      ]

      file = Tempfile.new(['multi', '.json'])
      file.write(boletos.to_json)
      file.rewind

      begin
        post '/api/boleto/multi?include_data=true', {
          type: 'pdf',
          data: Rack::Test::UploadedFile.new(file.path, 'application/json')
        }

        expect(last_response.status).to eq(200)
        expect(last_response.content_type).to include('application/json')

        body = JSON.parse(last_response.body)
        expect(body['total']).to eq(2)
        expect(body['boletos']).to be_an(Array)
        expect(body['boletos'].length).to eq(2)

        bb = body['boletos'][0]
        expect(bb['bank']).to eq('banco_brasil')
        expect(bb['nosso_numero']).to eq('000000123')
        expect(bb['nosso_numero_formatado']).to eq('01234567000000123')

        sicoob = body['boletos'][1]
        expect(sicoob['bank']).to eq('sicoob')
        expect(sicoob['nosso_numero']).to eq('0007890')

        pdf = Base64.strict_decode64(body['content_base64'])
        expect(pdf.bytes[0..3]).to eq([0x25, 0x50, 0x44, 0x46])
      ensure
        file.close
        file.unlink
      end
    end
  end
end
