module Clients
  module Insee
    class SireneClient
      BASE_URL = 'https://api.insee.fr/api-sirene/3.11/'.freeze
      SIREN_END_POINT = (BASE_URL + 'siren').freeze
      SIRET_END_POINT = (BASE_URL + 'siret').freeze

      def initialize(api_key:)
        @api_key = api_key
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
        attr_reader :api_key

        def get_request(url, headers: {})
          call = RestClient.get(url, { 'X-INSEE-Api-Key-Integration' => api_key, accept: 'application/json' }.merge(headers))
          JSON.parse(call.body).deep_symbolize_keys
        end
    end
  end
end
