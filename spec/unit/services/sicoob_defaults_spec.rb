# frozen_string_literal: true

require 'spec_helper'

# Cobre dois ajustes de robustez para o Sicoob (756):
# 1. aceite/especie_documento em branco -> caem no default correto do brcobrança
# 2. `variacao` (existe no boleto, não na remessa CNAB 240) -> ignorado, sem erro
RSpec.describe 'Sicoob — defaults e remessa robusta' do
  let(:boleto_sicoob) do
    {
      'valor' => 100.0, 'cedente' => 'Empresa X', 'documento_cedente' => '12345678000123',
      'sacado' => 'Fulano', 'sacado_documento' => '12345678901',
      'agencia' => '1234', 'conta_corrente' => '12345', 'convenio' => '123456', 'nosso_numero' => '1'
    }
  end

  let(:remessa_sicoob) do
    {
      'agencia' => '1234', 'conta_corrente' => '12345', 'convenio' => '123456', 'carteira' => '1',
      'modalidade_carteira' => '01', 'tipo_formulario' => '4', 'parcela' => '01',
      'empresa_mae' => 'EMPRESA', 'documento_cedente' => '12345678000123',
      'versao_layout_arquivo_opcao' => '081',
      'pagamentos' => [{
        'valor' => 100.0, 'data_vencimento' => '2026-07-10', 'nosso_numero' => '1',
        'documento_sacado' => '12345678901', 'nome_sacado' => 'Fulano', 'endereco_sacado' => 'Rua A',
        'bairro_sacado' => 'Centro', 'cep_sacado' => '01001000', 'cidade_sacado' => 'SP', 'uf_sacado' => 'SP'
      }]
    }
  end

  describe BoletoApi::Services::FieldMapper do
    it 'remove campos defaultáveis em branco (para o brcobrança aplicar o default)' do
      mapped = described_class.map_boleto('aceite' => '', 'especie_documento' => '   ')
      expect(mapped).not_to have_key('aceite')
      expect(mapped).not_to have_key('especie_documento')
    end

    it 'mantém o valor quando preenchido' do
      mapped = described_class.map_boleto('aceite' => 'N', 'especie_documento' => 'DM')
      expect(mapped['aceite']).to eq('N')
      expect(mapped['especie_documento']).to eq('DM')
    end
  end

  describe BoletoApi::Services::BoletoService do
    it 'boleto Sicoob válido com aceite/especie_documento em branco (cai no default)' do
      boleto = described_class.create('sicoob', boleto_sicoob.merge('aceite' => '', 'especie_documento' => ''))
      expect(boleto.aceite).to eq('S')
      expect(boleto.especie_documento).to eq('DM')
      expect(boleto).to be_valid
    end
  end

  describe BoletoApi::Services::RemessaService do
    it 'ignora `variacao` na remessa CNAB 240 Sicoob em vez de gerar erro' do
      result = described_class.generate('sicoob', 'cnab240', remessa_sicoob.merge('variacao' => '01'))
      expect(result[:valid]).to be(true)
      expect(result[:content]).to be_a(String)
      expect(result[:content].bytesize).to be > 0
    end

    it 'gera a remessa normalmente sem `variacao`' do
      result = described_class.generate('sicoob', 'cnab240', remessa_sicoob)
      expect(result[:valid]).to be(true)
    end

    it 'ignora campo extra dentro do pagamento (ex: `cedente`) sem gerar 500' do
      payload = remessa_sicoob.dup
      payload['pagamentos'] = [payload['pagamentos'].first.merge('cedente' => 'X', 'carteira' => '1')]
      expect { @result = described_class.generate('sicoob', 'cnab240', payload) }.not_to raise_error
      expect(@result[:valid]).to be(true)
    end

    it 'trata código de formato em branco no pagamento (cai no default)' do
      payload = remessa_sicoob.dup
      payload['pagamentos'] = [payload['pagamentos'].first.merge('cod_desconto' => '', 'especie_titulo' => '')]
      result = described_class.generate('sicoob', 'cnab240', payload)
      expect(result[:valid]).to be(true)
    end
  end

  describe BoletoApi::Services::FieldMapper do
    it 'remove códigos defaultáveis em branco do pagamento' do
      mapped = described_class.map_pagamento('cod_desconto' => '', 'especie_titulo' => '  ', 'valor' => 10)
      expect(mapped).not_to have_key('cod_desconto')
      expect(mapped).not_to have_key('especie_titulo')
      expect(mapped['valor']).to eq(10)
    end

    it 'garante bairro_sacado = "" quando ausente (evita nil.format_size)' do
      mapped = described_class.map_pagamento('valor' => 10)
      expect(mapped['bairro_sacado']).to eq('')
    end
  end

  # Regressão de produção: remessa CNAB 400 do BB usa `bairro_sacado.format_size`
  # sem validar presença; sem bairro, estourava NoMethodError -> 500.
  describe 'Remessa sem bairro do sacado (regressão BB CNAB 400)' do
    let(:remessa_bb) do
      {
        'empresa_mae' => 'Empresa Teste LTDA', 'documento_cedente' => '12345678000100',
        'agencia' => '3073', 'conta_corrente' => '12345678', 'digito_conta' => '0',
        'convenio' => '1234567', 'carteira' => '18', 'variacao_carteira' => '019',
        'sequencial_remessa' => 1,
        'pagamentos' => [{
          'nosso_numero' => '123', 'numero_documento' => 'DOC-001', 'data_vencimento' => '2026/12/31',
          'valor' => 1500.0, 'sacado' => 'Joao da Silva', 'sacado_documento' => '12345678900',
          'sacado_endereco' => 'Rua Teste, 100', 'sacado_cidade' => 'Sao Paulo',
          'sacado_uf' => 'SP', 'sacado_cep' => '01000000' # <- sem bairro de propósito
        }]
      }
    end

    it 'gera a remessa mesmo sem bairro (não dá 500)' do
      expect { @r = BoletoApi::Services::RemessaService.generate('banco_brasil', 'cnab400', remessa_bb) }.not_to raise_error
      expect(@r[:valid]).to be(true)
      expect(@r[:content].bytesize).to be > 0
    end
  end
end
