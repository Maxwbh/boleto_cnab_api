# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multi Boleto API', type: :integration do
  let(:fixtures) { JSON.parse(File.read('spec/fixtures/sample_data.json')) }

  let(:boleto_bb) do
    fixtures['banco_brasil_valido'].merge('bank' => 'banco_brasil')
  end

  let(:boleto_sicoob) do
    fixtures['sicoob_valido'].merge('bank' => 'sicoob')
  end

  describe 'POST /api/boleto/multi' do
    context 'with multiple valid boletos' do
      it 'generates multi-page PDF successfully' do
        boletos = [boleto_bb, boleto_sicoob]

        # Cria arquivo temporário com JSON dos boletos
        file = Tempfile.new(['boletos', '.json'])
        file.write(boletos.to_json)
        file.rewind

        begin
          post '/api/boleto/multi', {
            type: 'pdf',
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }

          expect(last_response.status).to eq(200)
          expect(last_response.content_type).to include('application/pdf')
          expect(last_response.body).not_to be_empty

          # Verifica magic number do PDF
          expect(last_response.body.bytes[0..3]).to eq([0x25, 0x50, 0x44, 0x46])
        ensure
          file.close
          file.unlink
        end
      end
    end

    context 'with multiple boletos from same bank' do
      it 'generates PDF with multiple pages' do
        boletos = [
          boleto_bb,
          boleto_bb.merge('nosso_numero' => '456', 'valor' => 2000.00),
          boleto_bb.merge('nosso_numero' => '789', 'valor' => 3000.00)
        ]

        file = Tempfile.new(['boletos', '.json'])
        file.write(boletos.to_json)
        file.rewind

        begin
          post '/api/boleto/multi', {
            type: 'pdf',
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }

          expect(last_response.status).to eq(200)
          expect(last_response.content_type).to include('application/pdf')
        ensure
          file.close
          file.unlink
        end
      end
    end

    context 'with single boleto' do
      it 'generates PDF successfully' do
        boletos = [boleto_bb]

        file = Tempfile.new(['boletos', '.json'])
        file.write(boletos.to_json)
        file.rewind

        begin
          post '/api/boleto/multi', {
            type: 'pdf',
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }

          expect(last_response.status).to eq(200)
        ensure
          file.close
          file.unlink
        end
      end
    end

    context 'with invalid boleto in list' do
      it 'returns validation errors' do
        boleto_invalido = fixtures['invalido_sem_nosso_numero'].merge('bank' => 'banco_brasil')
        boletos = [boleto_bb, boleto_invalido]

        file = Tempfile.new(['boletos', '.json'])
        file.write(boletos.to_json)
        file.rewind

        begin
          post '/api/boleto/multi', {
            type: 'pdf',
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }

          expect(last_response.status).to eq(400)
          body = JSON.parse(last_response.body)
          expect(body).to have_key('error')
        ensure
          file.close
          file.unlink
        end
      end
    end

    context 'with empty array' do
      it 'returns validation error' do
        file = Tempfile.new(['boletos', '.json'])
        file.write([].to_json)
        file.rewind

        begin
          post '/api/boleto/multi', {
            type: 'pdf',
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }

          expect(last_response.status).to eq(400)
        ensure
          file.close
          file.unlink
        end
      end
    end

    context 'with different output types' do
      %w[pdf jpg png tif].each do |output_type|
        it "generates #{output_type.upcase} successfully" do
          file = Tempfile.new(['boletos', '.json'])
          file.write([boleto_bb].to_json)
          file.rewind

          begin
            post '/api/boleto/multi', {
              type: output_type,
              data: Rack::Test::UploadedFile.new(file.path, 'application/json')
            }

            expect(last_response.status).to eq(200)
            expect(last_response.body).not_to be_empty
          ensure
            file.close
            file.unlink
          end
        end
      end
    end

    context 'without file upload' do
      it 'returns error for missing data' do
        post '/api/boleto/multi', { type: 'pdf' }

        expect(last_response.status).to eq(400)
        body = JSON.parse(last_response.body)
        expect(body).to have_key('error')
      end
    end

    context 'with malformed JSON file' do
      it 'returns JSON parse error' do
        file = Tempfile.new(['boletos', '.json'])
        file.write('{invalid json')
        file.rewind

        begin
          post '/api/boleto/multi', {
            type: 'pdf',
            data: Rack::Test::UploadedFile.new(file.path, 'application/json')
          }

          expect(last_response.status).to eq(400)
          body = JSON.parse(last_response.body)
          expect(body['error']).to include('JSON').or include('parse')
        ensure
          file.close
          file.unlink
        end
      end
    end
  end
end
