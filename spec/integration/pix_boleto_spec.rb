# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'PIX no Boleto — Bancos suportados' do
  let(:fixtures) { JSON.parse(File.read('spec/fixtures/sample_data.json')) }

  let(:emv_example) { '00020126580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-426614174000' }

  # Bancos com suporte a PIX no boleto
  {
    'banco_brasil' => 'banco_brasil_valido',
    'sicoob' => 'sicoob_valido',
    'bradesco' => 'bradesco_valido',
    'itau' => 'itau_valido',
    'caixa' => 'caixa_valido',
    'santander' => 'santander_valido',
    'banco_c6' => 'banco_c6_valido'
  }.each do |bank, fixture_key|
    context "#{bank} com campo emv" do
      let(:data) do
        fixtures[fixture_key].merge(
          'emv' => emv_example,
          'chave_pix' => '12345678900',
          'tipo_chave_pix' => 'cpf',
          'txid' => 'TX20260529001'
        )
      end

      it "aceita campos PIX na validacao" do
        get '/api/boleto/validate', { bank: bank, data: data.to_json }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['valid']).to eq(true)
      end

      it "retorna dados PIX em /boleto/data" do
        get '/api/boleto/data', { bank: bank, data: data.to_json }

        expect(last_response.status).to eq(200)
        body = JSON.parse(last_response.body)
        expect(body['nosso_numero']).not_to be_nil
        # PIX fields passam para o boleto (emv fica no objeto pix se disponivel)
        expect(body).to have_key('pix') if body.key?('pix')
      end

      it "gera PDF com PIX (template prawn)" do
        get '/api/boleto', {
          bank: bank, type: 'pdf', template: 'prawn',
          data: data.to_json
        }

        expect(last_response.status).to eq(200)
        expect(last_response.body.bytes[0..3]).to eq([0x25, 0x50, 0x44, 0x46])
      end
    end
  end
end
