# frozen_string_literal: true

require 'test_helper'

module Backend
  class EntitiesSireneSearchTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::EntitiesController
    setup_sign_in

    test '#sirene_search renders the candidates as JSON' do
      candidates = [{ siret: '12345678900012', name: 'ACME SARL', label: 'ACME SARL — 44000 NANTES' }]

      SireneSearchService.stub(:call, candidates) do
        get :sirene_search, params: { q: 'acme' }, format: :json
      end

      assert_response :success
      body = JSON.parse(response.body)
      assert_equal 'ACME SARL', body['results'].first['name']
      assert_equal '12345678900012', body['results'].first['siret']
    end
  end
end
