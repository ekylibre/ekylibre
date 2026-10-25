require 'cgi'
require 'uri'

module Clients
  module Insee
    # Thin client over the INSEE Sirene V3.11 API.
    # Docs: https://portail-api.insee.fr/ (Sirene 3.11).
    class SireneClient
      BASE_URL = 'https://api.insee.fr/api-sirene/3.11/'.freeze
      SIREN_END_POINT = (BASE_URL + 'siren').freeze
      SIRET_END_POINT = (BASE_URL + 'siret').freeze

      # API caps a page at 1000 results.
      MAX_PAGE = 1000

      def initialize(api_key:)
        @api_key = api_key
      end

      # --- Single resource lookups -----------------------------------------

      def get_siren(siren)
        get_request(SIREN_END_POINT + "/#{siren}")
      end

      def get_siret(siret)
        get_request(SIRET_END_POINT + "/#{siret}")
      end

      # --- Multi-criteria search (paginated) -------------------------------
      # `query` is the raw Sirene `q` expression, e.g.
      #   "denominationUniteLegale:BOULANGERIE* AND codePostalEtablissement:44000"
      # `number` maps to `nombre` (page size), `start` to `debut` (offset),
      # `fields` to `champs` (comma-separated field selection).

      def search_legal_units(query, number: 20, start: 0, fields: nil)
        get_request(build_search_url(SIREN_END_POINT, query, number: number, start: start, fields: fields))
      end

      def search_establishments(query, number: 20, start: 0, fields: nil)
        get_request(build_search_url(SIRET_END_POINT, query, number: number, start: start, fields: fields))
      end

      # All establishments attached to a legal unit (head office + branches).
      def get_establishments_of_legal_unit(siren, number: 100)
        search_establishments("siren:#{siren}", number: number)
      end

      # --- Convenience name searches (kept for existing callers) -----------

      def get_legal_unit_by_name(name)
        search_legal_units("raisonSociale:#{name}")
      end

      def get_enterprise_by_name(name)
        search_establishments("raisonSociale:#{name}")
      end

      def get_enterprise_by_name_and_postal_code(name, postal_code)
        search_establishments("raisonSociale:#{name} AND codePostalEtablissement:#{postal_code}")
      end

      private

        attr_reader :api_key

        def build_search_url(endpoint, query, number:, start:, fields:)
          params = { q: query, nombre: number.to_i.clamp(1, MAX_PAGE), debut: start.to_i }
          params[:champs] = Array(fields).join(',') if fields.present?
          "#{endpoint}?#{URI.encode_www_form(params)}"
        end

        def get_request(url, headers: {})
          call = RestClient.get(url, { 'X-INSEE-Api-Key-Integration' => api_key, accept: 'application/json' }.merge(headers))
          JSON.parse(call.body).deep_symbolize_keys
        end
    end
  end
end
