require 'test_helper'
module Api
  module V1
    class TokensControllerTest < ActionController::TestCase
      # test_restfully_all_actions

      test 'create' do
        post :create, email: 'admin@ekylibre.org', password: '12345678'
        json = JSON.parse response.body
        assert json['token']
      end

      test 'create with invalid password' do
        post :create, email: 'admin@ekylibre.org', password: 'invalid password'
        json = JSON.parse response.body
        assert_response :unauthorized
        assert json['message']
      end

      test 'revoke token' do
        # Get it!
        post :create, email: 'admin@ekylibre.org', password: '12345678'
        json = JSON.parse response.body
        token = json['token']
        assert token

        # Revoke it
        delete :destroy, id: token
        assert_response :ok

        # Revoke it if you can
        delete :destroy, id: "What's up?"
        assert_response :not_found
      end
    end
  end
end
