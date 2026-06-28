# frozen_string_literal: true

require 'base64'
# Garante Prawn carregado no boot: as funções de lote (carnê/multi) do
# BoletoService referenciam Prawn::Fonts antes de qualquer extend que o
# carregaria preguiçosamente.
require 'prawn'
# As funções de lote (carnê/multi) do BoletoService referenciam Prawn::Fonts
# antes de qualquer extend que o carregaria preguiçosamente — garante no boot.

module BoletoApi
  module Endpoints
    # Endpoints de RENDERIZAÇÃO (engine BrCobrança) consumidos pelo Boleto-API (Python).
    #
    # São POST com corpo JSON e resposta normalizada — pensados para o
    # `brcobranca_proxy` do gateway. Só renderização: dados + PDF + CNAB.
    # Nada de credencial/banco-API aqui (isso é responsabilidade do gateway).
    class RenderEndpoint < Grape::API
      format :json

      resource :render do
        desc 'Renderiza um boleto: dados (linha digitável/código de barras) + PDF base64'
        params do
          requires :bank, type: String, desc: 'Nome do banco (ex: itau, banco_c6)'
          requires :data, type: Hash, desc: 'Dados do boleto'
          optional :template, type: String, values: Config::Constants::TEMPLATES,
                   default: 'prawn', desc: 'Template do PDF (prawn = sem GhostScript)'
        end
        post :boleto do
          bank = params[:bank]
          values = params[:data].to_h

          info = Services::BoletoService.data(bank, values)
          unless info[:valid]
            error!({ error: 'Dados do boleto inválidos', validation_errors: info[:errors] }, 400)
          end

          pdf = Services::BoletoService.generate(bank, values, template: params[:template])
          unless pdf[:valid]
            error!({ error: 'Falha ao gerar PDF', validation_errors: pdf[:errors] }, 400)
          end

          {
            nosso_numero: info[:nosso_numero],
            linha_digitavel: info[:linha_digitavel],
            codigo_barras: info[:codigo_barras],
            pdf_base64: Base64.strict_encode64(pdf[:content])
          }
        end

        desc 'Renderiza um carnê (N boletos) — 3 vias por A4, PDF base64 (sem GhostScript)'
        params do
          optional :bank, type: String, desc: 'Banco comum a todos (se cada boleto não trouxer o seu)'
          requires :boletos, type: Array, desc: 'Lista de boletos (cada um com seus dados)'
          optional :template, type: String, values: %w[carne prawn],
                   default: 'carne', desc: 'carne = 3 vias A4 (PrawnCarne); prawn = 1 boleto/página'
        end
        post :carne do
          boletos = params[:boletos].map do |b|
            h = b.to_h
            params[:bank] ? h.merge('bank' => params[:bank]) : h
          end

          # 'carne' = PrawnCarne.lote_carne (3 vias A4, sem GhostScript).
          result = Services::BoletoService.generate_multi(boletos, template: params[:template])
          unless result[:valid]
            error!({ error: 'Falha ao gerar carnê', validation_errors: result[:errors] }, 400)
          end

          { pdf_base64: Base64.strict_encode64(result[:content]) }
        end

        desc 'Renderiza arquivo de remessa CNAB (texto)'
        params do
          requires :bank, type: String, desc: 'Nome do banco'
          requires :type, type: String, values: Config::Constants::CNAB_TYPES, desc: 'cnab400 ou cnab240'
          requires :data, type: Hash, desc: 'Dados da remessa e pagamentos'
          optional :pix, type: Boolean, default: false, desc: 'Segmento PIX (boleto híbrido)'
        end
        post :remessa do
          result = Services::RemessaService.generate(params[:bank], params[:type], params[:data].to_h, pix: params[:pix])
          unless result[:valid]
            error!({ error: 'Erro ao gerar remessa', validation_errors: result[:errors] }, 400)
          end

          { cnab: result[:content] }
        end
      end
    end
  end
end
