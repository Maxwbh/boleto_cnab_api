# frozen_string_literal: true

module BoletoApi
  module Endpoints
    # Endpoints para processamento de arquivos de retorno CNAB
    class RetornoEndpoint < Grape::API
      format :json

      resource :retorno do
        desc 'Processa arquivo de retorno CNAB'
        params do
          requires :bank, type: String, desc: 'Nome do banco'
          requires :type, type: String, values: Config::Constants::CNAB_TYPES, desc: 'Tipo CNAB (cnab400 ou cnab240)'
          requires :data, type: File, desc: 'Arquivo de retorno CNAB'
        end
        post do
          file = params[:data][:tempfile]
          result = Services::RetornoService.parse(params[:bank], params[:type], file)

          if result[:valid]
            result[:pagamentos]
          else
            error!({
              error: 'Erro ao processar retorno',
              details: result[:errors]
            }, 400)
          end
        end
      end
    end
  end
end
