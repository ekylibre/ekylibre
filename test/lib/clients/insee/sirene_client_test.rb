# frozen_string_literal: true

require 'test_helper'

module Clients
  module Insee
    class SireneClientTest < ActiveSupport::TestCase
      FakeResponse = Struct.new(:body)

      test 'search_establishments builds a paginated /siret query with the api key header' do
        client = SireneClient.new(api_key: 'KEY123')
        captured = nil
        RestClient.stub(:get, ->(*args) { captured = args; FakeResponse.new("{}") }) do
          client.search_establishments('raisonSociale:ACME', number: 5, start: 10, fields: %i[siret siren])
        end

        url, headers = captured
        assert_includes url, 'https://api.insee.fr/api-sirene/3.11/siret?'
        assert_includes url, 'q=raisonSociale%3AACME'
        assert_includes url, 'nombre=5'
        assert_includes url, 'debut=10'
        assert_includes url, 'champs=siret%2Csiren'
        assert_equal 'KEY123', headers['X-INSEE-Api-Key-Integration']
      end

      test 'caps the page size to the API maximum' do
        client = SireneClient.new(api_key: 'K')
        captured = nil
        RestClient.stub(:get, ->(*args) { captured = args.first; FakeResponse.new("{}") }) do
          client.search_establishments('q', number: 10_000_000)
        end

        assert_includes captured, "nombre=#{SireneClient::MAX_PAGE}"
      end
    end
  end
end
