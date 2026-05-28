# frozen_string_literal: true

module BoletoApi
  module Endpoints
    # Endpoints para geração de arquivos de remessa CNAB
    class RemessaEndpoint < Grape::API
      format :json

      resource :remessa do
        desc 'Gera arquivo de remessa CNAB'
        params do
          requires :bank, type: String, desc: 'Nome do banco'
          requires :type, type: String, values: Config::Constants::CNAB_TYPES, desc: 'Tipo CNAB (cnab400 ou cnab240)'
          requires :data, type: File, desc: 'JSON com dados da remessa e pagamentos'
          optional :pix, type: String, default: 'false',
                   desc: 'Se "true", gera remessa com segmento PIX (boleto híbrido).'
        end
        post do
          values = JSON.parse(params[:data][:tempfile].read)
          pix = params[:pix].to_s.downcase == 'true'
          result = Services::RemessaService.generate(params[:bank], params[:type], values, pix: pix)

          if result[:valid]
            status 200
            suffix = pix ? '-pix' : ''
            content_type 'text/plain'
            header['Content-Disposition'] = "attachment; filename=remessa-#{params[:bank]}-#{params[:type]}#{suffix}.rem"
            env['api.format'] = :binary
            result[:content]
          else
            error!({
              error: 'Erro ao gerar remessa',
              validation_errors: result[:errors]
            }, 400)
          end
        end
      end
    end
  end
end
