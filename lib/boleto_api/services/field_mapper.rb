# frozen_string_literal: true

module BoletoApi
  module Services
    # Serviço para mapeamento e conversão de campos
    class FieldMapper
      # Mapeamento de campos alternativos para os nomes corretos da gem
      FIELD_MAPPINGS = {
        'numero_documento' => 'documento_numero'
      }.freeze

      # Campos de data para boletos
      BOLETO_DATE_FIELDS = %w[
        data_documento
        data_vencimento
        data_processamento
      ].freeze

      # Campos de data para pagamentos/remessa
      PAGAMENTO_DATE_FIELDS = %w[
        data_vencimento
        data_emissao
        data_desconto
        data_segundo_desconto
        data_multa
      ].freeze

      class << self
        # Mapeia e converte campos para formato esperado pela gem brcobranca
        #
        # @param values [Hash] Hash com os valores do boleto
        # @param date_fields [Array<String>] Lista de campos de data a converter
        # @return [Hash] Hash com campos mapeados e datas convertidas
        def map(values, date_fields: BOLETO_DATE_FIELDS)
          result = values.dup
          map_field_names!(result)
          convert_dates!(result, date_fields)
          result
        end

        # Mapeia campos para boletos
        def map_boleto(values)
          map(values, date_fields: BOLETO_DATE_FIELDS)
        end

        # Mapeia campos para pagamentos
        def map_pagamento(values)
          result = map(values, date_fields: PAGAMENTO_DATE_FIELDS)
          result['data_vencimento'] ||= Date.today
          result
        end

        private

        def map_field_names!(values)
          FIELD_MAPPINGS.each do |from, to|
            next unless values.key?(from)

            if values.key?(to)
              # Se ambos existem, mantém o campo correto e remove o alternativo
              values.delete(from)
            else
              # Mapeia o campo alternativo para o correto
              values[to] = values.delete(from)
            end
          end
        end

        def convert_dates!(values, date_fields)
          date_fields.each do |field|
            next unless values[field]

            values[field] = parse_date(values[field])
          end
        end

        def parse_date(value)
          return value if value.is_a?(Date)
          return nil if value.nil? || value.to_s.strip.empty?

          Date.parse(value.to_s)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
