# frozen_string_literal: true

require_relative 'brcobranca_provider'
require_relative 'c6_provider'

module BoletoApi
  module Providers
    # Roteador do gateway: escolhe o provider certo.
    #
    # Regra:
    #   - provider explícito ("c6" | "brcobranca") tem prioridade
    #   - senão, infere pelo modo: banco_c6 + modo "api" -> C6; o resto -> brcobranca
    module Registry
      PROVIDERS = {
        'brcobranca' => BrcobrancaProvider,
        'c6' => C6Provider
      }.freeze

      module_function

      # @param provider [String, nil] nome explícito do provider
      # @param bank [String, nil] banco da cobrança
      # @param mode [String, nil] "api" (online/registrado) ou "offline" (CNAB)
      # @param credentials [Hash] credenciais do tenant (por request)
      # @param config [Hash] parâmetros não-secretos
      # @return [BaseProvider]
      def for(provider: nil, bank: nil, mode: nil, credentials: {}, config: {})
        key = resolve_key(provider, bank, mode)
        klass = PROVIDERS.fetch(key) do
          raise ArgumentError, "Provider desconhecido: #{provider.inspect} (bancos: #{PROVIDERS.keys.join(', ')})"
        end
        klass.new(credentials: credentials, config: config.merge(bank: bank))
      end

      def resolve_key(provider, bank, mode)
        return provider.to_s if provider && !provider.to_s.empty?
        return 'c6' if bank.to_s == 'banco_c6' && mode.to_s == 'api'

        'brcobranca'
      end
    end
  end
end
