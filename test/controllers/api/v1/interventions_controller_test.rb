require 'test_helper'
module Api
  module V1
    class InterventionsControllerTest < ActionController::TestCase
      connect_with_token

      test 'index' do
        add_auth_header
        get :index
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30

        get :index, params: { page: 2 }
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30

        get :index, params: { doer_email: 'admin@ekylibre.org' }
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30

        get :index, params: { user_email: 'admin@ekylibre.org' }
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30

        get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'true' }
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30

        get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'false' }
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30

        get :index, params: { user_email: 'admin@ekylibre.org', nature: 'request', with_interventions: 'falsesd' }
        assert_response :unprocessable_entity
      end
    end
  end
end
