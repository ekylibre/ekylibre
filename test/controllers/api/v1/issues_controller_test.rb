require 'test_helper'
module Api
  module V1
    class IssuesControllerTest < ActionController::TestCase
      connect_with_token

      test 'index' do
        add_auth_header
        get :index
        json = JSON.parse response.body
        assert_response :ok
        assert json.size <= 25
      end

      test 'create' do
        add_auth_header
        post :create, name: 'Sample issue', nature: :issue, description: 'No idea of the source', gravity: 2, priority: 2
      end
    end
  end
end
