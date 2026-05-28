# frozen_string_literal: true

module BoletoApi
  module Services
    # Retorna informacoes detalhadas de cada banco suportado.
    # Usa Brcobranca::Bancos (v12.7.0+) quando disponivel,
    # com fallback para deteccao via const_get.
    class BankInfoService
      class << self
        def all
          if bancos_api_available?
            Brcobranca::Bancos.todos.map { |b| format_from_gem(b) }
          else
            Config::Constants::SUPPORTED_BANKS.map { |bank| format_from_detection(bank) }
          end
        end

        private

        def bancos_api_available?
          defined?(Brcobranca::Bancos) && Brcobranca::Bancos.respond_to?(:todos)
        end

        # Usa dados ricos do Brcobranca::Bancos (v12.7.0+)
        def format_from_gem(banco)
          cnab = banco[:cnab] || {}
          pix = banco[:pix] || {}

          remessa_formatos = []
          retorno_formatos = []

          cnab.each do |formato, tipos|
            remessa_formatos << "cnab#{formato}" if tipos[:remessa]
            retorno_formatos << "cnab#{formato}" if tipos[:retorno]
          end

          pix.each do |formato, _klass|
            remessa_formatos << "cnab#{formato}_pix"
          end

          {
            banco: snake_case(banco[:boleto]),
            codigo: banco[:codigo],
            nome: banco[:nome],
            boleto: {
              suportado: true,
              formatos: Config::Constants::OUTPUT_TYPES,
              pix: pix.any?,
              carteiras: banco[:carteiras] || []
            },
            remessa: {
              suportado: remessa_formatos.any?,
              formatos: remessa_formatos
            },
            retorno: {
              suportado: retorno_formatos.any?,
              formatos: retorno_formatos
            },
            extras: banco[:extras] || {}
          }
        end

        # Fallback: deteccao via const_get (pre-v12.7.0)
        def format_from_detection(bank)
          class_name = bank.to_s.split('_').map(&:capitalize).join
          {
            banco: bank,
            codigo: bank_codigo(class_name),
            nome: bank,
            boleto: {
              suportado: true,
              formatos: Config::Constants::OUTPUT_TYPES,
              pix: pix?(class_name),
              carteiras: []
            },
            remessa: detect_remessa(class_name),
            retorno: detect_retorno(class_name),
            extras: {}
          }
        end

        def detect_remessa(class_name)
          formatos = []
          formatos << 'cnab400' if class_exists?("Brcobranca::Remessa::Cnab400::#{class_name}")
          formatos << 'cnab240' if class_exists?("Brcobranca::Remessa::Cnab240::#{class_name}")
          { suportado: formatos.any?, formatos: formatos }
        end

        def detect_retorno(class_name)
          formatos = []
          formatos << 'cnab400' if class_exists?("Brcobranca::Retorno::Cnab400::#{class_name}")
          formatos << 'cnab240' if class_exists?("Brcobranca::Retorno::Cnab240::#{class_name}")
          { suportado: formatos.any?, formatos: formatos }
        end

        def snake_case(name)
          name.to_s.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        end

        def bank_codigo(class_name)
          Object.const_get("Brcobranca::Boleto::#{class_name}").new.banco
        rescue StandardError
          nil
        end

        def pix?(class_name)
          Object.const_get("Brcobranca::Boleto::#{class_name}").new.respond_to?(:emv=)
        rescue StandardError
          false
        end

        def class_exists?(full_name)
          Object.const_get(full_name)
          true
        rescue NameError
          false
        end
      end
    end
  end
end
