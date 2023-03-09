require 'test_helper'
module Backend
  class MeasuresControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup_sign_in

    test 'convert action' do
      get :convert, params: { value: 10.34, from: 'kilometer', to: 'meter' }, format: :json
      assert_response(:success)
      assert_equal({ "value"=>10_340.0, "unit"=>"meter" }, JSON.parse(response.body))

      get :convert, params: { value: 10.34, from: 'liter', to: 'meter' }, format: :json
      assert_response(:unprocessable_entity)
      assert_equal("Measure can't be converted from one dimension (volume) to an other (distance)", JSON.parse(response.body)['error'])
    end
  end
end
