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

        get :index, page: 2
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30

        get :index, doer_email: 'admin@ekylibre.org'
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30

        get :index, user_email: 'admin@ekylibre.org'
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 30
      end
    end
  end
end
