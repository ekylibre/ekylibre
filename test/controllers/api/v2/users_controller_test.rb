require 'test_helper'
module Api
  module V2
    class UsersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      test 'get user info' do
        get :show, params: {}
        user = JSON.parse response.body
        assert user['first_name']
        assert user['last_name']
        assert user['email']
        assert user['language']
        assert user['administrator']
        assert user['worker_id']
        assert_response :ok
      end

      test 'update user info' do
        params = {
            first_name: "Support",
            last_name: "Ekylibre",
            email: "support@ekylibre.com",
            language: "fra"
        }
        put :update, params: params
        json = JSON.parse response.body
        assert json['id'].present?
        assert_response :ok
      end

      test 'update with wrong values' do
        params = {
            first_name: "Support",
            last_name: "Ekylibre",
            email: "support.ekylibre.com",
            language: "fra"
        }
        put :update, params: params
        json = JSON.parse response.body
        assert_response :bad_request
        assert json['errors'].include?("Email is invalid")
      end
    end
  end
end
