require 'test_helper'
module Backend
  class StocksControllerTest < ActionController::TestCase
    def setup
      @user = users(:users_001)
    end

    test 'give a list of variant with average_cost_amount/amount for authenticate user' do
      sign_in @user
      get :list
      assert_response 200
    end

    test 'redirect if user are not authenticate' do
      get :list
      assert_response :redirect
    end
    # some test
  end
end
