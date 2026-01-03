# frozen_string_literal: true

require_relative 'field_mapper'
require_relative '../config/constants'

module BoletoApi
  module Services
    # Serviço para geração de arquivos de remessa CNAB
    class RemessaService
      class << self
        # Gera arquivo de remessa CNAB
        #
        # @param bank [String] Nome do banco
        # @param cnab_type [String] Tipo de CNAB ('cnab400' ou 'cnab240')
        # @param values [Hash] Dados da remessa incluindo pagamentos
        # @return [Hash] { valid: Boolean, content: String/nil, errors: Array }
        def generate(bank, cnab_type, values)
          validate_cnab_type!(cnab_type)

          pagamentos_data = values.delete('pagamentos') || values.delete(:pagamentos) || []
          pagamentos = []
          errors = []

          pagamentos_data.each_with_index do |pagamento_values, index|
            pagamento = create_pagamento(pagamento_values)

            if pagamento.valid?
              pagamentos << pagamento
            else
              errors << { index: index + 1, errors: pagamento.errors.messages }
            end
          end

          if errors.any?
            return { valid: false, content: nil, errors: errors }
          end

          values[:pagamentos] = pagamentos
          remessa = create_remessa(bank, cnab_type, values)

          if remessa.valid?
            content = remessa.gera_arquivo
            { valid: true, content: content, errors: [] }
          else
            { valid: false, content: nil, errors: [remessa.errors.messages] }
          end
        end

        # Cria objeto de pagamento
        #
        # @param values [Hash] Dados do pagamento
        # @return [Brcobranca::Remessa::Pagamento] Objeto pagamento
        def create_pagamento(values)
          mapped_values = FieldMapper.map_pagamento(values)
          Brcobranca::Remessa::Pagamento.new(mapped_values)
        end

        private

        def validate_cnab_type!(cnab_type)
          unless Config::Constants.cnab_type_supported?(cnab_type)
            raise ArgumentError, "Tipo CNAB '#{cnab_type}' não suportado. Tipos disponíveis: #{Config::Constants::CNAB_TYPES.join(', ')}"
          end
        end

        def create_remessa(bank, cnab_type, values)
          remessa_class(bank, cnab_type).new(values)
        end

        def remessa_class(bank, cnab_type)
          type_class = cnab_type.to_s.split('_').map(&:capitalize).join
          bank_class = bank.to_s.split('_').map(&:capitalize).join
          Object.const_get("Brcobranca::Remessa::#{type_class}::#{bank_class}")
        rescue NameError
          raise ArgumentError, "Classe de remessa não encontrada para banco '#{bank}' e tipo '#{cnab_type}'"
        end
      end
    end
  end
end
