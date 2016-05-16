require 'test_helper'
module Api
  module V1
    class PlantsControllerTest < ActionController::TestCase
      connect_with_token

      test 'index' do
        add_auth_header
        get :index
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 25
      end
    end
  end
end
