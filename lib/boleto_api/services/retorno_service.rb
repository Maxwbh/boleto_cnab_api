# frozen_string_literal: true

require_relative '../config/constants'

module BoletoApi
  module Services
    # Serviço para processamento de arquivos de retorno CNAB
    class RetornoService
      class << self
        # Processa arquivo de retorno CNAB
        #
        # @param bank [String] Nome do banco
        # @param cnab_type [String] Tipo de CNAB ('cnab400' ou 'cnab240')
        # @param file [File, StringIO] Arquivo de retorno
        # @return [Hash] { valid: Boolean, pagamentos: Array, errors: Array }
        def parse(bank, cnab_type, file)
          validate_cnab_type!(cnab_type)

          retorno_class = get_retorno_class(bank, cnab_type)
          pagamentos = retorno_class.load_lines(file)

          parsed_pagamentos = pagamentos.map do |pagamento|
            extract_fields(pagamento)
          end

          { valid: true, pagamentos: parsed_pagamentos, errors: [] }
        rescue StandardError => e
          { valid: false, pagamentos: [], errors: [e.message] }
        end

        private

        def validate_cnab_type!(cnab_type)
          unless Config::Constants.cnab_type_supported?(cnab_type)
            raise ArgumentError, "Tipo CNAB '#{cnab_type}' não suportado. Tipos disponíveis: #{Config::Constants::CNAB_TYPES.join(', ')}"
          end
        end

        def get_retorno_class(bank, cnab_type)
          type_class = cnab_type.to_s.split('_').map(&:capitalize).join
          bank_class = bank.to_s.split('_').map(&:capitalize).join
          Object.const_get("Brcobranca::Retorno::#{type_class}::#{bank_class}")
        rescue NameError
          raise ArgumentError, "Classe de retorno não encontrada para banco '#{bank}' e tipo '#{cnab_type}'"
        end

        def extract_fields(pagamento)
          Config::Constants::RETORNO_FIELDS.each_with_object({}) do |field, hash|
            hash[field] = safe_call(pagamento, field)
          end
        end

        def safe_call(object, method)
          return nil unless object.respond_to?(method)

          object.send(method)
        rescue StandardError
          nil
        end
      end
    end
  end
end
