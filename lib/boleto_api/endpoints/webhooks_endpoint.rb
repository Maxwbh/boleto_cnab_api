# frozen_string_literal: true

require_relative '../providers/c6_provider'

module BoletoApi
  module Endpoints
    # Recebe webhooks dos bancos, normaliza e (TODO) repassa ao gestao-contrato.
    #
    # É o ÚNICO ponto em que o gateway deixa de ser 100% "passa-pra-frente": ele
    # recebe a liquidação do C6, normaliza o evento e encaminha. O mapeamento
    # webhook -> tenant deve sair do próprio payload (sem virar banco de dados).
    class WebhooksEndpoint < Grape::API
      format :json

      resource :webhooks do
        desc 'Webhook de liquidação do C6 Bank'
        params do
          optional :id, type: String
          optional :status, type: String
        end
        post :c6 do
          body = env['api.request.body'] || params
          # TODO: validar autenticidade do webhook (assinatura/header do C6) antes de confiar.
          event = Providers::C6Provider.new.normalizar_webhook(headers, body)

          BoletoApi.logger&.info({ event: 'webhook_c6', normalized: event[:event], id: event[:id] }.to_json)

          # TODO: encaminhar `event` ao gestao-contrato (POST para URL configurada
          # em ENV, com retry). Mantém o gateway desacoplado do domínio.
          { received: true, normalized: event }
        end
      end
    end
  end
end
