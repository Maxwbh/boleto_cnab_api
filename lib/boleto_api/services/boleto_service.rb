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

          # Filtra campos não suportados pela classe de boleto do banco
          # (ex: digito_conta não existe em Bradesco)
          klass = boleto_class(bank)
          filtered_values = filter_supported_attributes(klass, mapped_values)
          klass.new(filtered_values)
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
        # Usa o método to_hash do brcobranca v12.5+ quando disponível
        #
        # @param bank [String] Nome do banco
        # @param values [Hash] Dados do boleto
        # @return [Hash] Dados do boleto incluindo código de barras, linha digitável, etc
        def data(bank, values)
          boleto = create(bank, values)

          unless boleto.valid?
            return { valid: false, errors: boleto.errors.messages }
          end

          # Tenta to_hash (v12.5+), com fallback seguro em caso de erro
          # (ex: Sicredi pode lançar Brcobranca::BoletoInvalido em codigo_barras)
          if boleto.respond_to?(:to_hash)
            begin
              hash = boleto.to_hash.merge(valid: true, bank: bank)
            rescue StandardError
              hash = build_boleto_hash(boleto, bank)
            end
            normalize_public_contract(hash, boleto)
          else
            build_boleto_hash(boleto, bank)
          end
        end

        # Retorna apenas nosso_numero e dados relacionados
        # Usa dados_calculados do brcobranca v12.5+ quando disponível
        #
        # @param bank [String] Nome do banco
        # @param values [Hash] Dados do boleto
        # @return [Hash] Nosso número e dados relacionados
        def nosso_numero(bank, values)
          boleto = create(bank, values)

          unless boleto.valid?
            return { valid: false, errors: boleto.errors.messages }
          end

          nn_formatado = boleto.respond_to?(:nosso_numero_boleto) ? boleto.nosso_numero_boleto.to_s : boleto.nosso_numero.to_s

          base = {
            valid: true,
            nosso_numero: boleto.nosso_numero.to_s,
            nosso_numero_formatado: nn_formatado,
            nosso_numero_dv: safe_call(boleto, :nosso_numero_dv),
            codigo_barras: boleto.codigo_barras,
            linha_digitavel: safe_call(boleto, :linha_digitavel),
            agencia_conta_boleto: safe_call(boleto, :agencia_conta_boleto)
          }

          if boleto.respond_to?(:dados_calculados)
            boleto.dados_calculados.merge(base)
          else
            base
          end
        end

        # Gera arquivo do boleto (PDF, JPG, PNG, TIF)
        #
        # @param bank [String] Nome do banco
        # @param values [Hash] Dados do boleto
        # @param format [String] Formato de saída ('pdf', 'jpg', 'png', 'tif')
        # @return [Hash] { valid:, content:, errors:, metadata: { nosso_numero, nosso_numero_formatado, nosso_numero_dv } }
        def generate(bank, values, format: 'pdf')
          validate_output_format!(format)
          boleto = create(bank, values)

          unless boleto.valid?
            return { valid: false, content: nil, errors: boleto.errors.messages }
          end

          content = boleto.send("to_#{format}".to_sym)
          {
            valid: true,
            content: content,
            errors: {},
            metadata: boleto_metadata(boleto, bank)
          }
        end

        # Gera arquivo com múltiplos boletos
        #
        # @param boletos_data [Array<Hash>] Lista de boletos (cada um com 'bank' e dados)
        # @param format [String] Formato de saída
        # @return [Hash] { valid: Boolean, content: String/nil, errors: Array }
        def generate_multi(boletos_data, format: 'pdf')
          validate_output_format!(format)

          if boletos_data.nil? || boletos_data.empty?
            return {
              valid: false,
              content: nil,
              errors: [{ error: 'Lista de boletos não pode estar vazia' }],
              valid_count: 0,
              invalid_count: 0
            }
          end

          boletos_with_bank = []
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
                boletos_with_bank << { bank: bank, boleto: boleto }
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
              valid_count: boletos_with_bank.size,
              invalid_count: errors.size
            }
          end

          boletos = boletos_with_bank.map { |bb| bb[:boleto] }
          content = Brcobranca::Boleto::Base.lote(boletos, formato: format.to_sym)
          metadata = boletos_with_bank.map { |bb| boleto_metadata(bb[:boleto], bb[:bank]) }
          {
            valid: true,
            content: content,
            errors: [],
            valid_count: boletos.size,
            invalid_count: 0,
            metadata: metadata
          }
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

        # Filtra hash mantendo apenas atributos com setters na classe alvo
        # Evita NoMethodError quando um campo não é suportado pelo banco
        # (ex: digito_conta existe em Caixa/Santander mas não em Bradesco)
        def filter_supported_attributes(klass, values)
          instance = klass.new
          values.each_with_object({}) do |(key, value), hash|
            setter = "#{key}="
            hash[key] = value if instance.respond_to?(setter)
          end
        rescue StandardError
          # Se a instanciação vazia falhar, passa tudo (comportamento original)
          values
        end

        # Normaliza o hash para o contrato público da API.
        def normalize_public_contract(hash, boleto)
          hash[:nosso_numero] = boleto.nosso_numero.to_s
          hash[:nosso_numero_formatado] = boleto.respond_to?(:nosso_numero_boleto) ? boleto.nosso_numero_boleto.to_s : hash[:nosso_numero]
          hash[:nosso_numero_dv] = safe_call(boleto, :nosso_numero_dv)
          hash.delete(:nosso_numero_boleto)

          if hash.key?(:documento_numero) && !hash.key?(:numero_documento)
            hash[:numero_documento] = hash[:documento_numero]
          end

          hash
        end

        def safe_call(object, method)
          return nil unless object.respond_to?(method)

          object.send(method)
        rescue StandardError
          nil
        end

        # Extrai metadados do boleto para uso em headers HTTP ou response JSON.
        # Usa safe_call para todos os campos calculados, pois algumas classes
        # (ex: Sicredi) podem lançar Brcobranca::BoletoInvalido em codigo_barras
        # mesmo quando o boleto passa na validação.
        def boleto_metadata(boleto, bank)
          nn_formatado = safe_call(boleto, :nosso_numero_boleto).to_s
          nn_formatado = boleto.nosso_numero.to_s if nn_formatado.empty?
          {
            bank: bank,
            nosso_numero: boleto.nosso_numero.to_s,
            nosso_numero_formatado: nn_formatado,
            nosso_numero_dv: safe_call(boleto, :nosso_numero_dv).to_s,
            codigo_barras: safe_call(boleto, :codigo_barras).to_s,
            linha_digitavel: safe_call(boleto, :linha_digitavel).to_s
          }
        end

        # Fallback para versões anteriores do brcobranca (< v12.5)
        # ou quando to_hash falha (safe_call em todos os campos calculados)
        def build_boleto_hash(boleto, bank)
          {
            valid: true,
            bank: bank,
            nosso_numero: boleto.nosso_numero.to_s,
            nosso_numero_formatado: safe_call(boleto, :nosso_numero_boleto).to_s,
            nosso_numero_dv: safe_call(boleto, :nosso_numero_dv),
            codigo_barras: safe_call(boleto, :codigo_barras),
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
      end
    end
  end
end
