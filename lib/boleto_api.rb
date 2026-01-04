# frozen_string_literal: true

require 'brcobranca'
require 'grape'
require 'logger'
require 'json'

# Módulos internos
require_relative 'boleto_api/version'
require_relative 'boleto_api/config/constants'
require_relative 'boleto_api/services/field_mapper'
require_relative 'boleto_api/services/boleto_service'
require_relative 'boleto_api/services/remessa_service'
require_relative 'boleto_api/services/retorno_service'
require_relative 'boleto_api/middleware/error_handler'
require_relative 'boleto_api/middleware/request_logger'
require_relative 'boleto_api/endpoints/health_endpoint'
require_relative 'boleto_api/endpoints/boleto_endpoint'
require_relative 'boleto_api/endpoints/remessa_endpoint'
require_relative 'boleto_api/endpoints/retorno_endpoint'

module BoletoApi
  class << self
    # Logger da aplicação
    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.formatter = proc do |severity, datetime, _progname, msg|
          "#{datetime.strftime('%Y-%m-%dT%H:%M:%S.%3N%z')} [#{severity}] #{msg}\n"
        end
      end
    end

    # Permite configurar um logger customizado
    attr_writer :logger
  end

  # Servidor principal da API
  class Server < Grape::API
    version 'v1', using: :header, vendor: 'BoletoApi'
    format :json
    prefix :api

    # Middlewares
    use Middleware::RequestLogger
    use Middleware::ErrorHandler

    # Monta endpoints
    mount Endpoints::HealthEndpoint
    mount Endpoints::BoletoEndpoint
    mount Endpoints::RemessaEndpoint
    mount Endpoints::RetornoEndpoint
  end
end
