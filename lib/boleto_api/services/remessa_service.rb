# frozen_string_literal: true

require_relative 'field_mapper'
require_relative '../config/constants'

module BoletoApi
  module Services
    # Serviço para geração de arquivos de remessa CNAB
    # Usa Brcobranca::Remessa.criar (v12.4+) quando disponível
    class RemessaService
      class << self
        # Gera arquivo de remessa CNAB
        # Usa Brcobranca::Remessa.criar (v12.4+) quando disponível
        #
        # @param bank [String] Nome do banco
        # @param cnab_type [String] Tipo de CNAB ('cnab400' ou 'cnab240')
        # @param values [Hash] Dados da remessa incluindo pagamentos
        # @return [Hash] { valid: Boolean, content: String/nil, errors: Array }
        def generate(bank, cnab_type, values)
          validate_cnab_type!(cnab_type)
          validate_payload!(values)

          # Usa factory method do brcobranca v12.4+ se disponível
          if remessa_factory_available?
            generate_with_factory(bank, cnab_type, values)
          else
            generate_legacy(bank, cnab_type, values)
          end
        end

        # Cria objeto de pagamento
        #
        # @param values [Hash] Dados do pagamento
        # @return [Brcobranca::Remessa::Pagamento] Objeto pagamento
        def create_pagamento(values)
          mapped_values = FieldMapper.map_pagamento(values)

          # Usa to_hash do Pagamento se disponível (v12.4+)
          if Brcobranca::Remessa::Pagamento.respond_to?(:new)
            Brcobranca::Remessa::Pagamento.new(mapped_values)
          else
            Brcobranca::Remessa::Pagamento.new(mapped_values)
          end
        end

        private

        # Verifica se Brcobranca::Remessa.criar está disponível (v12.4+)
        def remessa_factory_available?
          defined?(Brcobranca::Remessa) &&
            Brcobranca::Remessa.respond_to?(:criar)
        end

        # Gera remessa usando factory method do brcobranca v12.4+
        def generate_with_factory(bank, cnab_type, values)
          values_copy = values.dup
          pagamentos_data = values_copy.delete('pagamentos') || values_copy.delete(:pagamentos) || []

          # Converte hashes de pagamento em objetos Brcobranca::Remessa::Pagamento
          pagamentos = pagamentos_data.map { |p| create_pagamento(p) }

          # Prepara dados para o factory - symbolizar chaves pois vêm do JSON.parse (strings)
          # e Ruby 3.0+ exige symbols para keyword arguments
          factory_params = values_copy.transform_keys(&:to_sym).merge(
            banco: bank,
            formato: cnab_type.to_s,
            pagamentos: pagamentos
          )

          begin
            remessa = Brcobranca::Remessa.criar(**factory_params)

            if remessa.valid?
              content = remessa.gera_arquivo
              { valid: true, content: content, errors: [] }
            else
              { valid: false, content: nil, errors: [remessa.errors.messages] }
            end
          rescue ArgumentError => e
            { valid: false, content: nil, errors: [e.message] }
          end
        end

        # Gera remessa usando método legado (versões anteriores)
        def generate_legacy(bank, cnab_type, values)
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

        def validate_cnab_type!(cnab_type)
          unless Config::Constants.cnab_type_supported?(cnab_type)
            raise ArgumentError, "Tipo CNAB '#{cnab_type}' não suportado. Tipos disponíveis: #{Config::Constants::CNAB_TYPES.join(', ')}"
          end
        end

        # Valida que o payload é um Hash contendo 'pagamentos'.
        # Um erro comum do cliente é enviar um Array direto como root do JSON
        # ao invés de um objeto { "pagamentos": [...], ...outros campos }.
        def validate_payload!(values)
          if values.is_a?(Array)
            raise ArgumentError,
                  'Payload da remessa deve ser um objeto JSON (Hash) com chaves ' \
                  "como 'pagamentos', 'agencia', 'conta_corrente', etc. " \
                  "Recebido: Array com #{values.size} item(ns). " \
                  "Envie o array dentro de { \"pagamentos\": [...] }."
          end

          unless values.is_a?(Hash)
            raise ArgumentError,
                  "Payload da remessa deve ser um Hash, recebido: #{values.class}"
          end

          pagamentos = values['pagamentos'] || values[:pagamentos]
          if pagamentos.nil?
            raise ArgumentError, "Campo 'pagamentos' é obrigatório no payload da remessa"
          end

          unless pagamentos.is_a?(Array)
            raise ArgumentError,
                  "Campo 'pagamentos' deve ser um Array, recebido: #{pagamentos.class}"
          end

          if pagamentos.empty?
            raise ArgumentError, "Campo 'pagamentos' não pode estar vazio"
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
