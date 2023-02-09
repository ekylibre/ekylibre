require 'test_helper'
module Backend
  class UnitsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup_sign_in

    test 'show action' do
      get :show, params: { id: units(:units_001).id }, format: :json
      assert_response :success
    end
  end
end
