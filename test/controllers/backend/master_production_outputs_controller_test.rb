require 'test_helper'
module Backend
  class MasterProductionOutputsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[index]

    test 'index' do
      get :index, params: { main: true, production_nature_id: 1 }, format: :json
      production_outputs = JSON.parse(response.body)
      assert_response :success
      assert production_outputs.any?, "Return many records"
      assert production_outputs.all?{|r| r['main'] == true}, "Return record with main equals to true"
      assert production_outputs.all?{|r| r['production_nature_id'] == 1}, "Return record with production_nature_id equals to the right id"
    end
  end
end
