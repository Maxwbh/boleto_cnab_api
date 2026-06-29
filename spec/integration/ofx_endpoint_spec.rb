# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'POST /api/ofx/parse' do
  let(:sicoob_ofx_path) { File.join(__dir__, '../fixtures/extrato_sicoob.ofx') }
  let(:itau_ofx_path) { File.join(__dir__, '../fixtures/extrato_itau.ofx') }

  context 'com arquivo OFX válido' do
    it 'retorna JSON com transações' do
      post '/api/ofx/parse', {
        file: Rack::Test::UploadedFile.new(sicoob_ofx_path, 'application/octet-stream')
      }

      expect(last_response.status).to eq(201)
      body = JSON.parse(last_response.body)

      expect(body).to have_key('banco')
      expect(body).to have_key('conta')
      expect(body).to have_key('transacoes')
      expect(body).to have_key('resumo')
      expect(body['banco']['org']).to eq('SICOOB')
      expect(body['transacoes'].size).to eq(4)
    end
  end

  context 'com filtro somente_creditos=true' do
    it 'retorna apenas créditos' do
      post '/api/ofx/parse', {
        file: Rack::Test::UploadedFile.new(sicoob_ofx_path, 'application/octet-stream'),
        somente_creditos: 'true'
      }

      expect(last_response.status).to eq(201)
      body = JSON.parse(last_response.body)

      body['transacoes'].each do |tx|
        expect(tx['tipo']).to eq('CREDIT')
      end
      expect(body['transacoes'].size).to eq(2)
    end
  end

  context 'com arquivo OFX Itaú' do
    it 'parseia corretamente' do
      post '/api/ofx/parse', {
        file: Rack::Test::UploadedFile.new(itau_ofx_path, 'application/octet-stream')
      }

      expect(last_response.status).to eq(201)
      body = JSON.parse(last_response.body)

      expect(body['banco']['org']).to eq('ITAU')
      expect(body['transacoes'].size).to eq(2)
    end
  end

  context 'sem arquivo' do
    it 'retorna erro 400' do
      post '/api/ofx/parse'

      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body['details']).to include('file is missing')
    end
  end

  context 'com arquivo inválido' do
    it 'retorna erro 400 para arquivo TXT' do
      tempfile = Tempfile.new(['invalid', '.txt'])
      tempfile.write('Este não é um arquivo OFX válido')
      tempfile.rewind

      post '/api/ofx/parse', {
        file: Rack::Test::UploadedFile.new(tempfile.path, 'text/plain')
      }

      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body['erro']).to include('inválido')

      tempfile.close
      tempfile.unlink
    end
  end

  context 'extração de nosso_numero' do
    it 'extrai nosso_numero do memo para Sicoob' do
      post '/api/ofx/parse', {
        file: Rack::Test::UploadedFile.new(sicoob_ofx_path, 'application/octet-stream')
      }

      body = JSON.parse(last_response.body)
      cobranca = body['transacoes'].find { |t| t['fitid'] == '202501150001' }
      expect(cobranca['nosso_numero_extraido']).to eq('0000012345')
    end

    it 'extrai nosso_numero do memo para Itaú' do
      post '/api/ofx/parse', {
        file: Rack::Test::UploadedFile.new(itau_ofx_path, 'application/octet-stream')
      }

      body = JSON.parse(last_response.body)
      credit = body['transacoes'].find { |t| t['tipo'] == 'CREDIT' }
      expect(credit['nosso_numero_extraido']).to eq('12345678')
    end
  end
end
