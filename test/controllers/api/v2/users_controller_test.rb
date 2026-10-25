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
        assert json['errors'].any?
      end

      test 'me returns minimal session payload' do
        get :me
        assert_response :ok
        json = JSON.parse response.body

        assert_equal %w[id email full_name locale role].sort, json.keys.sort
        assert json['id'].is_a?(Integer)
        assert json['email'].present?
        assert json['full_name'].present?
        assert json['locale'].present?
      end

      test 'me requires authentication' do
        @request.headers['Authorization'] = nil
        get :me
        assert_response :unauthorized
      end

      test 'me rejects invalid token' do
        @request.headers['Authorization'] = 'simple-token admin@ekylibre.org wrong-token'
        get :me
        assert_response :unauthorized
      end

      test 'me rejects malformed authorization header' do
        @request.headers['Authorization'] = 'Bearer some-jwt'
        get :me
        assert_response :bad_request
      end
    end
  end
end
