require 'test_helper'

module Backend
  class GolumnsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions only: []

    test 'show' do
      get :show, params: { id: 'fghjkl' }
      assert_response :success
    end

    test 'update' do
      post :update, params: { id: 'fghjkl', positions: { 0 => { id: 123, containers: [1, 2, 3] } } }
      assert_response :success
    end

    test 'reset' do
      post :reset, params: { id: 'fghjkl' }
      assert_response :success
    end
  end
end
