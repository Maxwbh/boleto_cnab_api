# frozen_string_literal: true

require_relative 'base_provider'
require_relative 'c6_client'

module BoletoApi
  module Providers
    # Provider ONLINE para a API REST do C6 Bank (Coalizão C6 / boleto registrado).
    #
    # Cada tenant (imobiliária) tem a própria conta C6 e envia credencial + cert.
    # O gateway registra boleto/PIX, consulta e baixa via API — sem remessa/retorno.
    #
    # ATENÇÃO: os PATHS e o SHAPE dos payloads abaixo são placeholders. Os valores
    # reais saem da documentação em developers.c6bank.com.br após o cadastro/
    # homologação. Marcados com TODO para fechar na sandbox.
    class C6Provider < BaseProvider
      def registrar(cobranca)
        # TODO: confirmar endpoint e contrato do "boleto registrado" do C6.
        payload = build_boleto_payload(cobranca)
        data = client.request(:post, '/v1/bank-slips', payload)

        normalize_result(
          id: data['id'] || data['nossoNumero'],
          status: map_status(data['status']) || 'registrado',
          linha_digitavel: data['digitableLine'] || data['linhaDigitavel'],
          codigo_barras: data['barcode'] || data['codigoBarras'],
          pix_copia_cola: data.dig('pix', 'emv') || data['pixCopiaECola'],
          raw: data
        )
      end

      def consultar(id)
        # TODO: confirmar endpoint de consulta.
        data = client.request(:get, "/v1/bank-slips/#{id}")
        normalize_result(
          id: id,
          status: map_status(data['status']) || 'pendente',
          linha_digitavel: data['digitableLine'],
          raw: data
        )
      end

      def baixar(id)
        # TODO: confirmar endpoint/método de baixa (DELETE vs PATCH cancel).
        data = client.request(:delete, "/v1/bank-slips/#{id}")
        normalize_result(id: id, status: 'baixado', raw: data)
      end

      # Normaliza o webhook de liquidação do C6 para o evento padrão do gateway.
      # O gateway é quem recebe o webhook (não o gestao-contrato); aqui ele vira
      # um evento neutro que o gateway repassa adiante.
      def normalizar_webhook(_headers, body)
        # TODO: confirmar shape real do webhook (assinatura/headers de validação).
        {
          event: 'cobranca.atualizada',
          id: body['id'] || body['nossoNumero'],
          status: map_status(body['status']),
          paid_at: body['paymentDate'] || body['dataPagamento'],
          valor: body['paidValue'] || body['valorPago'],
          raw: body
        }.compact
      end

      private

      def client
        @client ||= C6Client.new(credentials: symbolize(credentials), config: symbolize(config))
      end

      # Mapeia o status do C6 para o vocabulário normalizado do gateway.
      def map_status(c6_status)
        case c6_status.to_s.upcase
        when 'REGISTERED', 'REGISTRADO', 'ACTIVE' then 'registrado'
        when 'PAID', 'SETTLED', 'LIQUIDADO' then 'liquidado'
        when 'CANCELLED', 'WRITTEN_OFF', 'BAIXADO' then 'baixado'
        when '' then nil
        else 'pendente'
        end
      end

      # TODO: mapear os campos do gestao-contrato para o contrato do C6.
      def build_boleto_payload(cobranca)
        {
          amount: cobranca['valor'] || cobranca[:valor],
          dueDate: cobranca['vencimento'] || cobranca[:vencimento],
          ourNumber: cobranca['nosso_numero'] || cobranca[:nosso_numero],
          payer: cobranca['pagador'] || cobranca[:pagador]
        }.compact
      end

      def symbolize(hash)
        (hash || {}).transform_keys(&:to_sym)
      end
    end
  end
end
