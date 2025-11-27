# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multi-Bank Validation' do
  let(:fixtures) { JSON.parse(File.read('spec/fixtures/sample_data.json')) }

  # Lista de bancos para testar
  let(:banks) do
    {
      'banco_brasil' => fixtures['banco_brasil_valido'],
      'sicoob' => fixtures['sicoob_valido'],
      'bradesco' => fixtures['bradesco_valido'],
      'itau' => fixtures['itau_valido'],
      'caixa' => fixtures['caixa_valido'],
      'santander' => fixtures['santander_valido']
    }
  end

  describe 'GET /api/boleto/validate' do
    context 'validating all supported banks' do
      banks.each do |bank_name, data|
        it "validates #{bank_name} successfully" do
          get '/api/boleto/validate', {
            bank: bank_name,
            data: data.to_json
          }

          expect(last_response.status).to eq(200)
          body = JSON.parse(last_response.body)
          expect(body['valid']).to eq(true)
        end
      end
    end
  end

  describe 'GET /api/boleto/data' do
    context 'getting data from all supported banks' do
      banks.each do |bank_name, data|
        it "returns data for #{bank_name} without errors" do
          get '/api/boleto/data', {
            bank: bank_name,
            data: data.to_json
          }

          expect(last_response.status).to eq(200)
          body = JSON.parse(last_response.body)

          # Campos obrigatórios que todos os bancos devem ter
          expect(body).to have_key('bank')
          expect(body).to have_key('nosso_numero')
          expect(body).to have_key('codigo_barras')
          expect(body['bank']).to eq(bank_name)
          expect(body['codigo_barras']).not_to be_nil
          expect(body['codigo_barras']).not_to be_empty

          # Campos que podem ser nil (depende do banco)
          # Mas devem estar presentes no response
          expect(body).to have_key('linha_digitavel')
          expect(body).to have_key('nosso_numero_dv')
          expect(body).to have_key('agencia_conta_boleto')

          # Log para debug
          puts "\n#{bank_name.upcase}:"
          puts "  codigo_barras: #{body['codigo_barras']}"
          puts "  linha_digitavel: #{body['linha_digitavel'] || 'nil'}"
          puts "  nosso_numero: #{body['nosso_numero']}"
        end
      end
    end

    context 'handling safe method access' do
      it 'returns nil for linha_digitavel when method does not exist' do
        # Testar especificamente o Sicoob que pode não ter linha_digitavel
        get '/api/boleto/data', {
          bank: 'sicoob',
          data: fixtures['sicoob_valido'].to_json
        }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)

        # Deve ter a chave, mas pode ser nil
        expect(body).to have_key('linha_digitavel')
        # Não deve causar erro 500
        expect(last_response.status).not_to eq(500)
      end
    end
  end

  describe 'GET /api/boleto/nosso_numero' do
    context 'generating nosso_numero for all banks' do
      banks.each do |bank_name, data|
        it "generates nosso_numero for #{bank_name}" do
          get '/api/boleto/nosso_numero', {
            bank: bank_name,
            data: data.to_json
          }

          expect(last_response.status).to eq(200)
          body = JSON.parse(last_response.body)

          expect(body).to have_key('nosso_numero')
          expect(body).to have_key('codigo_barras')
          expect(body['nosso_numero']).not_to be_nil
          expect(body['codigo_barras']).not_to be_nil
        end
      end
    end
  end

  describe 'GET /api/boleto (PDF generation)' do
    context 'generating PDF for major banks' do
      # Testar apenas os principais para economizar tempo
      major_banks = {
        'banco_brasil' => fixtures['banco_brasil_valido'],
        'sicoob' => fixtures['sicoob_valido'],
        'itau' => fixtures['itau_valido']
      }

      major_banks.each do |bank_name, data|
        it "generates PDF for #{bank_name}" do
          get '/api/boleto', {
            bank: bank_name,
            type: 'pdf',
            data: data.to_json
          }

          expect(last_response.status).to eq(200)
          expect(last_response.content_type).to include('application/pdf')
          expect(last_response.body).not_to be_empty

          # Verificar magic number do PDF
          pdf_header = last_response.body.bytes[0..3]
          expect(pdf_header).to eq([0x25, 0x50, 0x44, 0x46]) # %PDF
        end
      end
    end
  end

  describe 'Field mapping compatibility' do
    context 'numero_documento vs documento_numero' do
      banks.each do |bank_name, data|
        it "handles numero_documento correctly for #{bank_name}" do
          # Enviar apenas numero_documento (sem documento_numero)
          test_data = data.dup
          test_data['numero_documento'] = "TEST-#{bank_name.upcase}-001"
          test_data.delete('documento_numero')

          get '/api/boleto/data', {
            bank: bank_name,
            data: test_data.to_json
          }

          expect(last_response.status).to eq(200)
          body = JSON.parse(last_response.body)

          # Deve retornar o numero_documento mapeado
          expect(body['numero_documento']).to eq("TEST-#{bank_name.upcase}-001")
        end
      end
    end
  end

  describe 'Error resilience' do
    it 'does not crash with NoMethodError for any bank' do
      banks.each do |bank_name, data|
        get '/api/boleto/data', {
          bank: bank_name,
          data: data.to_json
        }

        # Nunca deve retornar 500 por NoMethodError
        expect(last_response.status).not_to eq(500)

        # Se retornou erro, deve ser 400 (validação)
        if last_response.status >= 400
          body = JSON.parse(last_response.body)
          expect(body['error']).not_to include('NoMethodError')
          expect(body['error']).not_to include('undefined method')
        end
      end
    end
  end
end
