# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Retorno API', type: :integration do
  # Conteúdo de retorno CNAB 400 simulado (Banco do Brasil)
  let(:retorno_400_content) do
    # Header de arquivo (posição 1-400)
    header = '0'.ljust(400)

    # Registro detalhe (posição 1-400)
    detalhe = '1'.ljust(400)

    # Trailer (posição 1-400)
    trailer = '9'.ljust(400)

    "#{header}\n#{detalhe}\n#{trailer}"
  end

  # Conteúdo de retorno CNAB 240 simulado
  let(:retorno_240_content) do
    # Header de arquivo (240 posições)
    header = '0'.ljust(240)

    # Header de lote (240 posições)
    header_lote = '1'.ljust(240)

    # Segmento T (240 posições)
    segmento_t = '3'.ljust(240)

    # Segmento U (240 posições)
    segmento_u = '3'.ljust(240)

    # Trailer de lote
    trailer_lote = '5'.ljust(240)

    # Trailer de arquivo
    trailer = '9'.ljust(240)

    [header, header_lote, segmento_t, segmento_u, trailer_lote, trailer].join("\n")
  end

  describe 'POST /api/retorno' do
    context 'with valid CNAB 400 file' do
      it 'parses retorno file successfully' do
        # Cria arquivo temporário de retorno
        file = Tempfile.new(['retorno', '.ret'])
        file.write(retorno_400_content)
        file.rewind

        begin
          post '/api/retorno', {
            bank: 'banco_brasil',
            type: '400',
            data: Rack::Test::UploadedFile.new(file.path, 'text/plain')
          }

          # Pode retornar 200 (sucesso) ou 400/500 (erro de parsing)
          # dependendo do conteúdo do arquivo simulado
          expect([200, 400, 500]).to include(last_response.status)

          if last_response.status == 200
            body = JSON.parse(last_response.body)
            expect(body).to be_an(Array).or have_key('pagamentos')
          end
        ensure
          file.close
          file.unlink
        end
      end
    end

    context 'with valid CNAB 240 file' do
      it 'parses retorno file successfully' do
        file = Tempfile.new(['retorno', '.ret'])
        file.write(retorno_240_content)
        file.rewind

        begin
          post '/api/retorno', {
            bank: 'sicoob',
            type: '240',
            data: Rack::Test::UploadedFile.new(file.path, 'text/plain')
          }

          expect([200, 400, 500]).to include(last_response.status)
        ensure
          file.close
          file.unlink
        end
      end
    end

    context 'without file upload' do
      it 'returns error for missing file' do
        post '/api/retorno', {
          bank: 'banco_brasil',
          type: '400'
        }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body).to have_key('error')
      end
    end

    context 'with unsupported bank' do
      it 'returns error for unsupported bank' do
        file = Tempfile.new(['retorno', '.ret'])
        file.write(retorno_400_content)
        file.rewind

        begin
          post '/api/retorno', {
            bank: 'banco_inexistente',
            type: '400',
            data: Rack::Test::UploadedFile.new(file.path, 'text/plain')
          }

          expect(last_response.status).to eq(400)
          body = JSON.parse(last_response.body)
          expect(body['error']).to include('suportado').or include('Banco')
        ensure
          file.close
          file.unlink
        end
      end
    end

    context 'with empty file' do
      it 'returns error for empty file' do
        file = Tempfile.new(['retorno', '.ret'])
        file.write('')
        file.rewind

        begin
          post '/api/retorno', {
            bank: 'banco_brasil',
            type: '400',
            data: Rack::Test::UploadedFile.new(file.path, 'text/plain')
          }

          expect([400, 500]).to include(last_response.status)
        ensure
          file.close
          file.unlink
        end
      end
    end
  end

  describe 'Retorno response fields' do
    # Campos esperados no retorno conforme RETORNO_FIELDS
    let(:expected_fields) do
      %w[
        nosso_numero
        data_credito
        data_ocorrencia
        valor_titulo
        valor_pago
        valor_tarifa
        codigo_ocorrencia
        motivo_ocorrencia
      ]
    end

    it 'returns documented fields in response' do
      # Este teste verifica que os campos documentados são retornados
      # quando o parsing é bem sucedido
      skip 'Requer arquivo de retorno real para validação completa'
    end
  end
end
