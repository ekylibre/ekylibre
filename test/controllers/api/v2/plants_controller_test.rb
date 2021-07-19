require 'test_helper'
module Api
  module V2
    class PlantsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      setup do
        Plant.delete_all
        create_list(:corn_plant, 10, updated_at: '01/01/2016')
      end

      test 'get all records' do
        get :index, params: {}
        plants = JSON.parse response.body
        assert_equal 10, plants.count
        assert_response :ok
      end

      test 'get records from a given date' do
        create_list(:corn_plant, 5, updated_at: '05/01/2017')
        modified_since = '01/01/2017'
        get :index, params: { modified_since: modified_since }
        plants = JSON.parse response.body
        assert_equal 5, plants.count
        assert_response :ok
      end
    end
  end
end
