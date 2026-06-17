# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'json'
require 'base64'

module BoletoApi
  module Providers
    # Cliente HTTP de baixo nível para a API do C6 Bank.
    #
    # Autenticação confirmada do C6 (developers.c6bank.com.br):
    #   - mTLS: certificado de cliente em PKCS12 (.pfx) + senha
    #   - OAuth2 client_credentials: client_id + client_secret -> Bearer token
    #
    # Tudo POR TENANT: cada imobiliária gera cert + credencial no Web Banking dela
    # e envia para o gestao-contrato, que repassa por request. Este cliente usa
    # em memória e NÃO persiste.
    #
    # Usa apenas a stdlib (net/http + openssl) — sem dependência nova.
    class C6Client
      class AuthError < StandardError; end
      class RequestError < StandardError; end

      # Cache de token em memória, por client_id (processo). Evita reautenticar a
      # cada cobrança. NÃO é persistência de credencial — só do access_token vivo.
      @token_cache = {}
      class << self
        attr_reader :token_cache
      end

      # @param credentials [Hash] {
      #   client_id:, client_secret:,
      #   pfx_base64:, pfx_password:   # certificado mTLS do tenant
      # }
      # @param config [Hash] { base_url:, auth_url:, environment: 'sandbox'|'production' }
      def initialize(credentials:, config: {})
        @client_id     = credentials[:client_id] || credentials['client_id']
        @client_secret = credentials[:client_secret] || credentials['client_secret']
        @pfx_base64    = credentials[:pfx_base64] || credentials['pfx_base64']
        @pfx_password  = credentials[:pfx_password] || credentials['pfx_password']
        @base_url      = config[:base_url] || default_base_url(config[:environment])
        @auth_url      = config[:auth_url] || "#{@base_url}/oauth/token" # TODO: confirmar path na homologação
      end

      # Retorna um Bearer token válido (do cache ou autenticando).
      def token
        cached = self.class.token_cache[@client_id]
        return cached[:access_token] if cached && cached[:expires_at] > Time.now + 30

        authenticate!
      end

      # Requisição autenticada à API do C6 (mTLS + Bearer).
      # @return [Hash] corpo JSON parseado
      def request(method, path, body = nil)
        uri = URI.join(@base_url, path)
        req = build_request(method, uri, body)
        req['Authorization'] = "Bearer #{token}"
        req['Content-Type'] = 'application/json'

        res = http(uri).request(req)
        parse!(res)
      end

      private

      def authenticate!
        uri = URI(@auth_url)
        req = Net::HTTP::Post.new(uri)
        req['Content-Type'] = 'application/x-www-form-urlencoded'
        # client_credentials. TODO: confirmar se C6 usa Basic auth no header ou
        # client_id/secret no body — ajustar na homologação.
        req.set_form_data(
          grant_type: 'client_credentials',
          client_id: @client_id,
          client_secret: @client_secret
        )

        res = http(uri).request(req)
        data = parse!(res, context: 'auth')

        access_token = data['access_token'] || data[:access_token]
        raise AuthError, "C6 não retornou access_token: #{data.inspect}" unless access_token

        expires_in = (data['expires_in'] || 300).to_i
        self.class.token_cache[@client_id] = {
          access_token: access_token,
          expires_at: Time.now + expires_in
        }
        access_token
      end

      # net/http configurado com mTLS (cert do tenant carregado do PKCS12).
      def http(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |h|
          h.use_ssl = (uri.scheme == 'https')
          h.read_timeout = 30
          h.open_timeout = 10
          if @pfx_base64 && !@pfx_base64.empty?
            pkcs12 = OpenSSL::PKCS12.new(Base64.decode64(@pfx_base64), @pfx_password.to_s)
            h.cert = pkcs12.certificate
            h.key  = pkcs12.key
            h.verify_mode = OpenSSL::SSL::VERIFY_PEER
          end
        end
      end

      def build_request(method, uri, body)
        klass = {
          get: Net::HTTP::Get, post: Net::HTTP::Post,
          put: Net::HTTP::Put, patch: Net::HTTP::Patch, delete: Net::HTTP::Delete
        }.fetch(method.to_sym)
        req = klass.new(uri)
        req.body = body.to_json if body
        req
      end

      def parse!(res, context: 'request')
        body = res.body.to_s.empty? ? {} : JSON.parse(res.body)
        return body if res.is_a?(Net::HTTPSuccess)

        klass = context == 'auth' ? AuthError : RequestError
        # Não inclui credenciais na mensagem — só status + corpo do banco.
        raise klass, "C6 #{context} HTTP #{res.code}: #{body.inspect}"
      rescue JSON::ParserError
        raise RequestError, "C6 #{context} HTTP #{res.code}: resposta não-JSON"
      end

      def default_base_url(environment)
        # TODO: substituir pelos hosts reais da homologação C6.
        environment.to_s == 'production' ? 'https://api.c6bank.com.br' : 'https://baas-api-sandbox.c6bank.com.br'
      end
    end
  end
end
