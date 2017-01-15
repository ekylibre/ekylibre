require 'test_helper'

module Backend
  class GolumnsControllerTest < ActionController::TestCase
    test_restfully_all_actions only: []

    test 'show' do
      get :show, id: 'fghjkl'
      assert_response :success
    end

    test 'update' do
      post :update, id: 'fghjkl', positions: { 0 => { id: 123, containers: [1, 2, 3] } }
      assert_response :success
    end

    test 'reset' do
      post :reset, id: 'fghjkl'
      assert_response :success
    end
  end
end
