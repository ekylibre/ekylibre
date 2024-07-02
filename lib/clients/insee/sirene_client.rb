module Clients
  module Insee
    class SireneClient
      TOKEN_URL = 'https://api.insee.fr/token'.freeze
      BASE_URL = 'https://api.insee.fr/entreprises/sirene/V3.11/'.freeze
      SIREN_END_POINT = (BASE_URL + 'siren').freeze
      SIRET_END_POINT = (BASE_URL + 'siret').freeze

      def initialize(key:, secret:)
        @key = key
        @secret = secret
      end

      def get_siren(siren)
        get_request(SIREN_END_POINT + "/#{siren}")
      end

      def get_siret(siret)
        get_request(SIRET_END_POINT + "/#{siret}")
      end

      def get_legal_unit_by_name(name)
        query = "raisonSociale:#{CGI::escape(name)}"
        get_request(SIREN_END_POINT + "?q=" + CGI::escape(query))
      end

      def get_enterprise_by_name(name)
        query = "raisonSociale:#{CGI::escape(name)}"
        get_request(SIRET_END_POINT + "?q=" + CGI::escape(query))
      end

      def get_enterprise_by_name_and_postal_code(name, postal_code)
        query = "raisonSociale:#{CGI::escape(name)} AND codePostalEtablissement:#{postal_code}"
        get_request(SIRET_END_POINT + "?q=" + CGI::escape(query))
      end

      private
        attr_reader :key, :secret

        def authorization
          "Bearer #{token}"
        end

        def token
          key64 = Base64.strict_encode64("#{key}:#{secret}")
          auth_key = "Basic #{key64}"
          call = RestClient.post(TOKEN_URL, { grant_type: 'client_credentials' }, { authorization: auth_key } )
          response = JSON.parse(call.body).deep_symbolize_keys
          response[:access_token]
        end

        def get_request(url, headers: {})
          call = RestClient.get(url, { authorization: authorization }.merge(headers))
          response = JSON.parse(call.body).deep_symbolize_keys
        end
    end
  end
end
