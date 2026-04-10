# frozen_string_literal: true

module BoletoApi
  module Middleware
    # Middleware para tratamento centralizado de erros.
    #
    # IMPORTANTE: ordem dos rescue importa. Ruby captura a primeira cláusula
    # que corresponder à classe do erro ou suas superclasses. Como
    # NoMethodError < NameError, NoMethodError deve vir ANTES de NameError.
    class ErrorHandler < Grape::Middleware::Base
      def call(env)
        @env = env
        @app.call(env)
      rescue JSON::ParserError => e
        handle(400, 'JSON inválido', e, 'JSON::ParserError')
      rescue Grape::Exceptions::ValidationErrors => e
        handle(400, 'Parâmetro inválido', e, 'ValidationError')
      rescue ArgumentError => e
        handle(400, 'Parâmetro inválido', e, 'ArgumentError')
      rescue TypeError => e
        handle(400, 'Tipo de dado inválido', e, 'TypeError')
      rescue Brcobranca::BoletoInvalido => e
        handle(400, 'Boleto inválido', e, 'BoletoInvalido')
      rescue Brcobranca::RemessaInvalida => e
        handle(400, 'Remessa inválida', e, 'RemessaInvalida')
      rescue Brcobranca::NaoImplementado => e
        handle(400, 'Operação não suportada', e, 'NaoImplementado')
      rescue NoMethodError => e
        # NoMethodError vem ANTES de NameError (é subclasse).
        # Retornamos 500 porque geralmente indica bug interno (tipo errado).
        handle(500, 'Erro ao acessar método', e, 'NoMethodError')
      rescue NameError => e
        handle(400, 'Banco ou tipo não encontrado', e, 'NameError')
      rescue StandardError => e
        handle(500, 'Erro interno', e, e.class.to_s)
      end

      private

      def handle(status, error, exception, type)
        message = exception.message
        details = message
        origin = origin_from_backtrace(exception)
        log_error(status, error, message, type, exception, origin)

        body = {
          error: error,
          details: details,
          type: type
        }
        body[:origin] = origin if origin && debug_enabled?

        [
          status,
          { 'Content-Type' => 'application/json; charset=utf-8' },
          [body.to_json]
        ]
      end

      # Extrai o primeiro frame do backtrace que pertence ao código da API
      # (ignora frames internos de gems) para facilitar debug.
      def origin_from_backtrace(exception)
        return nil unless exception.backtrace

        app_frame = exception.backtrace.find { |frame| frame.include?('/lib/boleto_api/') }
        app_frame || exception.backtrace.first
      end

      def log_error(status, error, details, type, exception, origin)
        return unless defined?(BoletoApi) && BoletoApi.respond_to?(:logger)

        # Log em duas linhas: uma resumida e uma com backtrace (se disponível)
        BoletoApi.logger.error(
          "[#{status}] #{type}: #{error} - #{details}" \
          "#{origin ? " @ #{origin}" : ''}"
        )

        # Log adicional com backtrace em nível debug ou se LOG_BACKTRACE=true
        return unless exception.backtrace && log_backtrace?

        backtrace = exception.backtrace.first(10).map { |f| "  #{f}" }.join("\n")
        BoletoApi.logger.error("Backtrace:\n#{backtrace}")
      end

      def log_backtrace?
        ENV.fetch('LOG_BACKTRACE', 'true').to_s.downcase == 'true'
      end

      def debug_enabled?
        ENV.fetch('RACK_ENV', 'production').to_s != 'production' ||
          ENV.fetch('API_DEBUG', 'false').to_s.downcase == 'true'
      end
    end
  end
end
