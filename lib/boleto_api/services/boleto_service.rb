# frozen_string_literal: true

require_relative 'field_mapper'
require_relative '../config/constants'

module BoletoApi
  module Services
    # Serviço para operações com boletos
    class BoletoService
      class << self
        # Cria um objeto boleto a partir dos parâmetros
        #
        # @param bank [String] Nome do banco (ex: 'itau', 'banco_brasil')
        # @param values [Hash] Dados do boleto
        # @return [Brcobranca::Boleto::Base] Objeto boleto
        # @raise [ArgumentError] Se o banco não for suportado
        def create(bank, values)
          validate_bank!(bank)
          mapped_values = FieldMapper.map_boleto(values)
          boleto_class(bank).new(mapped_values)
        end

        # Valida os dados do boleto
        #
        # @param bank [String] Nome do banco
        # @param values [Hash] Dados do boleto
        # @return [Hash] Resultado da validação { valid: Boolean, errors: Hash }
        def validate(bank, values)
          boleto = create(bank, values)

          if boleto.valid?
            { valid: true, errors: {} }
          else
            { valid: false, errors: boleto.errors.messages }
          end
        end

        # Retorna dados completos do boleto (sem gerar arquivo)
        #
        # @param bank [String] Nome do banco
        # @param values [Hash] Dados do boleto
        # @return [Hash] Dados do boleto incluindo código de barras, linha digitável, etc
        def data(bank, values)
          boleto = create(bank, values)

          unless boleto.valid?
            return { valid: false, errors: boleto.errors.messages }
          end

          {
            valid: true,
            bank: bank,
            nosso_numero: boleto.nosso_numero_boleto,
            nosso_numero_dv: safe_call(boleto, :nosso_numero_dv),
            codigo_barras: boleto.codigo_barras,
            codigo_barras_segunda_parte: safe_call(boleto, :codigo_barras_segunda_parte),
            linha_digitavel: safe_call(boleto, :linha_digitavel),
            agencia_conta_boleto: safe_call(boleto, :agencia_conta_boleto),
            carteira: boleto.carteira,
            numero_documento: boleto.documento_numero,
            valor: boleto.valor,
            valor_documento: safe_call(boleto, :valor_documento) || boleto.valor,
            data_vencimento: boleto.data_vencimento,
            data_documento: boleto.data_documento,
            data_processamento: boleto.data_processamento,
            cedente: boleto.cedente,
            documento_cedente: boleto.documento_cedente,
            sacado: boleto.sacado,
            sacado_documento: boleto.sacado_documento,
            agencia: boleto.agencia,
            conta_corrente: boleto.conta_corrente,
            convenio: boleto.convenio
          }
        end

        # Retorna apenas nosso_numero e dados relacionados
        #
        # @param bank [String] Nome do banco
        # @param values [Hash] Dados do boleto
        # @return [Hash] Nosso número e dados relacionados
        def nosso_numero(bank, values)
          boleto = create(bank, values)

          unless boleto.valid?
            return { valid: false, errors: boleto.errors.messages }
          end

          {
            valid: true,
            nosso_numero: boleto.nosso_numero_boleto,
            nosso_numero_dv: safe_call(boleto, :nosso_numero_dv),
            codigo_barras: boleto.codigo_barras,
            linha_digitavel: safe_call(boleto, :linha_digitavel),
            agencia_conta_boleto: safe_call(boleto, :agencia_conta_boleto)
          }
        end

        # Gera arquivo do boleto (PDF, JPG, PNG, TIF)
        #
        # @param bank [String] Nome do banco
        # @param values [Hash] Dados do boleto
        # @param format [String] Formato de saída ('pdf', 'jpg', 'png', 'tif')
        # @return [Hash] { valid: Boolean, content: String/nil, errors: Hash }
        def generate(bank, values, format: 'pdf')
          validate_output_format!(format)
          boleto = create(bank, values)

          unless boleto.valid?
            return { valid: false, content: nil, errors: boleto.errors.messages }
          end

          content = boleto.send("to_#{format}".to_sym)
          { valid: true, content: content, errors: {} }
        end

        # Gera arquivo com múltiplos boletos
        #
        # @param boletos_data [Array<Hash>] Lista de boletos (cada um com 'bank' e dados)
        # @param format [String] Formato de saída
        # @return [Hash] { valid: Boolean, content: String/nil, errors: Array }
        def generate_multi(boletos_data, format: 'pdf')
          validate_output_format!(format)

          boletos = []
          errors = []

          boletos_data.each_with_index do |boleto_values, index|
            bank = boleto_values.delete('bank') || boleto_values.delete(:bank)

            if bank.nil?
              errors << { index: index + 1, error: "Campo 'bank' é obrigatório" }
              next
            end

            begin
              boleto = create(bank, boleto_values)

              if boleto.valid?
                boletos << boleto
              else
                errors << { index: index + 1, bank: bank, errors: boleto.errors.messages }
              end
            rescue ArgumentError => e
              errors << { index: index + 1, bank: bank, error: e.message }
            end
          end

          if errors.any?
            return {
              valid: false,
              content: nil,
              errors: errors,
              valid_count: boletos.size,
              invalid_count: errors.size
            }
          end

          content = Brcobranca::Boleto::Base.lote(boletos, formato: format.to_sym)
          { valid: true, content: content, errors: [], valid_count: boletos.size, invalid_count: 0 }
        end

        private

        def validate_bank!(bank)
          unless Config::Constants.bank_supported?(bank)
            raise ArgumentError, "Banco '#{bank}' não suportado. Bancos disponíveis: #{Config::Constants::SUPPORTED_BANKS.join(', ')}"
          end
        end

        def validate_output_format!(format)
          unless Config::Constants.output_type_supported?(format)
            raise ArgumentError, "Formato '#{format}' não suportado. Formatos disponíveis: #{Config::Constants::OUTPUT_TYPES.join(', ')}"
          end
        end

        def boleto_class(bank)
          class_name = bank.to_s.split('_').map(&:capitalize).join
          Object.const_get("Brcobranca::Boleto::#{class_name}")
        rescue NameError
          raise ArgumentError, "Classe de boleto não encontrada para banco '#{bank}'"
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
