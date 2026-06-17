# frozen_string_literal: true

require_relative '../providers/registry'

module BoletoApi
  module Endpoints
    # Endpoint UNIFICADO do gateway de cobrança.
    #
    # O gestao-contrato fala só com este recurso; o gateway roteia para o provider
    # (BrCobrança offline ou C6 online) e devolve uma resposta NORMALIZADA.
    #
    # SEGURANÇA: usa POST com credencial no BODY (nunca em query/URL). O
    # RequestLogger loga apenas path + query string — o body não é logado, então
    # a credencial do tenant não vaza em log.
    class CobrancaEndpoint < Grape::API
      format :json

      helpers do
        def provider_from_params
          Providers::Registry.for(
            provider: params[:provider],
            bank: params[:bank],
            mode: params[:mode],
            credentials: params[:credentials] || {},
            config: params[:config] || {}
          )
        end
      end

      resource :cobranca do
        desc 'Cria/registra uma cobrança (roteia para o provider)'
        params do
          optional :provider, type: String, values: %w[brcobranca c6], desc: 'Provider explícito'
          optional :bank, type: String, desc: 'Banco (ex: banco_c6)'
          optional :mode, type: String, values: %w[api offline], desc: 'api=registrado online; offline=CNAB'
          optional :credentials, type: Hash, desc: 'Credenciais do tenant (não persistidas, não logadas)'
          optional :config, type: Hash, desc: 'Parâmetros não-secretos (environment, base_url...)'
          requires :cobranca, type: Hash, desc: 'Dados da cobrança (pagador, valor, vencimento...)'
        end
        post do
          provider_from_params.registrar(params[:cobranca])
        end

        desc 'Consulta o status de uma cobrança'
        params do
          requires :id, type: String
          optional :provider, type: String, values: %w[brcobranca c6]
          optional :bank, type: String
          optional :mode, type: String, values: %w[api offline]
          optional :credentials, type: Hash
          optional :config, type: Hash
        end
        post ':id/consultar' do
          provider_from_params.consultar(params[:id])
        end

        desc 'Baixa/cancela uma cobrança'
        params do
          requires :id, type: String
          optional :provider, type: String, values: %w[brcobranca c6]
          optional :bank, type: String
          optional :mode, type: String, values: %w[api offline]
          optional :credentials, type: Hash
          optional :config, type: Hash
        end
        post ':id/baixar' do
          provider_from_params.baixar(params[:id])
        end
      end
    end
  end
end
