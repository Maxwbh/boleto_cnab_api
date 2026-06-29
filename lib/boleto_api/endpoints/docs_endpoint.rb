# frozen_string_literal: true

require 'yaml'

module BoletoApi
  module Endpoints
    # Serve Swagger UI navegavel e a especificacao OpenAPI 3.0
    class DocsEndpoint < Grape::API
      SPEC_PATH = File.expand_path('../../../docs/openapi.yaml', __dir__).freeze

      # OpenAPI spec em JSON (consumivel por Postman, Insomnia, geradores SDK)
      desc 'Especificacao OpenAPI 3.0 (JSON)'
      get '/openapi.json' do
        content_type 'application/json; charset=utf-8'
        env['api.format'] = :txt
        YAML.safe_load_file(SPEC_PATH, permitted_classes: [Date, Time, Symbol], aliases: true).to_json
      rescue StandardError => e
        error!({ error: 'OpenAPI spec não encontrada', details: e.message }, 500)
      end

      # OpenAPI spec em YAML (formato original)
      desc 'Especificacao OpenAPI 3.0 (YAML)'
      get '/openapi.yaml' do
        content_type 'application/yaml; charset=utf-8'
        env['api.format'] = :txt
        File.read(SPEC_PATH)
      rescue Errno::ENOENT => e
        error!({ error: 'OpenAPI spec não encontrada', details: e.message }, 500)
      end

      # Swagger UI interativa (HTML)
      desc 'Swagger UI navegavel'
      get '/docs' do
        content_type 'text/html; charset=utf-8'
        env['api.format'] = :txt
        version = BoletoApi::VERSION
        brcobranca = Gem.loaded_specs['brcobranca']&.version&.to_s || 'unknown'

        <<~HTML
          <!DOCTYPE html>
          <html lang="pt-BR">
          <head>
            <meta charset="UTF-8">
            <title>Boleto CNAB API — Documentacao</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
            <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@5/favicon-32x32.png">
            <style>
              body { margin: 0; }
              .topbar { background: #1b1b1b; padding: 12px 24px; color: white; }
              .topbar h1 { margin: 0; font: 600 18px sans-serif; }
              .topbar small { color: #999; font: 12px sans-serif; }
            </style>
          </head>
          <body>
            <div class="topbar">
              <h1>Boleto CNAB API</h1>
              <small>Versao #{version} - brcobranca #{brcobranca}</small>
            </div>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
            <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
            <script>
              window.onload = () => {
                window.ui = SwaggerUIBundle({
                  url: '/api/openapi.json',
                  dom_id: '#swagger-ui',
                  deepLinking: true,
                  presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
                  layout: 'StandaloneLayout',
                  tryItOutEnabled: true
                });
              };
            </script>
          </body>
          </html>
        HTML
      end
    end
  end
end
