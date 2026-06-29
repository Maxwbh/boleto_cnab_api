# frozen_string_literal: true

module BoletoApi
  module Endpoints
    # Endpoint de health check
    class HealthEndpoint < Grape::API
      format :json

      desc 'Health check da API'
      get '/health' do
        { status: 'OK', timestamp: Time.now.iso8601 }
      end

      desc 'Informações da API'
      get '/info' do
        {
          name: 'Boleto CNAB API',
          version: BoletoApi::VERSION,
          supported_banks: Config::Constants::SUPPORTED_BANKS,
          supported_formats: Config::Constants::OUTPUT_TYPES,
          cnab_types: Config::Constants::CNAB_TYPES
        }
      end
    end
  end
end
