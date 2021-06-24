require 'test_helper'
module Api
  module V1
    class PlantDensityAbaciControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      test 'index' do
        get :index, params: {}
        assert_response :ok
      end

      test 'show' do
        get :show, params: { id: 1 }
        assert_response :ok
        json = JSON.parse response.body
        assert json['germination_percentage']
        assert json['variety_name'], json.inspect
        assert json['items'].is_a?(Array)
        assert json['items'].any?
        json['items'].each do |item|
          assert item['seeding_density_value']
          assert item['plants_count']
        end
      end
    end
  end
end
