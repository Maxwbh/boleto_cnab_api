# frozen_string_literal: true

require_relative 'base_provider'
require_relative '../services/boleto_service'

module BoletoApi
  module Providers
    # Provider OFFLINE baseado no brcobranca (o que a API já faz hoje).
    #
    # Gera boleto/linha digitável/CNAB sem chamar API de banco nenhum. Cobre os
    # 17 bancos suportados (inclui banco_c6 no modo offline/CNAB). Não custodia
    # segredo nem fala com a rede — é o caminho "remessa/retorno".
    #
    # registrar  -> gera dados + PDF offline
    # consultar  -> não aplicável offline (status vem do arquivo retorno/OFX)
    # baixar     -> não aplicável offline (baixa é via remessa)
    class BrcobrancaProvider < BaseProvider
      def registrar(cobranca)
        bank = cobranca['bank'] || cobranca[:bank] || config[:bank]
        values = cobranca['data'] || cobranca[:data] || cobranca

        result = Services::BoletoService.data(bank, values)
        unless result[:valid]
          return normalize_result(id: nil, status: 'erro', raw: { errors: result[:errors] })
        end

        normalize_result(
          id: result[:nosso_numero],
          status: 'registrado',
          linha_digitavel: result[:linha_digitavel] || result['linha_digitavel'],
          codigo_barras: result[:codigo_barras] || result['codigo_barras'],
          raw: result
        )
      end

      # Offline não tem consulta online; o status é conciliado via retorno/OFX
      # (endpoints RetornoEndpoint / OFXEndpoint existentes).
      def consultar(_id)
        unsupported!(:consultar)
      end

      def baixar(_id)
        unsupported!(:baixar)
      end

      # Não há webhook no modo offline.
      def normalizar_webhook(_headers, _body)
        unsupported!(:normalizar_webhook)
      end

      private

      def unsupported!(op)
        {
          error: 'operacao_nao_suportada',
          provider: 'brcobranca',
          operacao: op,
          hint: 'No modo offline/CNAB a conciliação é via arquivo retorno (RetornoEndpoint) ou OFX.'
        }
      end
    end
  end
end
