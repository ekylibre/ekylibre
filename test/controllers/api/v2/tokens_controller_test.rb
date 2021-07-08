require 'test_helper'
module Api
  module V2
    class TokensControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      # test_restfully_all_actions

      test 'create' do
        post :create, params: { email: 'admin@ekylibre.org', password: '12345678' }
        json = JSON.parse response.body
        assert json['token']
      end

      test 'create with invalid password' do
        post :create, params: { email: 'admin@ekylibre.org', password: 'invalid password' }
        json = JSON.parse response.body
        assert_response :unauthorized
        assert json['message']
      end

      test 'revoke token' do
        # Get it!
        post :create, params: { email: 'admin@ekylibre.org', password: '12345678' }
        json = JSON.parse response.body
        token = json['token']
        assert token

        # Revoke it
        delete :destroy, params: { id: token }
        assert_response :ok

        # Revoke it if you can
        delete :destroy, params: { id: "What's up?" }
        assert_response :not_found
      end
    end
  end
end
