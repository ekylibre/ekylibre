require 'test_helper'
module Api
  module V1
    class PlantCountingsControllerTest < ActionController::TestCase
      connect_with_token

      test 'create' do
        add_auth_header
        post :create, comment: 'Yeah yeah yeah!!!',
                      plant_id: Plant.first.id,
                      plant_density_abacus_item_id: PlantDensityAbacus.first.id,
                      average_value: 17,
                      items_attributes: [
                        { value: 15 },
                        { value: 20 },
                        { value: 16 }
                      ]
        json = JSON.parse response.body
        assert_response :created, json.to_yaml
      end
    end
  end
end
