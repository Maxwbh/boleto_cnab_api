# frozen_string_literal: true

module BoletoApi
  module Services
    # Extrai nosso_numero do campo memo de transações OFX
    # Identifica o banco pelo campo ORG/FID do arquivo OFX
    module NossoNumeroExtractor
      class << self
        # Extrai nosso_numero do memo baseado no banco
        #
        # @param memo [String] Campo memo da transação OFX
        # @param banco_org [String] Identificador do banco (ORG ou FID do OFX)
        # @return [String, nil] Nosso número extraído ou nil
        def extrair(memo, banco_org)
          return nil if memo.nil? || memo.strip.empty?

          extractor = case banco_org.to_s.downcase
                      when /sicoob|756/   then method(:extrair_sicoob)
                      when /itau|ita|341/ then method(:extrair_itau)
                      when /brasil|001/   then method(:extrair_bb)
                      when /bradesco|237/ then method(:extrair_bradesco)
                      when /caixa|104/    then method(:extrair_caixa)
                      else method(:extrair_generico)
                      end
          extractor.call(memo.to_s)
        end

        private

        # Sicoob (756): sequência de 7 a 12 dígitos
        def extrair_sicoob(memo)
          match = memo.match(/(\d{7,12})/)
          match ? match[1] : nil
        end

        # Itaú (341): sequência de 8 dígitos
        def extrair_itau(memo)
          match = memo.match(/(\d{8})/)
          match ? match[1] : nil
        end

        # Banco do Brasil (001): sequência de 10 a 17 dígitos
        def extrair_bb(memo)
          match = memo.match(/(\d{10,17})/)
          match ? match[1] : nil
        end

        # Bradesco (237): sequência de 11 dígitos
        def extrair_bradesco(memo)
          match = memo.match(/(\d{11})/)
          match ? match[1] : nil
        end

        # Caixa (104): sequência de 14 a 17 dígitos
        def extrair_caixa(memo)
          match = memo.match(/(\d{14,17})/)
          match ? match[1] : nil
        end

        # Genérico: primeira sequência de 7 a 17 dígitos
        def extrair_generico(memo)
          match = memo.match(/(\d{7,17})/)
          match ? match[1] : nil
        end
      end
    end
  end
end
