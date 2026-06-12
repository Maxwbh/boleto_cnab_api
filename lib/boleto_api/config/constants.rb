# frozen_string_literal: true

module BoletoApi
  module Config
    # Constantes centralizadas da API
    module Constants
      # Bancos suportados para geração de boletos
      # Ordem: principais bancos brasileiros (código bancário)
      SUPPORTED_BANKS = %w[
        banco_brasil
        itau
        bradesco
        caixa
        santander
        sicoob
        sicredi
        banrisul
        banestes
        banco_nordeste
        banco_brasilia
        banco_c6
        unicred
        credisis
        safra
        citibank
        hsbc
        ailos
      ].freeze

      # Bancos suportados para remessa CNAB400
      CNAB400_BANKS = %w[
        banco_brasil
        banrisul
        bradesco
        itau
        citibank
        santander
        sicoob
        banco_nordeste
        banco_brasilia
        banco_c6
        unicred
        credisis
      ].freeze

      # Bancos suportados para remessa CNAB240
      CNAB240_BANKS = %w[
        caixa
        banco_brasil
        santander
        sicoob
        sicredi
        unicred
        ailos
      ].freeze

      # Tipos de saída suportados
      OUTPUT_TYPES = %w[pdf jpg png tif].freeze

      # Templates de geração de PDF
      #  - rghost : padrão, usa GhostScript (todos os formatos)
      #  - prawn  : Ruby puro, sem GhostScript (apenas PDF)
      #  - carne  : carnê (1 via por página; 3 vias por A4 no /multi), Prawn
      TEMPLATES = %w[rghost prawn carne].freeze

      # Templates que geram apenas PDF (Prawn)
      PDF_ONLY_TEMPLATES = %w[prawn carne].freeze

      # Campos opcionais de tema visual aplicados pelos templates Prawn.
      # São attr_accessor na Base do brcobranca (v12.10+) e passam direto no JSON.
      THEME_FIELDS = %w[
        logo_empresa
        cor_marca
        marca_dagua
        rodape_contato
        fonte_ttf
        parcela_atual
        total_parcelas
      ].freeze

      # Tipos de CNAB suportados
      CNAB_TYPES = %w[cnab400 cnab240].freeze

      # Campos de retorno do arquivo CNAB
      RETORNO_FIELDS = %i[
        codigo_registro
        codigo_ocorrencia
        data_ocorrencia
        agencia_com_dv
        agencia_sem_dv
        cedente_com_dv
        convenio
        nosso_numero
        tipo_cobranca
        tipo_cobranca_anterior
        natureza_recebimento
        carteira_variacao
        desconto
        iof
        carteira
        comando
        data_liquidacao
        data_vencimento
        valor_titulo
        banco_recebedor
        agencia_recebedora_com_dv
        especie_documento
        data_credito
        valor_tarifa
        outras_despesas
        juros_desconto
        iof_desconto
        valor_abatimento
        desconto_concedito
        valor_recebido
        juros_mora
        outros_recebimento
        abatimento_nao_aproveitado
        valor_lancamento
        indicativo_lancamento
        indicador_valor
        valor_ajuste
        sequencial
        arquivo
        motivo_ocorrencia
        documento_numero
      ].freeze

      # Content types para cada formato de saída
      CONTENT_TYPES = {
        'pdf' => 'application/pdf',
        'jpg' => 'image/jpeg',
        'png' => 'image/png',
        'tif' => 'image/tiff'
      }.freeze

      class << self
        def bank_supported?(bank)
          SUPPORTED_BANKS.include?(bank.to_s.downcase.tr('-', '_'))
        end

        def cnab_type_supported?(type)
          CNAB_TYPES.include?(type.to_s.downcase)
        end

        def output_type_supported?(type)
          OUTPUT_TYPES.include?(type.to_s.downcase)
        end

        def template_supported?(template)
          TEMPLATES.include?(template.to_s.downcase)
        end

        def pdf_only_template?(template)
          PDF_ONLY_TEMPLATES.include?(template.to_s.downcase)
        end

        def content_type_for(output_type)
          CONTENT_TYPES[output_type.to_s.downcase] || 'application/octet-stream'
        end
      end
    end
  end
end
