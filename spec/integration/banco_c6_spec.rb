# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'base64'

RSpec.describe 'Banco C6 (336) — Cenarios completos' do
  let(:fixtures) { JSON.parse(File.read('spec/fixtures/sample_data.json')) }
  let(:c6_data) { fixtures['banco_c6_valido'] }

  describe 'Carteira 10' do
    it 'valida dados com carteira 10' do
      get '/api/boleto/validate', { bank: 'banco_c6', data: c6_data.to_json }

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['valid']).to eq(true)
    end

    it 'gera dados com nosso_numero correto' do
      get '/api/boleto/data', { bank: 'banco_c6', data: c6_data.to_json }

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['nosso_numero']).to eq('0012345678')
      expect(body['nosso_numero_formatado']).to eq('0012345678-9')
      expect(body['nosso_numero_dv']).to eq('9')
      expect(body['codigo_barras']).not_to be_empty
      expect(body['linha_digitavel']).not_to be_empty
    end

    it 'gera PDF com template rghost' do
      get '/api/boleto', {
        bank: 'banco_c6', type: 'pdf',
        data: c6_data.to_json
      }

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/pdf')
      expect(last_response.body.bytes[0..3]).to eq([0x25, 0x50, 0x44, 0x46])
    end

    it 'gera PDF com template prawn' do
      get '/api/boleto', {
        bank: 'banco_c6', type: 'pdf',
        template: 'prawn',
        data: c6_data.to_json
      }

      expect(last_response.status).to eq(200)
      expect(last_response.body.bytes[0..3]).to eq([0x25, 0x50, 0x44, 0x46])
    end

    it 'retorna JSON completo com include_data=true' do
      get '/api/boleto', {
        bank: 'banco_c6', type: 'pdf',
        include_data: 'true',
        data: c6_data.to_json
      }

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['nosso_numero']).to eq('0012345678')
      expect(body['nosso_numero_formatado']).to eq('0012345678-9')
      expect(body['content_base64']).not_to be_nil
      expect(body['content_type']).to eq('application/pdf')

      pdf = Base64.strict_decode64(body['content_base64'])
      expect(pdf[0..3]).to eq('%PDF')
    end
  end

  describe 'Carteira 20' do
    let(:c6_cart20) { c6_data.merge('carteira' => '20') }

    it 'valida dados com carteira 20' do
      get '/api/boleto/validate', { bank: 'banco_c6', data: c6_cart20.to_json }

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['valid']).to eq(true)
    end

    it 'gera dados com carteira 20' do
      get '/api/boleto/data', { bank: 'banco_c6', data: c6_cart20.to_json }

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['nosso_numero']).not_to be_empty
      expect(body['codigo_barras']).not_to be_empty
    end
  end

  describe 'Carteira invalida' do
    it 'rejeita carteira 30' do
      data_invalida = c6_data.merge('carteira' => '30')
      get '/api/boleto/validate', { bank: 'banco_c6', data: data_invalida.to_json }

      expect(last_response.status).to eq(400)
    end
  end
end
