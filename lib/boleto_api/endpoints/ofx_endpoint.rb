# frozen_string_literal: true

module BoletoApi
  module Endpoints
    # Endpoint para parsing de arquivos OFX (extrato bancário)
    class OFXEndpoint < Grape::API
      format :json
      content_type :json, 'application/json; charset=utf-8'

      resource :ofx do
        desc 'Parseia arquivo OFX e retorna JSON com transações'
        params do
          requires :file, type: File, desc: 'Arquivo OFX (multipart/form-data)'
          optional :somente_creditos, type: String, default: 'false',
                   desc: 'Filtrar apenas créditos (true/false)'
        end
        post :parse do
          file = params[:file][:tempfile]
          somente_creditos = params[:somente_creditos].to_s.downcase == 'true'

          begin
            result = Services::OFXParserService.parse(file, somente_creditos: somente_creditos)
            result
          rescue StandardError => e
            error!({ erro: e.message }, 400)
          end
        end
      end
    end
  end
end
