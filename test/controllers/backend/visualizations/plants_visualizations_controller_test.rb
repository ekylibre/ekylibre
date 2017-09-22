require 'test_helper'
module Backend
  module Visualizations
    class PlantsVisualizationsControllerTest < ActionController::TestCase
      setup do
        Ekylibre::Tenant.switch!('test')
        @locale = ENV['LOCALE'] || I18n.default_locale
        @user = users(:users_001)
        @user.update_column(:language, @locale)
        sign_in(@user)
      end

      teardown do
        sign_out(@user)
      end

      test 'async loading plants visualization' do
        #TODO
        # current_campaign = Campaign.find_or_create_by!(harvest_year: 2016)
        binding.pry

        plants = Plant.of_campaign(@user.current_campaign)
        expected_plants_count = plants.count

        get :show, xhr: true, format: :json
        r = JSON.parse(@response.body)

        assert r.key? 'series'
        assert r['series'].key? 'main'
        assert_equal expected_plants_count, r['series']['main'].count

        # Test data on first plant
        assert_equal plants.first.name, r['series']['main'].first['name']
        assert_equal plants.first.shape.to_json_object, r['series']['main'].first['shape']

      end
    end
  end
end
