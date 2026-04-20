# frozen_string_literal: true

module BoletoApi
  module Endpoints
    # Endpoints de health check, informacoes e metadados
    class HealthEndpoint < Grape::API
      format :json

      desc 'Health check da API'
      get '/health' do
        { status: 'OK', timestamp: Time.now.iso8601 }
      end

      desc 'Informacoes da API'
      get '/info' do
        {
          name: 'Boleto CNAB API',
          version: BoletoApi::VERSION,
          supported_banks: Config::Constants::SUPPORTED_BANKS,
          supported_formats: Config::Constants::OUTPUT_TYPES,
          cnab_types: Config::Constants::CNAB_TYPES
        }
      end

      desc 'Metadados da API e gem brcobranca'
      get '/metadata' do
        brcobranca_version = Gem.loaded_specs['brcobranca']&.version&.to_s rescue 'unknown'

        {
          api: {
            name: 'Boleto CNAB API',
            version: BoletoApi::VERSION,
            ruby_version: RUBY_VERSION,
            rack_env: ENV.fetch('RACK_ENV', 'development')
          },
          brcobranca: {
            version: brcobranca_version,
            repository: 'https://github.com/Maxwbh/brcobranca'
          },
          endpoints: {
            health: 'GET /api/health',
            info: 'GET /api/info',
            metadata: 'GET /api/metadata',
            bancos: 'GET /api/bancos',
            boleto_validate: 'GET /api/boleto/validate',
            boleto_data: 'GET /api/boleto/data',
            boleto_nosso_numero: 'GET /api/boleto/nosso_numero',
            boleto_generate: 'GET /api/boleto',
            boleto_multi: 'POST /api/boleto/multi',
            remessa: 'POST /api/remessa',
            retorno: 'POST /api/retorno',
            ofx_parse: 'POST /api/ofx/parse'
          }
        }
      end

      desc 'Lista bancos suportados com capacidades detalhadas'
      get '/bancos' do
        Services::BankInfoService.all
      end
    end
  end
end
