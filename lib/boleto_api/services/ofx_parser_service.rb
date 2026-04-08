# frozen_string_literal: true

require 'ofx'
require 'tempfile'

module BoletoApi
  module Services
    # Serviço para parsing de arquivos OFX (extrato bancário)
    # Suporta OFX v1 (SGML) e v2 (XML)
    class OFXParserService
      class << self
        # Parseia arquivo OFX e retorna dados estruturados
        #
        # @param file [File, Tempfile] Arquivo OFX
        # @param somente_creditos [Boolean] Filtrar apenas créditos
        # @return [Hash] Dados estruturados do extrato
        def parse(file, somente_creditos: false)
          content = read_and_normalize_encoding(file)
          ofx = parse_ofx(content)

          account = ofx.account
          raise 'Nenhuma conta encontrada no arquivo' if account.nil?

          org = extract_org(ofx)
          fid = extract_fid(ofx)

          transacoes = build_transacoes(account.transactions, org, fid, somente_creditos)

          build_response(account, ofx, org, fid, transacoes)
        end

        private

        # Lê o arquivo e normaliza encoding para UTF-8
        def read_and_normalize_encoding(file)
          raw = if file.respond_to?(:read)
                  file.read
                else
                  File.read(file)
                end

          # Tentar detectar encoding e converter para UTF-8
          begin
            # Tentar como UTF-8 primeiro
            raw.force_encoding('UTF-8')
            return raw if raw.valid_encoding?
          rescue StandardError
            # Ignorar e tentar Latin-1
          end

          begin
            # Bancos brasileiros geralmente enviam em Latin-1
            raw.force_encoding('ISO-8859-1')
            raw.encode('UTF-8', 'ISO-8859-1', invalid: :replace, undef: :replace, replace: '?')
          rescue StandardError
            raw.force_encoding('ASCII-8BIT')
            raw.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
          end
        end

        # Parseia conteúdo OFX usando a gem ofx
        def parse_ofx(content)
          # A gem ofx espera um arquivo, então usamos Tempfile
          tempfile = Tempfile.new(['ofx_parse', '.ofx'])
          begin
            tempfile.binmode
            tempfile.write(content)
            tempfile.rewind
            OFX(tempfile.path)
          ensure
            tempfile.close
            tempfile.unlink
          end
        rescue StandardError => e
          raise "Arquivo OFX inválido ou não reconhecido: #{e.message}"
        end

        # Extrai campo ORG (fi_name) do OFX
        def extract_org(ofx)
          so = ofx.sign_on
          return '' unless so

          if so.respond_to?(:fi_name) && so.fi_name
            so.fi_name.to_s
          else
            ''
          end
        rescue StandardError
          ''
        end

        # Extrai campo FID (fi_id) do OFX
        def extract_fid(ofx)
          so = ofx.sign_on
          return '' unless so

          if so.respond_to?(:fi_id) && so.fi_id
            so.fi_id.to_s
          else
            ''
          end
        rescue StandardError
          ''
        end

        # Constrói array de transações
        def build_transacoes(transactions, org, fid, somente_creditos)
          return [] if transactions.nil? || transactions.empty?

          banco_id = org.to_s.empty? ? fid.to_s : org.to_s
          result = transactions.map do |tx|
            build_transacao(tx, banco_id)
          end

          if somente_creditos
            result.select { |tx| tx[:tipo] == 'CREDIT' }
          else
            result
          end
        end

        # Constrói hash de uma transação
        def build_transacao(tx, banco_id)
          memo = safe_string(tx.memo)
          {
            fitid: safe_string(tx.fit_id),
            tipo: tx.amount.to_f >= 0 ? 'CREDIT' : 'DEBIT',
            data: tx.posted_at&.strftime('%Y-%m-%d'),
            valor: tx.amount.to_f.abs,
            memo: memo,
            name: safe_string(tx.name),
            checknum: safe_string(tx.check_number),
            refnum: safe_string(tx.ref_number),
            nosso_numero_extraido: NossoNumeroExtractor.extrair(memo, banco_id)
          }
        end

        # Constrói resposta completa
        def build_response(account, ofx, org, fid, transacoes)
          creditos = transacoes.select { |t| t[:tipo] == 'CREDIT' }
          debitos = transacoes.select { |t| t[:tipo] == 'DEBIT' }

          {
            banco: {
              org: org.to_s,
              fid: fid.to_s
            },
            conta: {
              agencia: safe_string(account.respond_to?(:bank_id) ? account.bank_id : nil),
              numero: safe_string(account.id),
              tipo: safe_string(account.type).upcase
            },
            periodo: build_periodo(account),
            saldo: build_saldo(account),
            transacoes: transacoes,
            resumo: {
              total_transacoes: transacoes.size,
              total_creditos: creditos.size,
              total_debitos: debitos.size,
              soma_creditos: creditos.sum { |t| t[:valor] }.round(2),
              soma_debitos: debitos.sum { |t| t[:valor] }.round(2)
            }
          }
        end

        # Constrói período do extrato
        def build_periodo(account)
          transactions = account.transactions || []
          dates = transactions.map(&:posted_at).compact
          {
            inicio: dates.min&.strftime('%Y-%m-%d'),
            fim: dates.max&.strftime('%Y-%m-%d')
          }
        end

        # Constrói saldo
        def build_saldo(account)
          bal = account.balance
          {
            valor: bal.respond_to?(:amount) ? bal.amount.to_f : 0.0,
            data: bal.respond_to?(:posted_at) && bal.posted_at ?
                    bal.posted_at.strftime('%Y-%m-%d') : nil
          }
        end

        # Converte para string de forma segura
        def safe_string(value)
          return '' if value.nil?

          value.to_s
        rescue StandardError
          ''
        end
      end
    end
  end
end
