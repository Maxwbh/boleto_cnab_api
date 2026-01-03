# frozen_string_literal: true

module BoletoApi
  module Middleware
    # Middleware para tratamento centralizado de erros
    class ErrorHandler < Grape::Middleware::Base
      def call(env)
        @env = env
        @app.call(env)
      rescue JSON::ParserError => e
        error_response(400, 'JSON inválido', e.message, 'JSON::ParserError')
      rescue ArgumentError => e
        error_response(400, 'Parâmetro inválido', e.message, 'ArgumentError')
      rescue Brcobranca::BoletoInvalido => e
        error_response(400, 'Boleto inválido', e.message, 'BoletoInvalido')
      rescue Brcobranca::RemessaInvalida => e
        error_response(400, 'Remessa inválida', e.message, 'RemessaInvalida')
      rescue NameError => e
        error_response(400, 'Banco ou tipo não encontrado', e.message, 'NameError')
      rescue NoMethodError => e
        error_response(500, 'Erro ao acessar campo', e.message, 'NoMethodError')
      rescue StandardError => e
        error_response(500, 'Erro interno', e.message, e.class.to_s)
      end

      private

      def error_response(status, error, details, type)
        log_error(status, error, details, type)

        body = {
          error: error,
          details: details,
          type: type
        }

        [
          status,
          { 'Content-Type' => 'application/json' },
          [body.to_json]
        ]
      end

      def log_error(status, error, details, type)
        return unless defined?(BoletoApi) && BoletoApi.respond_to?(:logger)

        BoletoApi.logger.error("[#{status}] #{type}: #{error} - #{details}")
      end
    end
  end
end
