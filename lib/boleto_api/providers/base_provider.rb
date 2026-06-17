# frozen_string_literal: true

module BoletoApi
  module Providers
    # Interface comum a todos os providers de cobrança (gateway).
    #
    # O gateway (boleto_cnab_api) expõe UMA API para o gestao-contrato e roteia
    # internamente para o provider certo:
    #   - BrcobrancaProvider -> 17 bancos, CNAB, geração offline
    #   - C6Provider          -> boleto/PIX registrado via API REST (mTLS + OAuth)
    #
    # Cada provider é instanciado POR REQUEST com as credenciais do tenant.
    # IMPORTANTE: o gateway é stateless de persistência — as credenciais vêm no
    # request (vindas do cofre no gestao-contrato), são usadas em memória e
    # descartadas. NUNCA persistir credencial aqui.
    #
    # Todos os métodos devolvem um Hash NORMALIZADO, igual para qualquer provider,
    # para que o gestao-contrato não saiba (nem precise saber) qual banco está atrás.
    class BaseProvider
      # @param credentials [Hash] credenciais do tenant (por request, não persiste)
      # @param config [Hash] parâmetros não-secretos (ambiente, base_url, etc.)
      def initialize(credentials: {}, config: {})
        @credentials = credentials || {}
        @config = config || {}
      end

      # Registra/emite uma cobrança.
      # @param cobranca [Hash] dados da cobrança (pagador, valor, vencimento, ...)
      # @return [Hash] resposta normalizada (ver #normalize_result)
      def registrar(_cobranca)
        raise NotImplementedError, "#{self.class}#registrar"
      end

      # Consulta o status de uma cobrança.
      def consultar(_id)
        raise NotImplementedError, "#{self.class}#consultar"
      end

      # Baixa/cancela uma cobrança.
      def baixar(_id)
        raise NotImplementedError, "#{self.class}#baixar"
      end

      # Normaliza um webhook recebido do banco para um evento padrão do gateway.
      # @return [Hash] { event:, id:, status:, paid_at:, valor:, raw: }
      def normalizar_webhook(_headers, _body)
        raise NotImplementedError, "#{self.class}#normalizar_webhook"
      end

      protected

      attr_reader :credentials, :config

      # Formato de resposta NORMALIZADO — contrato único do gateway.
      # Qualquer provider deve devolver neste shape.
      def normalize_result(id:, status:, linha_digitavel: nil, codigo_barras: nil,
                           pix_copia_cola: nil, pdf_base64: nil, raw: nil)
        {
          id: id,
          status: status, # registrado | pendente | liquidado | baixado | erro
          linha_digitavel: linha_digitavel,
          codigo_barras: codigo_barras,
          pix_copia_cola: pix_copia_cola,
          pdf_base64: pdf_base64,
          raw: raw
        }.compact
      end
    end
  end
end
