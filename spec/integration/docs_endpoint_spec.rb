# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Docs endpoints (Swagger / OpenAPI)' do
  describe 'GET /api/openapi.json' do
    it 'retorna a especificação OpenAPI em JSON' do
      get '/api/openapi.json'

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/json')

      spec = JSON.parse(last_response.body)
      expect(spec['openapi']).to eq('3.0.3')
      expect(spec['info']['version']).to eq(BoletoApi::VERSION)
    end

    it 'inclui todos os 12 endpoints principais' do
      get '/api/openapi.json'
      spec = JSON.parse(last_response.body)
      paths = spec['paths'].keys

      %w[
        /api/health /api/info /api/metadata /api/bancos
        /api/boleto/validate /api/boleto/data /api/boleto/nosso_numero
        /api/boleto /api/boleto/multi
        /api/remessa /api/retorno /api/ofx/parse
      ].each do |path|
        expect(paths).to include(path), "Endpoint #{path} faltando no OpenAPI"
      end
    end
  end

  describe 'GET /api/openapi.yaml' do
    it 'retorna a especificação OpenAPI em YAML' do
      get '/api/openapi.yaml'

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('application/yaml')
      expect(last_response.body).to start_with('openapi: 3.0.3')
    end
  end

  describe 'GET /api/docs' do
    it 'retorna Swagger UI navegável' do
      get '/api/docs'

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to include('text/html')
      expect(last_response.body).to include('SwaggerUIBundle')
      expect(last_response.body).to include('/api/openapi.json')
      expect(last_response.body).to include(BoletoApi::VERSION)
    end
  end
end
