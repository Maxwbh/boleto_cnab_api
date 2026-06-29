# frozen_string_literal: true

require_relative '../config/constants'

module BoletoApi
  module Services
    # Serviço para processamento de arquivos de retorno CNAB
    # Usa Brcobranca::Retorno.parse (v12.5+) quando disponível
    class RetornoService
      class << self
        # Processa arquivo de retorno CNAB
        # Usa Brcobranca::Retorno.parse (v12.5+) com detecção automática
        #
        # @param bank [String] Nome do banco
        # @param cnab_type [String] Tipo de CNAB ('cnab400' ou 'cnab240')
        # @param file [File, StringIO] Arquivo de retorno
        # @return [Hash] { valid: Boolean, pagamentos: Array, errors: Array }
        def parse(bank, cnab_type, file)
          validate_cnab_type!(cnab_type)

          # Usa Retorno.parse do brcobranca v12.5+ se disponível
          if retorno_parse_available?
            parse_with_factory(bank, file)
          else
            parse_legacy(bank, cnab_type, file)
          end
        end

        private

        # Verifica se Brcobranca::Retorno.parse está disponível (v12.5+)
        def retorno_parse_available?
          defined?(Brcobranca::Retorno) &&
            Brcobranca::Retorno.respond_to?(:parse)
        end

        # Processa retorno usando Retorno.parse (v12.5+) com detecção automática
        def parse_with_factory(bank, file)
          retorno = Brcobranca::Retorno.parse(banco: bank, arquivo: file)

          parsed_pagamentos = retorno.map do |pagamento|
            # Usa to_hash do pagamento se disponível
            if pagamento.respond_to?(:to_hash)
              pagamento.to_hash
            else
              extract_fields(pagamento)
            end
          end

          { valid: true, pagamentos: parsed_pagamentos, errors: [] }
        rescue StandardError => e
          { valid: false, pagamentos: [], errors: [e.message] }
        end

        # Processa retorno usando método legado (versões anteriores)
        def parse_legacy(bank, cnab_type, file)
          retorno_class = get_retorno_class(bank, cnab_type)
          pagamentos = retorno_class.load_lines(file)

          parsed_pagamentos = pagamentos.map do |pagamento|
            extract_fields(pagamento)
          end

          { valid: true, pagamentos: parsed_pagamentos, errors: [] }
        rescue StandardError => e
          { valid: false, pagamentos: [], errors: [e.message] }
        end

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
