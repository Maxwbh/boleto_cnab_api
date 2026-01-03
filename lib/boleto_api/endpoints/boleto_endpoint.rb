# frozen_string_literal: true

module BoletoApi
  module Endpoints
    # Endpoints para operações com boletos
    class BoletoEndpoint < Grape::API
      format :json

      resource :boleto do
        desc 'Valida dados do boleto'
        params do
          requires :bank, type: String, desc: 'Nome do banco (ex: itau, banco_brasil)'
          requires :data, type: String, desc: 'Dados do boleto em JSON'
        end
        get :validate do
          values = JSON.parse(params[:data])
          result = Services::BoletoService.validate(params[:bank], values)

          if result[:valid]
            { valid: true, message: 'Dados do boleto são válidos' }
          else
            error!({
              valid: false,
              validation_errors: result[:errors],
              hint: 'Corrija os erros de validação antes de gerar o boleto'
            }, 400)
          end
        end

        desc 'Retorna dados completos do boleto (sem gerar arquivo)'
        params do
          requires :bank, type: String, desc: 'Nome do banco'
          requires :data, type: String, desc: 'Dados do boleto em JSON'
        end
        get :data do
          values = JSON.parse(params[:data])
          result = Services::BoletoService.data(params[:bank], values)

          if result[:valid]
            result.except(:valid)
          else
            error!({
              error: 'Dados do boleto inválidos',
              validation_errors: result[:errors]
            }, 400)
          end
        end

        desc 'Gera nosso_numero e dados relacionados'
        params do
          requires :bank, type: String, desc: 'Nome do banco'
          requires :data, type: String, desc: 'Dados do boleto em JSON'
        end
        get :nosso_numero do
          values = JSON.parse(params[:data])
          result = Services::BoletoService.nosso_numero(params[:bank], values)

          if result[:valid]
            result.except(:valid)
          else
            error!({
              error: 'Não foi possível gerar nosso_numero',
              validation_errors: result[:errors]
            }, 400)
          end
        end

        desc 'Gera boleto em PDF, JPG, PNG ou TIF'
        params do
          requires :bank, type: String, desc: 'Nome do banco'
          requires :type, type: String, values: Config::Constants::OUTPUT_TYPES, desc: 'Formato de saída'
          requires :data, type: String, desc: 'Dados do boleto em JSON'
        end
        get do
          values = JSON.parse(params[:data])
          result = Services::BoletoService.generate(params[:bank], values, format: params[:type])

          if result[:valid]
            content_type Config::Constants.content_type_for(params[:type])
            header['Content-Disposition'] = "attachment; filename=boleto-#{params[:bank]}.#{params[:type]}"
            env['api.format'] = :binary
            result[:content]
          else
            error!({
              error: 'Dados do boleto inválidos',
              validation_errors: result[:errors],
              hint: 'Verifique se todos os campos obrigatórios estão preenchidos'
            }, 400)
          end
        end

        desc 'Gera múltiplos boletos em um único arquivo'
        params do
          requires :type, type: String, values: Config::Constants::OUTPUT_TYPES, desc: 'Formato de saída'
          requires :data, type: File, desc: 'JSON com lista de boletos (cada um com campo "bank")'
        end
        post :multi do
          boletos_data = JSON.parse(params[:data][:tempfile].read)
          result = Services::BoletoService.generate_multi(boletos_data, format: params[:type])

          if result[:valid]
            content_type Config::Constants.content_type_for(params[:type])
            header['Content-Disposition'] = "attachment; filename=boletos-multi.#{params[:type]}"
            env['api.format'] = :binary
            result[:content]
          else
            error!({
              error: "#{result[:invalid_count]} boleto(s) com erros de validação",
              validation_errors: result[:errors],
              valid_count: result[:valid_count],
              invalid_count: result[:invalid_count]
            }, 400)
          end
        end
      end
    end
  end
end
