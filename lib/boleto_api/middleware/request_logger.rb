# frozen_string_literal: true

module BoletoApi
  module Middleware
    # Middleware para logging de requisições
    class RequestLogger < Grape::Middleware::Base
      def call(env)
        @env = env
        start_time = Time.now

        log_request_start(env)

        status, headers, response = @app.call(env)

        log_request_end(env, status, start_time)

        [status, headers, response]
      rescue StandardError => e
        log_request_error(env, e, start_time)
        raise
      end

      private

      def log_request_start(env)
        return unless logger

        method = env['REQUEST_METHOD']
        path = env['PATH_INFO']
        query = env['QUERY_STRING']

        logger.info({
          event: 'request_start',
          method: method,
          path: path,
          query: query.empty? ? nil : query,
          timestamp: timestamp
        }.compact.to_json)
      end

      def log_request_end(env, status, start_time)
        return unless logger

        duration_ms = ((Time.now - start_time) * 1000).round(2)
        method = env['REQUEST_METHOD']
        path = env['PATH_INFO']

        logger.info({
          event: 'request_end',
          method: method,
          path: path,
          status: status,
          duration_ms: duration_ms,
          timestamp: timestamp
        }.to_json)
      end

      def log_request_error(env, error, start_time)
        return unless logger

        duration_ms = ((Time.now - start_time) * 1000).round(2)
        method = env['REQUEST_METHOD']
        path = env['PATH_INFO']

        logger.error({
          event: 'request_error',
          method: method,
          path: path,
          error_class: error.class.to_s,
          error_message: error.message,
          duration_ms: duration_ms,
          timestamp: timestamp
        }.to_json)
      end

      def logger
        return @logger if defined?(@logger)

        @logger = if defined?(BoletoApi) && BoletoApi.respond_to?(:logger)
                    BoletoApi.logger
                  end
      end

      def timestamp
        Time.now.strftime('%Y-%m-%dT%H:%M:%S.%3N%z')
      end
    end
  end
end
