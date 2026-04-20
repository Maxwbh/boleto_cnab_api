# frozen_string_literal: true

module BoletoApi
  module Services
    # Retorna informacoes detalhadas de cada banco suportado,
    # detectando capacidades diretamente das classes da gem brcobranca.
    class BankInfoService
      class << self
        def all
          Config::Constants::SUPPORTED_BANKS.map { |bank| info(bank) }
        end

        def info(bank)
          class_name = bank_class_name(bank)
          {
            banco: bank,
            codigo: bank_codigo(class_name),
            boleto: {
              suportado: true,
              formatos: Config::Constants::OUTPUT_TYPES,
              pix: pix?(class_name)
            },
            remessa: remessa_info(class_name),
            retorno: retorno_info(class_name)
          }
        end

        private

        def remessa_info(class_name)
          formatos = []
          formatos << 'cnab400' if class_exists?("Brcobranca::Remessa::Cnab400::#{class_name}")
          formatos << 'cnab240' if class_exists?("Brcobranca::Remessa::Cnab240::#{class_name}")
          formatos << 'cnab400_pix' if class_exists?("Brcobranca::Remessa::Cnab400::#{class_name}Pix")
          formatos << 'cnab240_pix' if class_exists?("Brcobranca::Remessa::Cnab240::#{class_name}Pix")
          { suportado: formatos.any?, formatos: formatos }
        end

        def retorno_info(class_name)
          formatos = []
          formatos << 'cnab400' if class_exists?("Brcobranca::Retorno::Cnab400::#{class_name}")
          formatos << 'cnab240' if class_exists?("Brcobranca::Retorno::Cnab240::#{class_name}")
          { suportado: formatos.any?, formatos: formatos }
        end

        def bank_class_name(bank)
          bank.to_s.split('_').map(&:capitalize).join
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
